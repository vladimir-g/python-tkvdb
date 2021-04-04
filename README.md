# python-tkvdb

Python-tkvdb is a Cython wrapper for
[tkvdb](https://github.com/vmxdev/tkvdb) trie key-value
database. Python 3 is required.

**Project is in very alpha stage now. Just do not use.**

## Installation

This is a typical python/cython package that uses setuptools build
system.

### Downloading

Original tkvdb sources are included as submodule, so when installing
from git please use `git clone --recursive` for cloning, or init
submodules after with `git submodule update --init
--recursive`. Custom sources may also be provided in `tkvdb/`
subdirectory before build.

Source archives that were made with `python setup.py sdist` contain
generated C-code without `.pyx` files as Cython official documentation
recommends. Cython header files (`.pxd`) still provided though.

Package also can be distributed as python wheels. With wheels no
additional post-installation actions are required.

Initialization and usage of virtualenv or alternatives aren't
properly described in this manual, so use them by you own discretion.

### Building

Project uses Cython to generate C extension for Python. To build
package, you need to have C compiler and build tools.

For installation from the source archive, Cython isn't required, but
git versions require it. Source directory also includes
`pyproject.toml` (PEP 518), so if your build tool uses it, Cython
would be installed anyway.

To make common tasks easier, project contains simple Makefile that may
be used instad of pip/python commands. It isn't a requirement, so `pip
install .` also works. For additional reference, look into
[Makefile](Makefile).

Install example with virtualenv:

    cd python-tkvdb/
    python -m venv env
    source ./env/bin/activate
    make

Both Makefile and setup.py uses ``USE_CYTHON`` env variable (int, 0/1)
to determine if Cython (cythonize) would be started before extension
building. Cython needs to be installed in local environment for
this. Default value is 1 for make.

Makefile also has ``PYTHON`` env var that allows overriding python
interpreter path. Default value is just ``python``.

Example usage:

    USE_CYTHON=1 PYTHON=./env/bin/python make build

Make commands:

- `build` -- just build extension with `python setup.py build_ext`.
- `install` -- run `pip install`. Extension would be built if needed.
- no arguments (just `make`) -- alias for `install`.
- `dist` -- create wheel and sdist archive.
- `test` -- run unit tests
- `clean` -- remove generated code, compiled objects and distribution
archives.
- `uninstall` -- remove previously installed package (through `pip`)

After installing module `tkvdb` must be importable in the Python environment.

## Usage

Original `tkvdb` uses pretty specific terminology for some actions
(like transaction), so it is recommended to first consult with
original documentation anyway. Thread-safety notes and some caveats
are also described in the original README file.

Python-tkvdb provides pythonic-style wrapper for most parts of the original
library.

Most object have destructors that call `free` internally and do memory
management on garbage collection, but don't forget that this is
wrapper for C library.

All objects have internal `init()` method that receives C structures
(`ctkvdb.tkvdb*` etc), because Cython doesn't allow passing C values
in `__cinit__` constructor. They may be used from Cython code, but not
required in Python and called mostly automatically.

Some code examples may also be found in [tests code](tests/).

### Modules

Project is splitted into multiple python modules:

- `ctkvdb` -- Cython wrapper with C definitions from `tkvdb.h`.
- `tkvdb.db` -- database object and initialization. Also imported in
  `__init__.py` (i.e. main `tkvdb` module).
- `tkvdb.transaction` -- transaction (actually main input/output.
  interface). Wrapper around ``tkvdb_tr``.
- `tkvdb.cursor` -- transaction cursors for iteration. Wrapper around `tkvdb_cursor`.
- `tkvdb.iterators` -- pythonic iterators for `tkvdb.cursor`.
- `tkvdb.errors` -- all db-related exceptions that code may throw.

### Database initialization

Database is wrapped into the `Tkvdb` object from `tkvdb` or `tkvdb.db`
modules. At this time only path to database file is supported.

```python
from tkvdb import Tkvdb

db = Tkvdb(path_to_db_file)
# some code
db.close()
```

Context manager (`with` statment) that includes auto closing is also
available:

```python
with Tkvdb(path_to_db_file) as db:
    # some code
    with db.transaction() as tr:
        # more code
```

Attributes (readonly):
- `path: str` -- path to database file.
- `is_opened: bool` -- shows that database is initialized properly.

Methods (may raise exceptions):
- `Tkvdb(path: str)` (constructor) -- create database instance.
- `close()` -- close database.
- `transaction() -> tkvdb.transaction.Transaction` -- create
  transaction.
  

### Transactions

Transactions are basic way to do any operation with database. Consult
with original documentation about transaction term, because it doesn't
mean same thing as in other database systems.

**Input and ouput uses `bytes` type for everything**. Encode and
decode strings if needed.

Transaction must be created from database instance (described in
previous part)

```python
transaction = db.transaction()
transaction.begin()
transaction.put(b'key', b'value')
transaction.commit() # or transaction.rollback()
print(transaction.getvalue(b'key'))
transaction.free()
```

Pythonic `with` statment also available:

```python
with db.transaction() as tr:
    tr.put(b'key', b'value')
    tr.commit()
    print(tr.getvalue(b'key'))
```

Note that `with` statement *does not do commit, but rollbacks on
exception*. Do `commit` or `rollback` with your own code, or don't do
anything (implies rollback-like behavior). Transaction is started
(`begin`) automatically and will be freed (`free`) at exit from `with`
block though.

Transaction also has Python dict-like interface:

- `__getitem__` and `__setitem__`
- `get(key, default=None)`
- `keys()`, `values()` and `items()` iterators

```python
with db.transaction() as tr:
    tr[b'key'] = b'value'
    print(tr.get(b'other-key', b'default')) # prints b'default'
    tr.commit()
    print(tr[b'key']) # prints b'value'

    # Iterators
    for key in tr: # or tr.keys()
        print(key)
    for key, value in tr.items():
        print(key, value)
    for value in tr.values():
        print(value)
```

Attributes (readonly):
- `is_initialized: bool` -- shows that transaction underlying
  structures are initialized properly.
- `is_started: bool` -- shows that `begin()` method was called.
- `is_changed: bool` -- shows that transaction had any uncommited
  changes (i.e. `put()` was used).

Transaction methods. Most of them may raise an exception:

- `begin()` -- starts transaction, calls underlying `tkvdb_tr->begin()`.
- `getvalue(key: bytes) -> bytes` -- get value by key.
- `put(key: bytes)` -- insert value into db by key.
- `get(key: bytes, default: bytes = None) -> bytes` -- dict-like get with
  default value.
- `delete(key: bytes)` -- delete value by key.
- `__getitem__`, `__setitem__`, `__delitem__` -- dict-like methods.
- `free()` -- free transaction (called in `with` statement
  automatically).
- `keys()`, `values()`, `items()` -- return dict-like iterators.

### Cursors

Cursors are used to iterate through database contents. They are
defined in `tkvdb.cursor` module, C implementation is wrapped in
`tkvdb.cursor.Cursor` class.

Cursors are attached to transaction and created by
`Transacion.cursor()` method. They also may be created directly, but
need to be initialized in Cython.

Although cursors are sole way to iterate and seek in tkvdb, it is
better and easier to use python-style iterators for
such purposes.

Example usage:

```python
with self.db.transaction() as tr:
    c = tr.cursor()
    c.first()
    while True:
        print(c.key(), c.value())
        try:
            c.next()
        except tkvdb.errors.NotFoundError:
            break
```

Notice: `first` and `next` methods throw `tkvdb.errors.EmptyError` on
empty database, not `NotFoundError`. Cursors may be iterated by key
(see `tkvdb.iterator.KeysIterator`).

Attributes (readonly):
- `is_initialized: bool` -- shows that cursor underlying
  structures are initialized properly.
- `is_started: bool` -- shows that `first()` method was called.

Cursor methods.

- `first()` -- move cursor to first item in database.
- `next()` -- move cursor to next item in database.
- `key() -> bytes` -- get current key.
- `val() -> bytes` -- get current value.
- `keysize() -> int` -- get current key size.
- `valsize() -> int` -- get current value size.
- `free()` -- free cursor.
- `__iter__()` -- returns `tkvdb.iterators.KeysIterator`.

### Iterators

TBD

### Errors

Error classes are defined in `tkvdb.errors` module. Every non-ok
return value from the underlying C code is converted to python
Exception. Only `TKVDB_RES.TKVDB_OK` considered as success.

Consult with original documentation for error codes meaning.

One exception from this rule is
`tkvdb.transaction.Transaction.__getitem__()` (dict-like access) that
raises `KeyError` for python compatibility.

Examples:

```python
from tkvdb.errors import EmptyError, NotFoundError, NotStartedError

# ...
tr = db.transaction()
try:
    print(tr.getvalue(b'key'))
except (NotFoundError, EmptyError):
    print('key not found')
except NotStartedError:
    print('transaction not started')

with db.transaction() as tr:
    try:
        print(tr[b'key'])
    except KeyError:
        print('key not found')
```

Note that tkvdb raises `EmptyError` (`TKVDB_RES.TKVDB_EMPTY` return
code), not `NotFoundError` when key is not found in empty database,

Errors:

- `Error` -- base class for all tkvdb-related errors.
- `IoError` -- `TKVDB_RES.TKVDB_IO_ERROR` code.
- `LockedError` -- `TKVDB_RES.TKVDB_LOCKED` code.
- `EmptyError` -- `TKVDB_RES.TKVDB_EMPTY` code.
- `NotFoundError` -- `TKVDB_RES.TKVDB_NOT_FOUND` code.
- `EnomemError` -- `TKVDB_RES.TKVDB_ENOMEM` code.
- `CorruptedError` -- `TKVDB_RES.TKVDB_CORRUPTED` code.
- `NotStartedError` -- `TKVDB_RES.TKVDB_NOT_STARTED` code.
- `ModifiedError` -- `TKVDB_RES.TKVDB_MODIFIED` code.


## Missing features

- Iterators tests and documentation
- TKVDB_PARAM isn't implemented
- Cursor seek/prev/last
- RAM mode
- PyPi package

## License

Python-tkvdb is licensed under ISC license as original tkvdb project.
