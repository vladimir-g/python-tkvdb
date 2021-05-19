cdef extern from "tkvdb.h":
    cpdef enum TKVDB_RES:
        TKVDB_OK = 0
        TKVDB_IO_ERROR
        TKVDB_LOCKED
        TKVDB_EMPTY
        TKVDB_NOT_FOUND
        TKVDB_ENOMEM
        TKVDB_CORRUPTED
        TKVDB_NOT_STARTED
        TKVDB_MODIFIED

    cpdef enum TKVDB_PARAM:
        TKVDB_PARAM_TR_DYNALLOC
        TKVDB_PARAM_TR_LIMIT
        TKVDB_PARAM_ALIGNVAL
        TKVDB_PARAM_AUTOBEGIN
        TKVDB_PARAM_CURSOR_STACK_DYNALLOC
        TKVDB_PARAM_CURSOR_STACK_LIMIT
        TKVDB_PARAM_CURSOR_KEY_DYNALLOC
        TKVDB_PARAM_CURSOR_KEY_LIMIT
        TKVDB_PARAM_DBFILE_OPEN_FLAGS

    cpdef enum TKVDB_SEEK:
        TKVDB_SEEK_EQ
        TKVDB_SEEK_LE
        TKVDB_SEEK_GE

    ctypedef struct tkvdb:
        pass

    ctypedef struct tkvdb_cursor:
        void *(*key)(tkvdb_cursor *c);
        size_t (*keysize)(tkvdb_cursor *c);

        void *(*val)(tkvdb_cursor *c);
        size_t (*valsize)(tkvdb_cursor *c);

        tkvdb_datum (*key_datum)(tkvdb_cursor *c);
        tkvdb_datum (*val_datum)(tkvdb_cursor *c);

        TKVDB_RES (*seek)(tkvdb_cursor *c,
                          const tkvdb_datum *key, TKVDB_SEEK seek);
        TKVDB_RES (*first)(tkvdb_cursor *c);
        TKVDB_RES (*last)(tkvdb_cursor *c);

        TKVDB_RES (*next)(tkvdb_cursor *c);
        TKVDB_RES (*prev)(tkvdb_cursor *c);

        void (*free)(tkvdb_cursor *c);
        void *data;


    ctypedef struct tkvdb_params:
        pass

    ctypedef struct tkvdb_datum:
        void *data
        size_t size

    ctypedef struct tkvdb_tr:
        TKVDB_RES (*begin)(tkvdb_tr *tr);
        TKVDB_RES (*commit)(tkvdb_tr *tr);
        TKVDB_RES (*rollback)(tkvdb_tr *tr);

        TKVDB_RES (*put)(tkvdb_tr *tr,
                         const tkvdb_datum *key, const tkvdb_datum *val);
        TKVDB_RES (*get)(tkvdb_tr *tr,
                         const tkvdb_datum *key, tkvdb_datum *val);
        TKVDB_RES (*delete "del")(tkvdb_tr *tr, const tkvdb_datum *key, int del_pfx);

        size_t (*mem)(tkvdb_tr *tr);

        void (*free)(tkvdb_tr *tr);

        void *data;

    tkvdb_params *tkvdb_params_create();
    void tkvdb_param_set(tkvdb_params *params, TKVDB_PARAM p, unsigned long long val) # FIXME! int64_t
    void tkvdb_params_free(tkvdb_params *params);
    tkvdb *tkvdb_open(const char *path, tkvdb_params *params);
    TKVDB_RES tkvdb_close(tkvdb *db);
    TKVDB_RES tkvdb_sync(tkvdb *db);
    tkvdb_tr *tkvdb_tr_create(tkvdb *db, tkvdb_params *params);
    tkvdb_cursor *tkvdb_cursor_create(tkvdb_tr *tr);
