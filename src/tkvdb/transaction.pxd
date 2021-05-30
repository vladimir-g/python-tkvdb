cimport ctkvdb
cimport tkvdb.db as db
from tkvdb.cursor cimport Cursor
from tkvdb.iterators cimport BaseIterator
from tkvdb.params cimport Params


cdef class Transaction:
    cdef ctkvdb.tkvdb_tr* tr
    cdef readonly bint is_initialized
    cdef readonly bint is_started
    cdef readonly bint is_changed
    cdef readonly bint ram_only
    cdef readonly Params params
    cdef readonly db.Tkvdb db

    cpdef Cursor cursor(self, bytes seek_key=*, seek_type=*)
    cdef ctkvdb.tkvdb_tr* get_transaction(self)
    cpdef begin(self)
    cpdef commit(self)
    cpdef rollback(self)
    cpdef free(self)
    cpdef bytes getvalue(self, bytes key)
    cpdef put(self, bytes key, bytes value)
    cpdef delete(self, bytes key, bint prefix=*)
    cpdef BaseIterator items(self)
    cpdef BaseIterator values(self)
    cpdef BaseIterator keys(self)
