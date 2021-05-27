from tkvdb.cursor cimport Cursor


cdef class BaseIterator:
    cdef Cursor cursor
    cdef readonly bint reverse

    cpdef value(self)
    cpdef _iter(self)
    cpdef _start(self)


cdef class KeysIterator(BaseIterator):
    pass


cdef class ItemsIterator(BaseIterator):
    pass


cdef class ValuesIterator(BaseIterator):
    pass
