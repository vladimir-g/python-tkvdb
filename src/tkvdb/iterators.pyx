cimport ctkvdb
from tkvdb.cursor cimport Cursor
from tkvdb.errors cimport EmptyError, NotFoundError


cdef class BaseIterator:
    """Base class for all iterators."""
    def __init__(self, cursor):
        self.cursor = cursor

    def __iter__(self):
        return self

    def __next__(self):
        """Call cursor first or next."""
        try:
            if not self.cursor.is_started:
                self.cursor.first()
            else:
                self.cursor.next()
            return self.value()
        except (EmptyError, NotFoundError):
            raise StopIteration()

    cpdef value(self):
        """Return current value depending on implementation."""
        raise NotImplementedError()


cdef class KeysIterator(BaseIterator):
    """Iterator returning cursor keys."""
    cpdef value(self):
        return self.cursor.key()


cdef class ItemsIterator(BaseIterator):
    """Iterator returning cursor key-value tuple."""
    cpdef value(self):
        return (self.cursor.key(), self.cursor.val())


cdef class ValuesIterator(BaseIterator):
    """Iterator returning cursor values."""
    cpdef value(self):
        return self.cursor.val()
