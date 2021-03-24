cimport ctkvdb


cdef class Cursor:
    cdef ctkvdb.tkvdb_tr* tr
    cdef ctkvdb.tkvdb_cursor* cursor
    cdef readonly bint is_started
    cdef readonly bint is_opened        # FIXME naming

    cdef init(self, ctkvdb.tkvdb_tr* tr)
    cpdef bytes key(self)
    cpdef bytes val(self)
    cpdef Py_ssize_t keysize(self)
    cpdef Py_ssize_t valsize(self)
    cpdef ctkvdb.TKVDB_RES next(self)
    cpdef ctkvdb.TKVDB_RES first(self)
    cpdef ctkvdb.TKVDB_RES free(self)
