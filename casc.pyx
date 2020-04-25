from libcpp cimport bool
from libc.stdlib cimport free, malloc
from libc.string cimport strcpy
from typing import Union, Tuple

cimport casc


class CASCLibException(Exception):
    pass

class ERROR_SUCCESS(CASCLibException):
    pass

class ERROR_FILE_NOT_FOUND(CASCLibException):
    pass

class ERROR_PATH_NOT_FOUND(CASCLibException):
    pass

class ERROR_ACCESS_DENIED(CASCLibException):
    pass

class ERROR_INVALID_HANDLE(CASCLibException):
    pass

class ERROR_NOT_ENOUGH_MEMORY(CASCLibException):
    pass

class ERROR_NOT_SUPPORTED(CASCLibException):
    pass

class ERROR_INVALID_PARAMETER(CASCLibException):
    pass

class ERROR_DISK_FULL(CASCLibException):
    pass

class ERROR_ALREADY_EXISTS(CASCLibException):
    pass

class ERROR_INSUFFICIENT_BUFFER(CASCLibException):
    pass

class ERROR_BAD_FORMAT(CASCLibException):
    pass

class ERROR_NO_MORE_FILES(CASCLibException):
    pass

class ERROR_HANDLE_EOF(CASCLibException):
    pass

class ERROR_CAN_NOT_COMPLETE(CASCLibException):
    pass

class ERROR_FILE_CORRUPT(CASCLibException):
    pass

class ERROR_FILE_ENCRYPTED(CASCLibException):
    pass

class ERROR_FILE_INCOMPLETE(CASCLibException):
    pass

class ERROR_FILE_OFFLINE(CASCLibException):
    pass

class ERROR_BUFFER_OVERFLOW(CASCLibException):
    pass

class ERROR_CANCELLED(CASCLibException):
    pass


ERROR_CODE_MAP = {
    0:    ERROR_SUCCESS,
    2:    ERROR_PATH_NOT_FOUND,
    1:    ERROR_ACCESS_DENIED,
    9:    ERROR_INVALID_HANDLE,
    12:   ERROR_NOT_ENOUGH_MEMORY,
    45:   ERROR_NOT_SUPPORTED,
    22:   ERROR_INVALID_PARAMETER,
    28:   ERROR_DISK_FULL,
    17:   ERROR_ALREADY_EXISTS,
    55:   ERROR_INSUFFICIENT_BUFFER,
    1000: ERROR_BAD_FORMAT,
    1001: ERROR_NO_MORE_FILES,
    1002: ERROR_HANDLE_EOF,
    1003: ERROR_CAN_NOT_COMPLETE,
    1004: ERROR_FILE_CORRUPT,
    1005: ERROR_FILE_ENCRYPTED,
    1006: ERROR_FILE_INCOMPLETE,
    1007: ERROR_FILE_OFFLINE,
    1008: ERROR_BUFFER_OVERFLOW,
    1009: ERROR_CANCELLED
}

class FileOpenFlags:
    CASC_OPEN_BY_NAME       = 0x00000000  # Open the file by name. This is the default value; str
    CASC_OPEN_BY_CKEY       = 0x00000001  # The name is just the content key; skip ROOT file processing; bytes[16]
    CASC_OPEN_BY_EKEY       = 0x00000002  # The name is just the encoded key; skip ROOT file processing; bytes[16]
    CASC_OPEN_BY_FILEID     = 0x00000003  # The name is FileDataId; int
    CASC_OPEN_TYPE_MASK     = 0x0000000F  # The mask which gets open type from the dwFlags
    CASC_OPEN_FLAGS_MASK    = 0xFFFFFFF0  # The mask which gets open type from the dwFlags
    CASC_STRICT_DATA_CHECK  = 0x00000010  # Verify all data read from a file
    CASC_OVERCOME_ENCRYPTED = 0x00000020


class LocaleFlags:
    CASC_LOCALE_ALL      = 0xFFFFFFFF
    CASC_LOCALE_NONE     = 0x00000000
    CASC_LOCALE_UNKNOWN1 = 0x00000001
    CASC_LOCALE_ENUS     = 0x00000002
    CASC_LOCALE_KOKR     = 0x00000004
    CASC_LOCALE_RESERVED = 0x00000008
    CASC_LOCALE_FRFR     = 0x00000010
    CASC_LOCALE_DEDE     = 0x00000020
    CASC_LOCALE_ZHCN     = 0x00000040
    CASC_LOCALE_ESES     = 0x00000080
    CASC_LOCALE_ZHTW     = 0x00000100
    CASC_LOCALE_ENGB     = 0x00000200
    CASC_LOCALE_ENCN     = 0x00000400
    CASC_LOCALE_ENTW     = 0x00000800
    CASC_LOCALE_ESMX     = 0x00001000
    CASC_LOCALE_RURU     = 0x00002000
    CASC_LOCALE_PTBR     = 0x00004000
    CASC_LOCALE_ITIT     = 0x00008000
    CASC_LOCALE_PTPT     = 0x00010000


