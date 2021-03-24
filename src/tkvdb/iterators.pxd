from tkvdb.cursor cimport Cursor


cdef class BaseIterator:
    cdef Cursor cursor
    cpdef bint is_started

    cpdef value(self)


cdef class KeysIterator(BaseIterator):
    pass


cdef class ItemsIterator(BaseIterator):
    pass


cdef class ValuesIterator(BaseIterator):
    pass
