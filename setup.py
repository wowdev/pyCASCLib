#!/usr/bin/env python
import platform
import subprocess
import os
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

# fix dylib loading path
if platform.system() == 'Darwin':
    for filepath in os.listdir(os.path.abspath(os.path.dirname(__file__))):
        if 'darwin' in filepath and 'CASC' in filepath:
            subprocess.call(['install_name_tool', '-change', 'libcasc.dylib', '@loader_path/libcasc.dylib', filepath])
            break