class FileInfo:

    c_key  = bytes()        # CKey
    e_key = bytes()         # EKey
    data_file_name = str()  # Plain name of the data file where the file is stored
    storage_offset = 0      # Offset of the file over the entire storage
    segment_offset = 0      # Offset of the file in the segment file ("data.###")
    tag_bit_mask = 0        # Bitmask of tags. Zero if not supported
    filename_hash = 0       # Hash of the file name. Zero if not supported
    content_size = 0        # Content size of all spans
    encoded_size = 0        # Encoded size of all spans
    segment_index = 0       # Index of the segment file (aka 0 = "data.000")
    span_count = 0          # Number of spans forming the file
    file_data_id = 0        # File data ID. CASC_INVALID_ID if not supported.
    locale_flags = 0        # Locale flags. CASC_INVALID_ID if not supported.
    content_flags = 0       # Locale flags. CASC_INVALID_ID if not supported


cdef _open_file_handle(void* storage_handle
                       , identifier: Union[str, int, bytes]
                       , open_flags: int
                       , locale_flags: int
                       , void** file_handle):

    cdef char* filepath
    cdef LPCSTR filedataid
    cdef BYTE key[16]

    if open_flags == FileOpenFlags.CASC_OPEN_BY_NAME:

        pybytestr = identifier.encode('utf-8')
        filepath = pybytestr

        if not casc.CascOpenFile(storage_handle, filepath, locale_flags, open_flags, file_handle):
            raise ERROR_CODE_MAP.get(casc.GetLastError())

    elif open_flags & FileOpenFlags.CASC_OPEN_BY_FILEID:

        filedataid = <LPCSTR><size_t>identifier

        if not casc.CascOpenFile(storage_handle, filedataid, locale_flags, open_flags, file_handle):
            raise ERROR_CODE_MAP.get(casc.GetLastError())

    elif open_flags & FileOpenFlags.CASC_OPEN_BY_CKEY or open_flags & FileOpenFlags.CASC_OPEN_BY_EKEY:

        if len(identifier) != 16:
            raise ERROR_INVALID_PARAMETER("CKey or Ekey must be a bytes object with length of 16")

        key = identifier

        if not casc.CascOpenFile(storage_handle, key, locale_flags, open_flags, file_handle):
            raise ERROR_CODE_MAP.get(casc.GetLastError())


cdef class CASCFile:

    cdef void* file_handle
    cdef bytes raw_data
    cdef CASCHandler storage
    cdef object file_info

    def __cinit__(self, storage: CASCHandler, identifier: Union[str, int, bytes], open_flags: int):

        """
        Initialize and read file from CASC

        Args:
            identifier:
               Specification of the file to open. This can be name, symbolic name, file data id, content key
               or an encoded key. Type of this parameter is specified in the open_flags parameter

            open_flags:
                Open options. Can be a combination of one or more flags from FileOpenFlags class.
                Note that flags CASC_OPEN_BY_* are mutually exclusive.

        Returns:

            bytes: Python bytes object containing raw bytes of the read file

        """

        _open_file_handle(storage.storage_handle, identifier, open_flags, storage.locale_flags, &self.file_handle)

        self.storage = storage
        self.storage.open_files.add(self)

        self.raw_data = None
        self.file_info = None

    def close(self):
        """ Close file """
        self._close_file()
        self.storage.open_files.remove(self)


    def _close_file(self):
        casc.CascCloseFile(self.file_handle)

    @property
    def info(self) -> FileInfo:

        """
        Retrieve file info

        Returns:

            FileInfo: Python object containing information about the requested file if file is present.
            None: if file failed to open or does not exist.

        """

        if self.file_info is not None:
            return self.file_info

        cdef void* file_info_raw = <void*>malloc(sizeof(casc.CASC_FILE_FULL_INFO))

        casc.CascGetFileInfo(self.file_handle, casc.CASC_FILE_INFO_CLASS.CascFileFullInfo,
                             file_info_raw, sizeof(casc.CASC_FILE_FULL_INFO), NULL)

        cdef casc.CASC_FILE_FULL_INFO* file_info = <casc.CASC_FILE_FULL_INFO*>file_info_raw

        free(file_info_raw)

        py_file_info = FileInfo()
        py_file_info.c_key = file_info.CKey
        py_file_info.e_key = file_info.EKey
        py_file_info.file_data_id = file_info.FileDataId
        py_file_info.content_flags = file_info.ContentFlags
        py_file_info.locale_flags = file_info.LocaleFlags
        py_file_info.content_size = file_info.ContentSize
        py_file_info.encoded_size = file_info.EncodedSize
        py_file_info.data_file_name = file_info.DataFileName
        py_file_info.filename_hash = file_info.FileNameHash
        py_file_info.segment_index = file_info.SegmentIndex
        py_file_info.segment_offset = file_info.SegmentOffset
        py_file_info.storage_offset = file_info.StorageOffset
        py_file_info.span_count = file_info.SpanCount
        py_file_info.tag_bit_mask = file_info.TagBitMask

        self.file_info = py_file_info

        return py_file_info

    @info.setter
    def info(self, value):
        raise PermissionError('\nFile info is a read-only property.')

    @info.deleter
    def info(self):
        raise PermissionError('\nFile info is a read-only property.')

    @property
    def data(self):

        if self.raw_data is not None:
            return self.raw_data


        cdef DWORD file_size = casc.CascGetFileSize(self.file_handle, NULL)
        cdef DWORD bytes_read
        cdef char *data = <char*>malloc(file_size)

        casc.CascReadFile(self.file_handle, data, file_size, &bytes_read)

        if not bytes_read:
            raise ERROR_CODE_MAP.get(casc.GetLastError())

        if bytes_read < file_size:
            raise ERROR_FILE_ENCRYPTED

        self.raw_data = memoryview(data[:bytes_read]).tobytes()
        free(data)

        return self.raw_data

    @data.setter
    def data(self, other):
        raise PermissionError('\nData is a read-only property.')

    @data.deleter
    def data(self):
        raise PermissionError('\nData is a read-only property.')

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        self.close()


