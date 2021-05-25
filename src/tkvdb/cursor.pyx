import enum
from cpython.bytes cimport PyBytes_FromStringAndSize, PyBytes_AsStringAndSize

cimport ctkvdb
from ctkvdb cimport TKVDB_SEEK as S
from tkvdb.transaction cimport Transaction
from tkvdb.iterators cimport KeysIterator, ItemsIterator, ValuesIterator
from tkvdb.errors import make_error


class Seek(enum.Enum):
    """Enum wrapper for TKVDB_SEEK."""
    EQ = S.TKVDB_SEEK_EQ
    LE = S.TKVDB_SEEK_LE
    GE = S.TKVDB_SEEK_GE


cdef class Cursor:
    """Pythonic wrapper around tkvdb cursor."""
    def __cinit__(self, Transaction tr):
        self.is_started = False
        self.tr = tr
        self.cursor = ctkvdb.tkvdb_cursor_create(
            tr.get_transaction()
        )
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

    cpdef prev(self):
        """Call cursor prev method."""
        ok = self.cursor.prev(self.cursor)
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

    cpdef last(self):
        """Call cursor last method."""
        ok = self.cursor.last(self.cursor)
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

    cpdef seek(self, bytes key, seek):
        """Call cursor seek method with Seek param."""
        # Create key
        cdef ctkvdb.tkvdb_datum key_datum
        PyBytes_AsStringAndSize(
            key,
            <char **>&key_datum.data,
            <Py_ssize_t *>&key_datum.size
        )

        ok = self.cursor.seek(self.cursor, &key_datum, seek.value)
        if ok != ctkvdb.TKVDB_RES.TKVDB_OK:
            error = make_error(ok)
            if error is not None:
                raise error()
        else:
            self.is_started = True

    def __dealloc__(self):
        """Destructor."""
        self.free()

    def __iter__(self):
        """Return keys iterator as default iterator."""
        return self.keys()

    cpdef BaseIterator items(self):
        """Dict-like items iterator."""
        return ItemsIterator(self)

    cpdef BaseIterator keys(self):
        """Dict-like keys iterator."""
        return KeysIterator(self)

    cpdef BaseIterator values(self):
        """Dict-like values iterator."""
        return ValuesIterator(self)

    def __enter__(self):
        """Context manager enter."""
        return self

    def __exit__(self, exc_type, exc_value, traceback):
        """Context manager exit."""
        self.free()

    # FIXME add key_datum/val_datum
