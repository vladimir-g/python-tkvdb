from ctkvdb cimport TKVDB_RES


cdef class Error(Exception):
    cdef readonly str name
    cdef readonly int code


cdef class IoError(Error):
    """TKVDB_IO_ERROR return code."""
    pass


cdef class LockedError(Error):
    """TKVDB_LOCKED return code."""
    pass


cdef class EmptyError(Error):
    """TKVDB_EMPTY return code."""
    pass


cdef class NotFoundError(Error):
    """TKVDB_NOT_FOUND return code."""
    pass


cdef class EnomemError(Error):
    """TKVDB_ENOMEM return code."""
    pass


cdef class CorruptedError(Error):
    """TKVDB_CORRUPTED return code."""
    pass


cdef class NotStartedError(Error):
    """TKVDB_NOT_STARTED return code."""
    pass


cdef class ModifiedError(Error):
    """TKVDB_MODIFIED return code."""
    pass


cpdef Error make_error(TKVDB_RES code)