cdef class CASCHandler:

    cdef void* storage_handle
    cdef int locale_flags
    cdef set open_files
    cdef CASC_OPEN_STORAGE_ARGS p_args

    cdef char* c_path
    cdef char* region
    cdef char* product

    def __cinit__(self, path: str, locale_flags: int, is_online: bool = False):

        """
        Intialize CASC Handler

        Args:
            path:
                Local storages: A parameter string containing the path to a local storage.
                If the storage contains multiple products (World of Warcraft Retail + World of Warcraft PTR),
                the product can be specified by the product code name separated by a colon
                ("C:\Games\World of Warcraft:wowt").

                Online storage: A parameter string containing the path to a local cache,
                followed by a product code name and region, both separated by a colon. Example: "C:\Cache:wow:eu".

            is_online: Open this storage as online or local storage (bool).

        Returns:
            None
        """

        self.open_files = set()
        self.locale_flags = locale_flags

        self.c_path = <char *>malloc(len(path) + 1)
        strcpy(self.c_path, path.encode('utf-8'))

        self.region = <char *>malloc(3)
        strcpy(self.region, 'eu'.encode('utf-8'))

        self.product = <char *>malloc(4)
        strcpy(self.product, 'wow'.encode('utf-8'))

        self.p_args.Size = sizeof(CASC_OPEN_STORAGE_ARGS)
        self.p_args.szLocalPath = self.c_path
        self.p_args.szCodeName = self.product
        self.p_args.szRegion = self.region
        self.p_args.dwLocaleMask = locale_flags

        if is_online:
            if not casc.CascOpenStorageEx(NULL, &self.p_args, True, &self.storage_handle):
                raise ERROR_CODE_MAP.get(casc.GetLastError())
        else:
            if not casc.CascOpenStorageEx(NULL, &self.p_args, False, &self.storage_handle):
                raise ERROR_CODE_MAP.get(casc.GetLastError())


    def read_file(self, identifier: Union[str, int, bytes], open_flags: int) -> CASCFile:

        """
        Read file from CASC

        Args:
            identifier:
               Specification of the file to open. This can be name, symbolic name, file data id, content key
               or an encoded key. Type of this parameter is specified in the open_flags parameter

            open_flags:
                Open options. Can be a combination of one or more flags from FileOpenFlags class.
                Note that flags CASC_OPEN_BY_* are mutually exclusive.

        Returns:

            bytes: Python bytes object containing raw bytes of the read file

        """

        return CASCFile(self, identifier, open_flags)


    def file_exists(self, identifier: Union[str, int, bytes], open_flags: int) -> bool:

        """
        Check if file exists in opened CASC storage

        Args:
            identifier:
               Specification of the file to check. This can be name, symbolic name, file data id, content key
               or an encoded key. Type of this parameter is specified in the open_flags parameter

            open_flags:
                Open options. Can be a combination of one or more flags from FileOpenFlags class.
                Note that flags CASC_OPEN_BY_* are mutually exclusive.

        Returns:

            Bool: identifies if the requested file exists

        """

        cdef void* file_handle

        try:
            _open_file_handle(self.storage_handle, identifier, open_flags, self.locale_flags, &file_handle)
        except CASCLibException:
            return False

        casc.CascCloseFile(file_handle)

        return True

    def close(self):
        """ Close storage """

        for file in self.open_files:
            file._close_file()

        self.open_files.clear()

        if self.storage_handle != NULL:
            casc.CascCloseStorage(self.storage_handle)

    def __contains__(self, item: Tuple[Union[str, int, bytes], int]):
        return self.file_exists(item[0], item[1])

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        self.close()