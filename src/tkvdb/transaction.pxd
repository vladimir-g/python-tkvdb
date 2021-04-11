cimport ctkvdb
from tkvdb.cursor cimport Cursor
from tkvdb.iterators cimport BaseIterator


cdef class Transaction:
    cdef ctkvdb.tkvdb_tr* tr
    cdef ctkvdb.tkvdb* db
    cdef readonly bint is_initialized
    cdef readonly bint is_started
    cdef readonly bint is_changed
    cdef readonly bint ram_only

    cdef init(self, ctkvdb.tkvdb* db)
    cpdef Cursor cursor(self)
    cpdef begin(self)
    cpdef commit(self)
    cpdef rollback(self)
    cpdef free(self)
    cpdef bytes getvalue(self, bytes key)
    cpdef put(self, bytes key, bytes value)
    cpdef delete(self, bytes key)
    cpdef BaseIterator items(self)
    cpdef BaseIterator values(self)
    cpdef BaseIterator keys(self)
