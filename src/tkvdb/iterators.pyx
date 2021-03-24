cimport ctkvdb
from tkvdb.cursor cimport Cursor


cdef class BaseIterator:
    def __init__(self, cursor):
        self.cursor = cursor
        self.is_started = False

    def __iter__(self):
        return self

    def __next__(self):
        if not self.is_started:
            rc = self.cursor.first()
            self.is_started = True
        else:
            rc = self.cursor.next()
        if rc == ctkvdb.TKVDB_OK:
            return self.value()
        raise StopIteration

    cpdef value(self):
        raise NotImplementedError()


cdef class KeysIterator(BaseIterator):
    cpdef value(self):
        return self.cursor.key()

cdef class ItemsIterator(BaseIterator):
    cpdef value(self):
        return (self.cursor.key(), self.cursor.val())

cdef class ValuesIterator(BaseIterator):
    cpdef value(self):
        return self.cursor.val()
