#!/usr/bin/env python
import platform
import subprocess
import os
from setuptools import setup, Extension
from Cython.Build import cythonize

from pathlib import Path

# allow local imports from root package
import sys
sys.path.append(str(Path(__file__).parent.parent.parent.absolute()))

from cmake import check_for_cmake, CMAKE_EXE

CUR_DIR = os.path.abspath(os.path.dirname(__file__))

def main():

    print ('\nBuilding CASC extension')
    # build CASCLib
    check_for_cmake()

    build_dir = os.path.join(CUR_DIR, 'CASCLib', 'build')

    os.makedirs(build_dir, exist_ok=True)
    os.chdir(build_dir)

    cmake_defines = ['-DCMAKE_BUILD_TYPE=Release'
    , '-DCASC_BUILD_SHARED_LIB=OFF'
    , '-DCASC_BUILD_STATIC_LIB=ON']

    if sys.platform != 'win32':
        cmake_defines.extend(['-DCMAKE_CXX_FLAGS=-fPIC', '-DCMAKE_C_FLAGS=-fPIC'])

    status = subprocess.call([CMAKE_EXE, '..', *cmake_defines])

    if status:
        print(f'\nError building CASCLib. See CMake error above.')
        sys.exit(1)

    status = subprocess.check_call([CMAKE_EXE, '--build', '.', '--config', 'Release'])

    if status:
        print(f'\nError building CASCLib. See build error above.')
        sys.exit(1)

    status = subprocess.call([CMAKE_EXE, '--install', '.', '--prefix', CUR_DIR])

    if status:
        print(f'\nError building CASCLib. Error setting install configuration.')
        sys.exit(1)

    os.chdir(CUR_DIR)

    static_libraries = ['casc']
    static_lib_dir = 'lib'
    libraries = []
    library_dirs = []
    extra_objects = []

    if sys.platform == 'win32':
        libraries.extend(static_libraries)
        library_dirs.append(static_lib_dir)
        extra_objects = []
    else: # POSIX
        extra_objects = ['{}/lib{}.a'.format(static_lib_dir, l) for l in static_libraries]

    setup(
        name='Python CASC Handler',
        ext_modules=cythonize(
            Extension(
            "CASC",
            sources=[
                "casc.pyx"
            ],
            language="c++",
            libraries=libraries,
            library_dirs=library_dirs,
            include_dirs = ["include"],
            extra_objects=extra_objects
            )
        ),
        requires=['Cython']
    )

    print('\nSuccesfully built CASC extension.')

'''
    # fix dylib loading path
    if platform.system() == 'Darwin':
        for filepath in os.listdir(CUR_DIR):
            if 'darwin' in filepath and 'CASC' in filepath:
                subprocess.call(['install_name_tool', '-change', 'libcasc.dylib', '@loader_path/libcasc.dylib', filepath])
                break
'''

if __name__ == '__main__':
    main()
