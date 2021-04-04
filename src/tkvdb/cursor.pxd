cimport ctkvdb
from tkvdb.iterators cimport BaseIterator


cdef class Cursor:
    cdef ctkvdb.tkvdb_tr* tr
    cdef ctkvdb.tkvdb_cursor* cursor
    cdef readonly bint is_initialized
    cdef readonly bint is_started

    cdef init(self, ctkvdb.tkvdb_tr* tr)
    cpdef bytes key(self)
    cpdef bytes val(self)
    cpdef Py_ssize_t keysize(self)
    cpdef Py_ssize_t valsize(self)
    cpdef next(self)
    cpdef first(self)
    cpdef free(self)
    cpdef BaseIterator items(self)
    cpdef BaseIterator values(self)
    cpdef BaseIterator keys(self)
