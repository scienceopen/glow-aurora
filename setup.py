#!/usr/bin/env python3
import setuptools #needed to enable develop
from numpy.distutils.core import setup,Extension
from os.path import join
from glob import glob

# f2py -m aurora -c egrid.f maxt.f glow.f vquart.f gchem.f ephoto.f solzen.f rcolum.f etrans.f exsect.f ssflux.f snoem.f snoemint.f geomag.f nrlmsise00.f qback.f fieldm.f aurora_sub.f

# NOTE: iri90.f not included in f2py b/c we use the pyiri90 package
# NOTE: nrlmsise00.f not included .... msise00 package
fortranfiles=['egrid.f','maxt.f','glow.f',
              'vquart.f','gchem.f','ephoto.f','solzen.f','rcolum.f',
              'etrans.f','exsect.f','ssflux.f','snoem.f','snoemint.f',
              'geomag.f','qback.f','fieldm.f',
              'nrlmsise00.f','iri90.f',
              'aurora_sub.f']

root='fortran'

fortranpaths = [join(root,f) for f in fortranfiles]
fortdata = glob(join(root,'*.dat'))
iridata = glob(join('iri','*.asc')) #in pyiri90
#%%
with open('README.rst') as f:
	long_description = f.read()

ext=[Extension(name='glowfort',
               sources=fortranpaths,
               f2py_options=['--quiet'],
               extra_f77_compile_args=['-finit-local-zero']
)]
               #include_dirs=[root],
               #library_dirs=[root])]

#%% install
setup(name='glowaurora',
      version='0.1',
	 description='Python wrapper for Stan Solomon GLOW auroral model',
	 long_description=long_description,
	 author='Michael Hirsch',
	 url='https://github.com/scienceopen/glowaurora',
      packages=['glowaurora'],
#      package_dir={'glowaurora': 'glowaurora'}, #not working
 #     package_data={'glowaurora': ['fortran/*.dat']}, #not working, use data_files
      include_package_data=True,
      ext_modules=ext,
      data_files=[('glowaurora',fortdata),
                  ('glowaurora/iri',iridata)
                  ], #must have data_files to copy *.dat to site-packages

	  install_requires=['msise00','pymap3d', 'histutils','pyiri90',
                         'numpy','pandas','astropy'],
      dependency_links = ['https://github.com/scienceopen/msise00/tarball/master#egg=msise00',
                          'https://github.com/scienceopen/histutils/tarball/master#egg=histutils',
                          'https://github.com/scienceopen/pymap3d/tarball/master#egg=pymap3d',
                          'https://github.com/scienceopen/pyiri90/tarball/master#egg=pyiri90'
                            ],
      )