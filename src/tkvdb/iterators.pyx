cimport ctkvdb
from tkvdb.cursor cimport Cursor
from tkvdb.errors cimport EmptyError, NotFoundError


cdef class BaseIterator:
    """Base class for all iterators."""
    def __init__(self, cursor, reverse=False):
        self.cursor = cursor
        self.reverse = reverse

    def __iter__(self):
        return self

    def __reversed__(self):
        self.reverse = True
        return self

    cpdef _iter(self):
        """Do an iteration step."""
        if self.reverse:
            self.cursor.prev()
        else:
            self.cursor.next()

    cpdef _start(self):
        """Put cursor in initial position."""
        if self.reverse:
            self.cursor.last()
        else:
            self.cursor.first()

    def __next__(self):
        """Call cursor first or next."""
        try:
            if not self.cursor.is_started:
                self._start()
            else:
                self._iter()
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
