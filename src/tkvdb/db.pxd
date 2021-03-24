cimport ctkvdb
from tkvdb.transaction cimport Transaction


cdef class Tkvdb:
    cdef ctkvdb.tkvdb* db
    cdef readonly str path
    cdef readonly bint is_opened

    cpdef Transaction transaction(self)

    cpdef close(self)
