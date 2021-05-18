cimport ctkvdb


cdef class Params:
    cdef ctkvdb.tkvdb_params* params
    cdef dict values

    cpdef get_values(self)
    cdef ctkvdb.tkvdb_params* get_params(self)
    cpdef get(self, param)
    cpdef set(self, param, int value)
    cpdef free(self)
