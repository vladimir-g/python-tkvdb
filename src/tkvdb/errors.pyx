from ctkvdb cimport TKVDB_RES


cdef class Error(Exception):
    """Base class for all tkvdb exceptions."""
    def __cinit__(self, *args, **kwargs):
        self.name = 'Error'
        self.code = -1

    def __str__(self):
        return str(self.name)   # FIXME

# Repeatable, but Cython doesn't allow easy metaprogramming

cdef class IoError(Error):
    """TKVDB_IO_ERROR return code."""
    def __cinit__(self, *args, **kwargs):
        self.name = 'TKVDB_IO_ERROR'
        self.code = TKVDB_RES.TKVDB_IO_ERROR


cdef class LockedError(Error):
    """TKVDB_LOCKED return code."""
    def __cinit__(self, *args, **kwargs):
        self.name = 'TKVDB_LOCKED'
        self.code = TKVDB_RES.TKVDB_LOCKED


cdef class EmptyError(Error):
    """TKVDB_EMPTY return code."""
    def __cinit__(self, *args, **kwargs):
        self.name = 'TKVDB_EMPTY'
        self.code = TKVDB_RES.TKVDB_EMPTY


cdef class NotFoundError(Error):
    """TKVDB_NOT_FOUND return code."""
    def __cinit__(self, *args, **kwargs):
        self.name = 'TKVDB_NOT_FOUND'
        self.code = TKVDB_RES.TKVDB_NOT_FOUND


cdef class EnomemError(Error):
    """TKVDB_ENOMEM return code."""
    def __cinit__(self, *args, **kwargs):
        self.name = 'TKVDB_ENOMEM'
        self.code = TKVDB_RES.TKVDB_ENOMEM


cdef class CorruptedError(Error):
    """TKVDB_CORRUPTED return code."""
    def __cinit__(self, *args, **kwargs):
        self.name = 'TKVDB_CORRUPTED'
        self.code = TKVDB_RES.TKVDB_CORRUPTED

cdef class NotStartedError(Error):
    """TKVDB_NOT_STARTED return code."""
    def __cinit__(self, *args, **kwargs):
        self.name = 'TKVDB_NOT_STARTED'
        self.code = TKVDB_RES.TKVDB_NOT_STARTED


cdef class ModifiedError(Error):
    """TKVDB_MODIFIED return code."""
    def __cinit__(self, *args, **kwargs):
        self.name = 'TKVDB_MODIFIED'
        self.code = TKVDB_RES.TKVDB_MODIFIED


codes_map = {
    TKVDB_RES.TKVDB_IO_ERROR: IoError,
    TKVDB_RES.TKVDB_LOCKED: LockedError,
    TKVDB_RES.TKVDB_EMPTY: EmptyError,
    TKVDB_RES.TKVDB_NOT_FOUND: NotFoundError,
    TKVDB_RES.TKVDB_ENOMEM: EnomemError,
    TKVDB_RES.TKVDB_CORRUPTED: CorruptedError,
    TKVDB_RES.TKVDB_NOT_STARTED: NotStartedError,
    TKVDB_RES.TKVDB_MODIFIED: ModifiedError
}

 
cpdef Error make_error(TKVDB_RES code):
    if code in codes_map:
        return <Error>codes_map[code]
    return None

     
