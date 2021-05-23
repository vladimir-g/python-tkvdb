import unittest
import tempfile

from tkvdb import Tkvdb
from tkvdb.transaction import Transaction
from tkvdb.params import Params, Param
from tkvdb.errors import NotStartedError
from .base import TestMixin


class TestParams(TestMixin, unittest.TestCase):
    """Test tkvdb_params."""
    def test_init(self):
        """Test params initialization."""
        params = Params()
        self.assertTrue(params.is_initialized)
        params.free()

    def test_set(self):
        """Test params set."""
        params = Params()

        # Set some param
        params.set(Param.Autobegin, 1)
        self.assertTrue(params.get(Param.Autobegin), 1)
        # Set invalid param
        with self.assertRaises(TypeError):
            params.set(9999, 1)

        params.free()

    def test_get(self):
        """Test params get."""
        params = Params()

        # Set value and check
        params.set(Param.TrDynalloc, 1)
        self.assertTrue(params.get(Param.TrDynalloc), 1)

        # Get missing value
        self.assertEqual(params.get(Param.TrLimit), None)

        params.free()

    def test_getvalues(self):
        """Test params get."""
        values = {Param.TrDynalloc: 1, Param.Autobegin: 1}
        # Set from constructor
        params = Params(values)
        self.assertEqual(params.get_values(), values)
        params.free()

    def test_transaction(self):
        """Test passing params to transaction."""
        params = Params({Param.Autobegin: 1})
        # Create RAM-only transaction
        tr = Transaction(params=params)
        tr.put(b'key', b'value')  # Must not fail
        params.free()

    def test_db(self):
        """Test passing params to database."""
        params = Params({Param.Autobegin: 1})
        path = tempfile.NamedTemporaryFile(delete=False).name
        with Tkvdb(path, params) as db:
            tr = Transaction(db=db, ram_only=False)
            tr.put(b'key', b'value')  # Must not fail

            # Now override params
            params = Params({Param.Autobegin: 0})
            tr = Transaction(db=db, ram_only=False, params=params)
            with self.assertRaises(NotStartedError):
                tr.put(b'key', b'value')  # Must fail

            # Test passing params through db handle
            with db.transaction(params) as tr:
                tr.put(b'key', b'value')  # Not failing

        # Test again
        with Tkvdb(path) as db:
            params = Params({Param.Autobegin: 1})
            with db.transaction(params) as tr:
                tr.put(b'key', b'value')


if __name__ == '__main__':
    unittest.main()
