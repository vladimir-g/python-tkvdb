import os
import sys

cimport ctkvdb
from tkvdb.transaction cimport Transaction
from tkvdb.errors import make_error


cdef class Tkvdb:
    """Wrapper around tkvdb database with pythonic interface."""
    def __cinit__(self, path):
        self.path = path
        param = ctkvdb.tkvdb_params_create() # FIXME
        self.db = ctkvdb.tkvdb_open(os.fsencode(path), param)        # FIXME errors
        self.is_opened = True

    cpdef Transaction transaction(self):
        """Create transaction object."""
        tr = Transaction()
        tr.init(self.db)
        return tr

    cpdef close(self):
        """Close and free database."""
        if self.is_opened:
            ok = ctkvdb.tkvdb_close(self.db)
            error = make_error(ok)
            if error is not None:
                raise error()
            self.is_opened = False

    def __dealloc__(self):
        """Destructor."""
        self.close()

    def __enter__(self):
        """Context manager enter."""
        return self

    def __exit__(self, *args):
        """Context manager exit."""
        self.close()
