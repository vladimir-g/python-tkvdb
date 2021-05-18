import os
import sys

cimport ctkvdb
from tkvdb.transaction cimport Transaction
from tkvdb.errors import make_error
from tkvdb.params import Params


cdef class Tkvdb:
    """Wrapper around tkvdb database with pythonic interface."""
    def __cinit__(self, str path, Params params=None):
        self.path = path
        if params is None:
            params = Params()
        self.db = ctkvdb.tkvdb_open(
            os.fsencode(path),
            params.get_params()
        )
        self.params = params
        self.is_opened = True

    cdef ctkvdb.tkvdb* get_db(self):
        """Get underlying C database structure."""
        return self.db

    cpdef Transaction transaction(self, Params params=None):
        """Create transaction object."""
        tr = Transaction(self, params=params, ram_only=False)
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
