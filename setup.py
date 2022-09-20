#!/usr/bin/env python
import subprocess
import platform
import argparse
import os
import sys
from setuptools import setup, Extension
from Cython.Build import cythonize

from cmake import check_for_cmake, CMAKE_EXE

CUR_DIR = os.path.abspath(os.path.dirname(__file__))


def print_error(*s: str):
    print("\033[91m {}\033[00m".format(' '.join(s)))


def print_succes(*s: str):
    print("\033[92m {}\033[00m".format(' '.join(s)))


def print_info(*s: str):
    print("\033[93m {}\033[00m".format(' '.join(s)))


def main(debug: bool):

    print_info('\nBuilding CASC extension...')
    print(f'Target mode: {"Debug" if debug else "Release"}')
    # build CASCLib
    check_for_cmake()

    build_dir = os.path.join(CUR_DIR, 'CASCLib', 'build')

    os.makedirs(build_dir, exist_ok=True)
    os.chdir(build_dir)

    cmake_defines = ['-DCMAKE_BUILD_TYPE=Debug' if debug else '-DCMAKE_BUILD_TYPE=Release'
    , '-DCASC_BUILD_SHARED_LIB=OFF'
    , '-DCASC_BUILD_STATIC_LIB=ON']

    if sys.platform != 'win32':
        cmake_defines.extend(['-DCMAKE_CXX_FLAGS=-fPIC', '-DCMAKE_C_FLAGS=-fPIC'])

    status = subprocess.call(['cmake', '..', *cmake_defines])

    if status:
        print_error(f'\nError building CASCLib. See CMake error above.')
        sys.exit(1)

    status = subprocess.check_call(['cmake', '--build', '.', f'--config {"Debug" if debug else "Release"}'])

    if status:
        print_error(f'\nError building CASCLib. See build error above.')
        sys.exit(1)

    status = subprocess.call(['cmake', '--install', '.', f'--prefix {CUR_DIR}'
                              , f'--config {"Debug" if debug else "Release"}'])

    if status:
        print_error(f'\nError building CASCLib. Error setting install configuration.')
        sys.exit(1)

    os.chdir(CUR_DIR)

    static_libraries = ['casc']
    static_lib_dir = 'lib'
    libraries = []
    library_dirs = []
    extra_objects = []
    define_macros = []

    if sys.platform == 'win32':
        libraries.extend(static_libraries)
        library_dirs.append(static_lib_dir)
        extra_objects = []
        define_macros.append(('CASCLIB_NO_AUTO_LINK_LIBRARY', None))
    else: # POSIX
        extra_objects = ['{}/lib{}.a'.format(static_lib_dir, l) for l in static_libraries]

    # compiler and linker settings
    if platform.system() == 'Darwin':
        if debug:
            extra_compile_args = ['-std=c++17', '-g3', '-O0']
            extra_link_args = []
        else:
            extra_compile_args = ['-std=c++17', '-O3']
            extra_link_args = []

    elif platform.system() == 'Windows':
        if debug:
            extra_compile_args = ['/std:c++17', '/Zi']
            extra_link_args = ['/DEBUG:FULL']
        else:
            extra_compile_args = ['/std:c++17']
            extra_link_args = []
    else:
        if debug:
            extra_compile_args = ['-std=c++17', '-O0', '-g']
            extra_link_args = []
        else:
            extra_compile_args = ['-std=c++17', '-O3']
            extra_link_args = []

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
            extra_objects=extra_objects,
            define_macros=define_macros,
            extra_compile_args=extra_compile_args,
            extra_link_args=extra_link_args
            )
        ),
        requires=['Cython']
    )

    print_succes('\nSuccesfully built CASC extension.')


'''
    # fix dylib loading path
    if platform.system() == 'Darwin':
        for filepath in os.listdir(CUR_DIR):
            if 'darwin' in filepath and 'CASC' in filepath:
                subprocess.call(['install_name_tool', '-change', 'libcasc.dylib', '@loader_path/libcasc.dylib', filepath])
                break
'''

if __name__ == '__main__':

    parser = argparse.ArgumentParser()
    parser.add_argument('--wbs_debug', action='store_true', help='Compile CASC extension in debug mode.')
    args, unknown = parser.parse_known_args()

    if args.wbs_debug:
        sys.argv.remove('--wbs_debug')

    main(args.wbs_debug)
