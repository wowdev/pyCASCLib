# pyCASCLib
Python object-oriented bindings for Ladislav Zezula's CASCLib (https://github.com/ladislav-zezula/CascLib)

pyCASCLib is a minimalistic Cython based wrapper for CASCLib. Currently not all the lib features are suported, 
but support for additional functions will be added in the future. Contributions are welcome.

# Building

Cython is required to build this project as a Python module.

A shared library (.dll, .so, .dylib, etc depending on platform) is required for the module to work. The binary should be placed 
in the package root. Make sure to change install path of the library to local one when compiling on Mac.

After installing Cython run `python3 setup.py build_ext --inplace` to build the Python module.
Once the building is finished, the library is ready to use in Python.

# Example usage

The Python API of the library is documented in the code with docstrings and type hints.

```
from CASC import CASCHandler, FileOpenFlags

# As a context manager
with CASCHandler('/Volumes/something/World of Warcraft/', False) as casc:
    flags = FileOpenFlags.CASC_OPEN_BY_FILEID # load file by FileDataID

    ret = casc.read_file(189077, flags)
    print(ret) # get raw file bytes

    print(casc.file_exists(189077, flags))
    print(casc.get_file_info(189077, flags).file_data_id) 
    
# Usage with manual closing
casc = CASCHandler('/Volumes/something/World of Warcraft/', False)
print(('world/arttest/boxtest/xyz.m2', FileOpenFlags.CASC_OPEN_BY_NAME) in casc)
casc.close()
```
