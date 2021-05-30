# python-tkvdb

Python-tkvdb is a Cython wrapper for
[tkvdb](https://github.com/vmxdev/tkvdb) trie key-value
database. Python 3 is required.

Code isn't well tested in production environments.

## Installation

This is a typical python/cython package that uses setuptools build
system.

### From PyPi

The most simple way of installing is using `pip`:

    pip install python-tkvdb

Considering that package is using Cython, C compiler may be required
for building if suitable wheel for current platform isn't found.

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
- `tkvdb.params` -- database and transaction params. Wrapper around `tkvdb_params`.

### Database initialization

Database is wrapped into the `Tkvdb` object from `tkvdb` or `tkvdb.db`
modules. At this time only path to database file is
supported. Parameters (`tkvdb.params.Params`) optionally may be passed
to constructor.

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
- `Tkvdb(path: str, params: tkvdb.params.Params = None)` (constructor)
  -- create database instance.
- `close()` -- close database.
- `transaction(params: tkvdb.params.Params = None) ->
  tkvdb.transaction.Transaction` -- create transaction.

There is also Cython method `get_db` that returns `tkvdb_db *`
pointer.

### Transactions

Transactions are basic way to do any operation with database. Consult
with original documentation about transaction term, because it doesn't
mean same thing as in other database systems.

**Input and ouput uses `bytes` type for everything**. Encode and
decode strings if needed.

Parameters (`tkvdb.params.Params`) optionally may be passed to
constructor.

Transaction must be created from database instance (described in
previous part):

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

Multiple keys may be deleted by `delete` method using optional
`prefix` argument (default `False`). Passing `True` allows deleting
keys starting from prefix. Dict-like `del` operator always deletes
only exact key.

Attributes (readonly):
- `is_initialized: bool` -- shows that transaction underlying
  structures are initialized properly.
- `is_started: bool` -- shows that `begin()` method was called.
- `is_changed: bool` -- shows that transaction had any uncommited
  changes (i.e. `put()` was used).
- `ram_only: bool` -- indicates that transaction is RAM-only.

Transaction methods. Most of them may raise an exception:

- `Transaction(ram_only=True, params: tkvdb.params.Params = None)`
  (constructor) -- create transaction instance. Must be called
  manually only for RAM-only usage, otherwise `db.transaction()` must
  be used instead.
- `begin()` -- starts transaction, calls underlying `tkvdb_tr->begin()`.
- `getvalue(key: bytes) -> bytes` -- get value by key.
- `put(key: bytes)` -- insert value into db by key.
- `get(key: bytes, default: bytes = None) -> bytes` -- dict-like get with
  default value.
- `delete(key: bytes, prefix=False)` -- delete value by key. With
  `prefix=True` all keys staring with `key` will be deleted.
- `__getitem__`, `__setitem__`, `__delitem__` -- dict-like methods.
- `__contains__` -- allows usage of `in` operator.
- `free()` -- free transaction (called in `with` statement
  automatically).
- `keys()`, `values()`, `items()` -- return dict-like iterators.
- `cursor(seek_key=None, seek_type=Seek.EQ)` -- return transaction
  cursor (see `Cursors`), with optional seek.


#### RAM-only transactions

Transactions also may be used in RAM-only mode. These transactions don't
require database file and use less memory. They are cleared on
`commit()` or `rollback()`. See more about RAM-only transactions in
original documentation.

Use `tkvdb.Transaction()` constructor to create RAM-only transaction
without database. This transaction may also be used with `with`
statement, same auto-begin rules apply. Example:

```python
with Transaction() as tr:
    tr[b'key'] = b'value'
    print(tr[b'key'])  # prints b'value'
    tr.commit()  # clears transaction
```

### Iterators

Transaction can be traversed using iterators. It is also the main way
for iterating through database contents.

Module `tkvdb.iterators` provides three dict-like iterators that use
`tkvdb.cursor.Cursor` inside:

- `tkvdb.iterators.KeysIterator` -- iterating over keys.
- `tkvdb.iterators.ValuesIterator` -- iterating over values.
- `tkvdb.iterators.ItemsIterator` -- iterating over key-value pair.

They can be used with transaction:

```python
with db.transaction() as tr:
    for key in tr:  # or tr.keys()
        print(tr[key])
    for value in tr.values():
        print(value)
    for key, value in tr.items():
        print(key, value)
```

In all loops new instance of `Cursor` is used.

They also can be used with cursor:

```python
with db.transaction() as tr:
    with tr.cursor() as c:
        for key in c:
            print(c.key(), c.keysize())
```

Notice that cursor iterators use same underlying `Cursor` object, so
they would iterate from same place where cursor stopped before:

```python
with db.transaction() as tr:
    with tr.cursor() as c:
        c.first()
        # do some iteration with c.next()
        for key in c:
            print(key)  # it wouldn't be first key
            if something:
                break
        for value in c.values():  # starts from last iterated key
            print(value)
```

Reverse iteration is available through the standard `reversed`
function. Iterators and transaction have required methods for this.
For new cursors iteration will start from the end using
`tkvdb.cursor.Cursor.last`.

```python
with db.transaction() as tr:
    for key in reversed(tr):
        print(key)
    # All iterator types allow this
    for key, value in reversed(tr.items()):
        print(key, value)

with db.transaction() as tr:
    with tr.cursor() as c:
        for key in reversed(c):
            print(key)
    with tr.cursor() as c:
        for value in reversed(c.values()):
            print(value)
```

Cursors created from transacton can used for searching (as shorthand
for `tkvdb.cursor.Cursor.seek()`). More information in next section.

```python
with db.transaction() as tr:
    with tr.cursor(seek_key=b'seek-tr-31', seek_type=Seek.GE) as c:
        print(c.key())
```

### Cursors

Cursors are used to iterate through database contents. They are
defined in `tkvdb.cursor` module, C implementation is wrapped in
`tkvdb.cursor.Cursor` class.

Cursors are attached to transaction and created by
`Transacion.cursor()` method. They also may be created directly.

Although cursors are sole way to iterate and seek in tkvdb, it is
better and easier to use python-style iterators for
such purposes.

Example usage:

```python
with db.transaction() as tr:
    with tr.cursor() as c:
        c.first()
        while True:
            print(c.key(), c.value())
            try:
                c.next()
            except tkvdb.errors.NotFoundError:
                break
```

Cursor also may be used without `with` statement, it would be freed
anyway on garbage collection:

```python
with db.transaction() as tr:
    c = tr.cursor():
    c.first()
    # ...
```

Notice: `first` and `next` methods throw `tkvdb.errors.EmptyError` on
empty database, not `NotFoundError`. Cursors may be iterated by using
iterators (see previous section).

Cursor also may be iterated in reverse order using `prev()`
method. Another method called `last()` moves cursor to last record and
often useful for the reverse iteration.

Cursor can be used for search with `seek()` method. This allows
searching k-v pair by prefix using seek criteria. Criterias are
defined in `tkvdb.cursor.Seek` enum:

- `Seek.EQ` -- search for the exact key match.
- `Seek.LE` -- search for less (in terms of memcmp()) or equal key.
- `Seek.GE` -- search for greater (in terms of memcmp()) or equal key.

Seeking is also may be initiated using `Transaction.cursor()` method
(see more in `Transactions` section).

```python
from tkvdb.cursor import Seek

with db.transaction() as tr:
    with tr.cursor() as c:
        c.seek(b'key', Seek.EQ)
        key = c.key()
        # ...
        c.next()

    with tr.cursor(seek_key=b'key') as c:
        # ...
```

Attributes (readonly):
- `is_initialized: bool` -- shows that cursor underlying
  structures are initialized properly.
- `is_started: bool` -- shows that `first()` method was called.

Cursor methods.

- `first()` -- move cursor to first item in database.
- `last()` -- move cursor to last item in database.
- `next()` -- move cursor to next item in database.
- `prev()` -- move cursor to previous item in database.
- `key() -> bytes` -- get current key.
- `val() -> bytes` -- get current value.
- `keysize() -> int` -- get current key size.
- `valsize() -> int` -- get current value size.
- `free()` -- free cursor.
- `__iter__()` -- returns `tkvdb.iterators.KeysIterator`.
- `seek(key: bytes, seek: tkvdb.cursor.Seek)` -- search key by
  criteria.
- `keys()`, `values()`, `items()` -- return dict-like iterators.

### Params

Params are used to specify different options for database and/or
transactions. They are defined in `tkvdb.params` module: the C
implementation (`tkvdb_params` struct) is wrapped by
`tkvdb.params.Params` class, and param values are wrapped by the
`tkvdb.params.Param` enum.

Parameter names transfomed using CamelCase, example: 

```
TKVDB_PARAM_TR_DYNALLOC => TrDynalloc
TKVDB_PARAM_CURSOR_STACK_DYNALLOC => CursorStackDynalloc
```

Available parameters in `tkvdb.params.Param` enum:

- `TrDynalloc` -- `TKVDB_PARAM_TR_DYNALLOC`
- `TrLimit` -- `TKVDB_PARAM_TR_LIMIT`
- `Alignval` -- `TKVDB_PARAM_ALIGNVAL`
- `Autobegin` -- `TKVDB_PARAM_AUTOBEGIN`
- `CursorStackDynalloc` -- `TKVDB_PARAM_CURSOR_STACK_DYNALLOC`
- `CursorStackLimit` -- `TKVDB_PARAM_CURSOR_STACK_LIMIT`
- `CursorKeyDynalloc` -- `TKVDB_PARAM_CURSOR_KEY_DYNALLOC`
- `CursorKeyLimit` -- `TKVDB_PARAM_CURSOR_KEY_LIMIT`
- `DbfileOpenFlags` -- `TKVDB_PARAM_DBFILE_OPEN_FLAGS`

Consult with original `tkvdb` documentation for params meaning and
possible values.

Params usage:

```python
from tkvdb.params import Params, Param

# Passing params to database
params = Params({Param.Autobegin: 1})  # set params at init
with Tkvdb(path, params) as db:
    # Params also will be passed to db transactions
    with db.transaction() as tr:
        # ...
    # Transaction may use own params
    params = Params()
    params.set(Param.TrLimit, 100)
    with db.transaction(params) as tr:
        # ...

# Setting params after init
params = Params()
params.set(Param.Autobegin, 1)
tr = Transaction(params=params)  # RAM-only transaction
```

As in original `tkvdb` code, params from database are passed to
db-bound transaction, if they aren't overrided directly by passing
another `Params` instance to transaction.

Python implementation also stores all set params and stores them in
internal `values` dict. Notice that it tracks only params that were
set directly, so default values aren't known to `Params` wrapper.

Params attributes:
- `is_initialized: bool` -- shows that params underlying structures
  are initialized properly.

Params methods:
- `Params(params=None)` (constructor) -- create params
  instance. Argument `params` may be dict with param names and values.
- `get_values()` -- return all set params.
- `get(param: tkvdb.params.Param)` -- return single param value.
- `set(param: tkvdb.params.Param, value: int)` -- set param value.
- `free()` -- free params object.

There is also Cython method `get_params` that returns `tkvdb_params *`
pointer.

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


## License

Python-tkvdb is licensed under ISC license as original tkvdb project.
