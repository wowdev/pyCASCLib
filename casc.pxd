from libcpp cimport bool

cdef extern from "Python.h":
    char *PyString_AsString(object)

cdef extern from "CASCLib/src/CASCLib.h":

    ctypedef unsigned long size_t
    ctypedef unsigned char  BYTE;
    ctypedef unsigned short USHORT;
    ctypedef int            LONG;
    ctypedef unsigned int   DWORD;
    ctypedef long long      LONGLONG;
    ctypedef signed long long LONGLONG;
    ctypedef signed long long *PLONGLONG;
    ctypedef unsigned long long ULONGLONG;
    ctypedef unsigned long long *PULONGLONG;
    ctypedef void         * HANDLE;
    ctypedef char           TCHAR;
    ctypedef unsigned int   LCID;
    ctypedef LONG         * PLONG;
    ctypedef DWORD        * PDWORD;
    ctypedef BYTE         * LPBYTE;
    ctypedef char         * LPSTR;
    ctypedef const char   * LPCSTR;
    ctypedef TCHAR        * LPTSTR;
    ctypedef const TCHAR  * LPCTSTR;


    ctypedef bool (* PFNPRODUCTCALLBACK)\
    (
        void * PtrUserParam,
        LPCSTR * ProductList,
        size_t ProductCount,
        size_t * PtrSelectedProduct
    )

    ctypedef bool (* PFNPROGRESSCALLBACK)\
    (
        void * PtrUserParam,
        LPCSTR szWork,
        LPCSTR szObject,
        DWORD CurrentValue,
        DWORD TotalValue
    )

    ctypedef struct CASC_OPEN_STORAGE_ARGS:
        size_t Size
        LPCTSTR szLocalPath
        LPCTSTR szCodeName
        LPCTSTR szRegion
        PFNPROGRESSCALLBACK PfnProgressCallback
        void * PtrProgressParam
        PFNPRODUCTCALLBACK PfnProductCallback
        void * PtrProductParam
        DWORD dwLocaleMask
        DWORD dwFlags

    ctypedef CASC_OPEN_STORAGE_ARGS* PCASC_OPEN_STORAGE_ARGS


    ctypedef enum CASC_FILE_INFO_CLASS:
        CascFileContentKey,
        CascFileEncodedKey,
        CascFileFullInfo,                           # Gives CASC_FILE_FULL_INFO structure
        CascFileSpanInfo,                           # Gives CASC_FILE_SPAN_INFO structure for each file span
        CascFileInfoClassMax


    ctypedef struct CASC_FILE_FULL_INFO:
        
        BYTE CKey[16]                              # CKey
        BYTE EKey[16]                              # EKey
        char  DataFileName[0x10]                   # Plain name of the data file where the file is stored
        ULONGLONG StorageOffset                    # Offset of the file over the entire storage
        ULONGLONG SegmentOffset                    # Offset of the file in the segment file ("data.###")
        ULONGLONG TagBitMask                       # Bitmask of tags. Zero if not supported
        ULONGLONG FileNameHash                     # Hash of the file name. Zero if not supported
        ULONGLONG ContentSize                      # Content size of all spans
        ULONGLONG EncodedSize                      # Encoded size of all spans
        DWORD SegmentIndex                         # Index of the segment file (aka 0 = "data.000")
        DWORD SpanCount                            # Number of spans forming the file
        DWORD FileDataId                           # File data ID. CASC_INVALID_ID if not supported.
        DWORD LocaleFlags                          # Locale flags. CASC_INVALID_ID if not supported.
        DWORD ContentFlags                         # Locale flags. CASC_INVALID_ID if not supported



    bool CascOpenStorageEx(LPCTSTR szParams, PCASC_OPEN_STORAGE_ARGS pArgs, bool bOnlineStorage, void** phStorage)
    bool CascOpenStorage(LPCTSTR szParams, DWORD dwLocaleMask, void ** phStorage)
    bool CascOpenOnlineStorage(LPCTSTR szParams, DWORD dwLocaleMask, HANDLE * phStorage)
    bool CascOpenFile(HANDLE hStorage, const void * pvFileName, DWORD dwLocaleFlags, DWORD dwOpenFlags, void** PtrFileHandle)
    DWORD CascGetFileSize(HANDLE hFile, PDWORD pdwFileSizeHigh);
    bool CascGetFileSize64(HANDLE hFile, PULONGLONG PtrFileSize)
    bool CascReadFile(HANDLE hFile, void * lpBuffer, DWORD dwToRead, PDWORD pdwRead)
    bool CascCloseFile(void* hFile)
    bool CascCloseStorage(void* hStorage)
    bool CascGetFileInfo(HANDLE hFile, CASC_FILE_INFO_CLASS InfoClass, void* pvFileInfo, size_t cbFileInfo, size_t* pcbLengthNeeded)
    DWORD GetLastError()

