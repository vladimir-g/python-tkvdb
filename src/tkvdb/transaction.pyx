from cpython.bytes cimport PyBytes_FromStringAndSize, PyBytes_AsStringAndSize

cimport ctkvdb
from tkvdb.cursor cimport Cursor
from tkvdb.cursor import Seek
from tkvdb.iterators cimport KeysIterator, ItemsIterator, ValuesIterator
from tkvdb.errors import make_error, NotFoundError, EmptyError
from tkvdb.params cimport Params


cdef class Transaction:
    """Pythonic wrapper around tkvdb transaction."""
    def __cinit__(self, db=None, ram_only=True, params=None):
        cdef ctkvdb.tkvdb* db_ptr = NULL # For RAM-mode
        if not ram_only:
            self.db = db
            db_ptr = self.db.get_db()

        # Set params to null as default to enable params inheritance
        # from db
        cdef ctkvdb.tkvdb_params * params_ptr = NULL
        if params is not None:
            self.params = params
            params_ptr = self.params.get_params()

        self.tr = ctkvdb.tkvdb_tr_create(db_ptr, params_ptr)
        self.is_initialized = True
        self.ram_only = ram_only
        self.is_started = False

    cdef ctkvdb.tkvdb_tr* get_transaction(self):
        """Return internal tkvdb_tr pointer."""
        return self.tr

    cpdef Cursor cursor(self, bytes seek_key=None, seek_type=Seek.EQ):
        """Create and initialize Cursor."""
        c = Cursor(self)
        if seek_key is not None:
            c.seek(seek_key, seek_type)
        return c

    cpdef begin(self):
        """Start transaction."""
        if not self.is_started:
            self.is_started = True
            self.tr.begin(self.tr)

    cpdef commit(self):
        """Do a commit if transaction is started (begin)."""
        if self.is_started:
            self.tr.commit(self.tr)
            self.is_changed = False

    cpdef rollback(self):
        """Do a rollback if transaction is started (begin)."""
        if self.is_started:
            self.tr.rollback(self.tr)
            self.is_changed = False

    cpdef free(self):
        """Free the transaction if it is initialized."""
        if self.is_initialized:
            self.tr.free(self.tr)
            self.is_initialized = False
            self.is_started = False
            self.is_changed = False

    cpdef bytes getvalue(self, bytes key):
        """Wrapper for tkvdb transaction get."""
        cdef ctkvdb.tkvdb_datum key_datum

        PyBytes_AsStringAndSize(
            key,
            <char **>&key_datum.data,
            <Py_ssize_t *>&key_datum.size
        )

        cdef ctkvdb.tkvdb_datum res_datum
        ok = self.tr.get(self.tr, &key_datum, &res_datum)
        if ok == ctkvdb.TKVDB_RES.TKVDB_OK:
            return PyBytes_FromStringAndSize(
                <char *>res_datum.data,
                res_datum.size
            )
        else:
            error = make_error(ok)
            if error is not None:
                raise error()
        return None

    def get(self, bytes key, bytes default=None):
        """Python mapping get method with default value."""
        try:
            return self.getvalue(key)
        except (EmptyError, NotFoundError):
            return default

    cpdef put(self, bytes key, bytes value):
        """Wrapper for tkvdb transaction put."""
        cdef ctkvdb.tkvdb_datum key_datum
        cdef ctkvdb.tkvdb_datum val_datum

        PyBytes_AsStringAndSize(
            key,
            <char **>&key_datum.data,
            <Py_ssize_t *>&key_datum.size
        )

        PyBytes_AsStringAndSize(
            value,
            <char **>&val_datum.data,
            <Py_ssize_t *>&val_datum.size
        )

        ok = self.tr.put(self.tr, &key_datum, &val_datum)
        error = make_error(ok)
        if error is not None:
            raise error()
        self.is_changed = True

    cpdef delete(self, bytes key, bint prefix=False):
        """Wrapper for tkvdb transaction delete."""
        cdef ctkvdb.tkvdb_datum key_datum

        PyBytes_AsStringAndSize(key,
                                <char **>&key_datum.data,
                                <Py_ssize_t *>&key_datum.size)

        del_pfx = 0
        if prefix:
            del_pfx = 1
        ok = self.tr.delete(self.tr, &key_datum, del_pfx)

    def __getitem__(self, bytes key):
        """Python mapping __getitem__."""
        try:
            return self.getvalue(key)
        except (EmptyError, NotFoundError):
            raise KeyError(key)

    def __setitem__(self, bytes key, bytes value):
        """Python mapping __getitem__."""
        self.put(key, value)

    def __delitem__(self, bytes key):
        """Python mapping __delitem__."""
        self.delete(key)

    def __dealloc__(self):
        """Destructor."""
        self.free()

    def __iter__(self):
        """Return dict-like keys iterator as default."""
        return self.keys()

    def __reversed__(self):
        """Return reversed keys iterator."""
        return reversed(self.keys())

    def __contains__(self, bytes key):
        """Python method for 'in' operator."""
        try:
            self.getvalue(key)
            return True
        except (EmptyError, NotFoundError):
            return False

    cpdef BaseIterator items(self):
        """Dict-like items iterator."""
        cursor = self.cursor()
        return ItemsIterator(cursor)

    cpdef BaseIterator keys(self):
        """Dict-like keys iterator."""
        cursor = self.cursor()
        return KeysIterator(cursor)

    cpdef BaseIterator values(self):
        """Dict-like values iterator."""
        cursor = self.cursor()
        return ValuesIterator(cursor)

    def __enter__(self):
        """Context manager enter."""
        self.begin()
        return self

    def __exit__(self, exc_type, exc_value, traceback):
        """Context manager exit."""
        if exc_type or exc_value or traceback:
            # Rollback on exception
            self.rollback()
        self.free()
