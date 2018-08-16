#!/usr/bin/env python
"""
Registration testing of GLOW
Michael Hirsch

f2py -m glowfort -c egrid.f maxt.f glow.f vquart.f gchem.f ephoto.f solzen.f
rcolum.f etrans.f exsect.f ssflux.f snoem.f snoemint.f geomag.f nrlmsise00.f
 qback.f fieldm.f iri90.f aurora_sub.f --quiet

pytest -v
"""
import pytest
from pytest import approx
import logging
from datetime import datetime
from itertools import chain
from numpy import array, zeros, float32, log, nan
from numpy.testing import assert_allclose
#
# import glowaurora
#
from sciencedates import datetime2yeardoy, datetime2gtd
try:
    import msise00
except Exception as e:
    msise00 = None
#
import glowfort
# %% test inputs
z = list(range(30, 110 + 1, 1))
z += (
    [111.5, 113., 114.5, 116.] +
    list(chain(range(118, 150 + 2, 2), range(153, 168 + 3, 3), range(172, 180 + 4, 4),
               range(185, 205 + 5, 5), range(211,
                                             223 + 6, 6), range(230, 244 + 7, 7),
               range(252, 300 + 8, 8), range(309, 345 +
                                             9, 9), range(355, 395 + 10, 10),
               range(406, 428 + 11, 11))) +
    [440, 453, 467, 482, 498, 515, 533, 551] +
    list(range(570, 950 + 20, 20))
)
z = array(z)

nbins = 190
jmax = 170  # glow.h

eflux = 1.
e0 = 1e3
maxind = 112
glat = 70
glon = 0  # like aurora.in
ap = 4
f107 = 100
f107a = 100
nmaj = 3
nst = 6
dtime = datetime(1999, 12, 21)
#
yd, utsec = datetime2yeardoy(dtime)[:2]


def test_egrid_maxt():
    ener, dE = glowfort.egrid()
    assert ener[[maxind, maxind + 10, -1]] == approx([1017.7124, 1677.9241, 47825.418], rel=0.001)
# %% test of maxt
    phi = glowfort.maxt(eflux, e0, ener, dE, itail=0, fmono=nan, emono=nan)
    assert phi.argmax() == maxind
    assert_allclose(phi[[maxind, maxind + 10]], [114810.6, 97814.438])

# %% test vquart (quartic root) KNOWN DEFECTIVE FORTRAN ALGORITHM
# Aquart = tile([-1,0,0,0,1],(jmax,1))
# qroot = glowfort.vquart(Aquart,1)
# assert_allclose(qroot[0],roots(Aquart[0,-1]))
# Aquart = array([[-1,0,0,0,1],
#                [-1,0,0,1,1]])
# nq = Aquart.shape[0]
# Aquart = tile(Aquart,(jmax//nq,1))
# qroot = glowfort.vquartmod.vquart(Aquart, nq)
# try:
#    assert_allclose(qroot[:nq],
#                    [1,0.8191725133961643])
# except AssertionError as e:
#    print('this mismatch is in discussion with S. Solomon.   {}'.format(e))


def test_solzen():
    solzen = pytest.importorskip('glowfort.solzen')
    sza = solzen(yd, utsec, glat, glon)
    assert sza == approx(133.43113708496094)

    return sza


def test_glow():
    # electron precipitation
    # First enact "glow" subroutine, which calls QBACK, ETRANS and GCHEM among others

    glowfort.glow()  # no args

    # %% ver and constituants
    """
    using common block CGLOW, instead use new GLOW for module
    """
    zceta = glowfort.cglow.zceta.T
    zeta = glowfort.cglow.zeta.T[:, :11]
    zcsum = zceta.sum(axis=-1)[:, :11]
    assert zcsum == approx(zeta)


def test_snoem():
    doy = datetime2gtd(dtime)[0]

    zno, maglat, nozm = glowfort.snoem(doy, 1.75 * log(0.4 * ap), f107)
    assert (nozm[12, 15], nozm[-2, -1]) == approx(35077728.0, 1.118755e+08)

    return nozm


def test_snoemint():
    if msise00 is not None:
        densd, tempd = msise00.rungtd1d(
            dtime, z, glat, glon, f107a, f107, [ap] * 7)
    # (nighttime background ionization)
        print(tempd)
        znoint = glowfort.snoemint(dtime.strftime('%Y%j'), glat, glon, f107, ap, z,
                                   tempd.loc[:, 'Tn'])
        assert znoint[[28, 143]] == approx((1.262170e+08, 3.029169e+01), rel=1e-5)  # arbitrary
        return znoint
    else:
        logging.warning(
            'skipped test_snoemint() due to missing external msise00')


def test_fieldm():
    xdip, ydip, zdip, totfield, dipang, decl, smodip = glowfort.fieldm(glat, glon % 360, z[50])
    assert xdip == approx(0.1049523800611496)
    assert totfield == approx(0.5043528079986572)
    assert dipang == approx(77.72911071777344)


def test_ssflux():
    iscale = 1
    hlybr = 0.
    hlya = 0.
    fexvir = 0.
    heiew = 0.
    xuvfac = 3.
    wave1, wave2, sflux = glowfort.ssflux(
        iscale, f107, f107a, hlybr, fexvir, hlya, heiew, xuvfac)
    assert_allclose(sflux[[11, 23]], (4.27225743e+11, 5.54400400e+07))


def test_rcolum_qback():
    if msise00 is not None:
        densd, tempd = msise00.rungtd1d(
            dtime, z, glat, glon, f107a, f107, [ap] * 7)

        """ VCD: Vertical Column Density """
        sza = test_solzen()
        zcol, zvcd = glowfort.rcolum(sza, z * 1e5,
                                     densd.loc[:, ['O', 'O2', 'N2']].values.T,
                                     tempd.loc[:, 'Tn'])
    # FIXME these tests were numerically unstable (near infinity values)
        # see rcolum comments for sun below horizon 1e30
        assert zcol[0, 0] == approx(1e30)
        # TODO changes a bit between python 2 / 3
        assert zvcd[2, 5] == approx(5.97157e+28, rtol=1e-2)
    # %% skipping EPHOTO since we care about night time more for now
        znoint = test_snoemint()
        # zeros because nighttime
        photoi = zeros((nst, nmaj, jmax), dtype=float32, order='F')
        phono = zeros((nst, jmax), dtype=float32, order='F')
        glowfort.qback(zmaj=densd.loc[:, ['O', 'O2', 'N2']].values.T,
                       zno=znoint,
                       zvcd=zvcd,
                       photoi=photoi, phono=phono)
        # arbitrary point check
        assert photoi[0, 0, 77] == approx(1.38091e-18, rel=1e-5)
        assert phono[0, 73] == approx(0.0, rel=1e-5)
    else:
        logging.warning('skipped rcolum qback due to missing external msise00')


# def test_eigen():
#    ener,dE = glowfort.egrid()
#    sim = makeeigen(ener,ones_like(ener),dtime,(glat,glon))


if __name__ == '__main__':
    pytest.main(['-x', __file__])
