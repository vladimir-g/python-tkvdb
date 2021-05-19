import enum

cimport ctkvdb
from ctkvdb cimport TKVDB_PARAM as P


class Param(enum.Enum):
    """Enum wrapper for TKVDB_PARAM enum."""
    TrDynalloc = P.TKVDB_PARAM_TR_DYNALLOC
    TrLimit = P.TKVDB_PARAM_TR_LIMIT
    Alignval = P.TKVDB_PARAM_ALIGNVAL
    Autobegin = P.TKVDB_PARAM_AUTOBEGIN
    CursorStackDynalloc = P.TKVDB_PARAM_CURSOR_STACK_DYNALLOC
    CursorStackLimit = P.TKVDB_PARAM_CURSOR_STACK_LIMIT
    CursorKeyDynalloc = P.TKVDB_PARAM_CURSOR_KEY_DYNALLOC
    CursorKeyLimit = P.TKVDB_PARAM_CURSOR_KEY_LIMIT
    DbfileOpenFlags = P.TKVDB_PARAM_DBFILE_OPEN_FLAGS


cdef class Params:
    """Wrapper for tkvdb_params structure."""
    def __cinit__(self, params=None):
        if params is None:
            params = dict()
        self.params = ctkvdb.tkvdb_params_create()
        self.values = {}
        if params is not None:
            for param, value in params.items():
                self.set(param, value)
        self.is_initialized = True

    cpdef get_values(self):
        """Get all set param values."""
        return self.values

    cdef ctkvdb.tkvdb_params* get_params(self):
        """Get underlying C structure."""
        return self.params

    cpdef get(self, param):
        """Get current param value."""
        if not isinstance(param, Param):
            raise TypeError('param must be tkvdb.params.Param enum')
        return self.values.get(param)

    cpdef set(self, param, int value):
        """Set param value."""
        if not isinstance(param, Param):
            raise TypeError('param must be tkvdb.params.Param enum')
        ctkvdb.tkvdb_param_set(self.params, param.value, value)
        self.values[param] = value

    cpdef free(self):
        """Free underlying C structure."""
        if self.is_initialized:
            ctkvdb.tkvdb_params_free(self.params)
            self.is_initialized = False

    def __dealloc__(self):
        """Destructor."""
        self.free()
