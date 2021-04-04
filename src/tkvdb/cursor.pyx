from cpython.bytes cimport PyBytes_FromStringAndSize

cimport ctkvdb
from tkvdb.iterators cimport KeysIterator
from tkvdb.errors import make_error


cdef class Cursor:
    """Pythonic wrapper around tkvdb cursor."""
    def __cinit__(self):
        self.is_initialized = False
        self.is_started = False

    cdef init(self, ctkvdb.tkvdb_tr* tr):
        """Initialize C cursor."""
        self.tr = tr
        self.cursor = ctkvdb.tkvdb_cursor_create(tr) # FIXME
        self.is_initialized = True

    cpdef bytes key(self):
        """Get current cursor key."""
        return PyBytes_FromStringAndSize(
            <char *>self.cursor.key(self.cursor),
            self.keysize()
        )

    cpdef bytes val(self):
        """Get current cursor value."""
        return PyBytes_FromStringAndSize(
            <char *>self.cursor.val(self.cursor),
            self.valsize()
        )

    cpdef Py_ssize_t keysize(self):
        """Get current key size."""
        return self.cursor.keysize(self.cursor)

    cpdef Py_ssize_t valsize(self):
        """Get current value size."""
        return self.cursor.valsize(self.cursor)

    cpdef next(self):
        """Call cursor next method."""
        ok = self.cursor.next(self.cursor)
        if ok != ctkvdb.TKVDB_RES.TKVDB_OK:
            error = make_error(ok)
            if error is not None:
                raise error()

    cpdef first(self):
        """Call cursor first method."""
        ok = self.cursor.first(self.cursor)
        if ok != ctkvdb.TKVDB_RES.TKVDB_OK:
            error = make_error(ok)
            if error is not None:
                raise error()
        else:
            self.is_started = True

    cpdef free(self):
        """Free cursor."""
        if self.is_initialized:
            self.cursor.free(self.cursor)
            self.is_initialized = False
            self.is_started = False

    def __dealloc__(self):
        """Destructor."""
        self.free()

    def __iter__(self):
        """Return keys iterator as default iterator."""
        return KeysIterator(self)

    def __enter__(self):
        """Context manager enter."""
        return self

    def __exit__(self, exc_type, exc_value, traceback):
        """Context manager exit."""
        self.free()

    # FIXME add seex, last, prev, key_datum/val_datum
