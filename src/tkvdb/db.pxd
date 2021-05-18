cimport ctkvdb
from tkvdb.transaction cimport Transaction
from tkvdb.params cimport Params


cdef class Tkvdb:
    cdef ctkvdb.tkvdb* db
    cdef readonly str path
    cdef readonly bint is_opened
    cdef Params params

    cpdef Transaction transaction(self, Params params=*)
    cdef ctkvdb.tkvdb* get_db(self)

    cpdef close(self)
