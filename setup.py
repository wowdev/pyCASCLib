from distutils.core import setup, Extension
from Cython.Build import cythonize

setup(
    name='Python CASC Handler',
    ext_modules=cythonize(
        Extension(
        "CASC",
        sources=[
            "casc.pyx"
        ],
        language="c++",
        libraries=['casc'],
        library_dirs=['.'],
        include_dirs = ["CASCLib/src/"]
        )
    ),
    requires=['Cython']
)