cimport ctkvdb
cimport tkvdb.transaction as tr
from tkvdb.iterators cimport BaseIterator


cdef class Cursor:
    cdef ctkvdb.tkvdb_cursor* cursor
    cdef readonly tr.Transaction tr
    cdef readonly bint is_initialized
    cdef readonly bint is_started

    cpdef bytes key(self)
    cpdef bytes val(self)
    cpdef Py_ssize_t keysize(self)
    cpdef Py_ssize_t valsize(self)
    cpdef next(self)
    cpdef prev(self)
    cpdef first(self)
    cpdef last(self)
    cpdef free(self)
    cpdef seek(self, bytes key, seek)
    cpdef BaseIterator items(self)
    cpdef BaseIterator values(self)
    cpdef BaseIterator keys(self)
