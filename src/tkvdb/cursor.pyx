from cpython.bytes cimport PyBytes_FromStringAndSize, PyBytes_AsString, PyBytes_AsStringAndSize

cimport ctkvdb
from tkvdb.iterators cimport KeysIterator


cdef class Cursor:
    # cdef ctkvdb.tkvdb_tr* tr
    # cdef ctkvdb.tkvdb_cursor* cursor
    # cpdef bint is_started
    # cpdef bint is_opened        # FIXME naming

    def __cinit__(self):
        self.is_started = False

    cdef init(self, ctkvdb.tkvdb_tr* tr):
        self.tr = tr
        self.cursor = ctkvdb.tkvdb_cursor_create(tr) # FIXME
        self.is_opened = True

    # cpdef seek(self, key, seek):
    #     self.cursor.seek(self.cursor, Utils.make_datum(key), seek)

    cpdef bytes key(self):
        # print("KEY LEN {}".format(self.keysize()))
        return PyBytes_FromStringAndSize(
            <char *>self.cursor.key(self.cursor),
            self.keysize()
        )

    # FIXME error checking
    cpdef bytes val(self):
        # print("VAL LEN {}".format(self.keysize()))
        return PyBytes_FromStringAndSize(
            <char *>self.cursor.val(self.cursor),
            self.valsize()
        )

    # def key_datum(self):
    #     return Utils.get_datum(self.cursor.key_datum(self.cursor))

    # def val_datum(self):
    #     return Utils.get_datum(self.cursor.val_datum(self.cursor))

    cpdef Py_ssize_t keysize(self): # Maybe size_t?
        return self.cursor.keysize(self.cursor)

    cpdef Py_ssize_t valsize(self):
        return self.cursor.valsize(self.cursor)

    cpdef ctkvdb.TKVDB_RES next(self):
        return self.cursor.next(self.cursor)

    cpdef ctkvdb.TKVDB_RES first(self):
        return self.cursor.first(self.cursor)

    cpdef ctkvdb.TKVDB_RES free(self):
        print("cursor free")
        self.cursor.free(self.cursor)

    def __iter__(self):
        return KeysIterator(self)

    # cpdef __iter__(self):
    # return KeyIterator(self)
