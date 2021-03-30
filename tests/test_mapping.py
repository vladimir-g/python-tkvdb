import unittest

from tkvdb import Tkvdb
from tkvdb.errors import NotStartedError, EmptyError
from .base import TestMixin


class TestMapping(TestMixin, unittest.TestCase):
    """Tests dict-like interface."""
    def test_getitem_setitem(self):
        """Test transaction getitem/setitem."""
        with self.db.transaction() as tr:
            tr[b'key-1'] = b'value-1'
            self.assertEqual(tr[b'key-1'], b'value-1')
            tr.rollback()

    def test_getitem_error(self):
        """Test transaction getitem errors."""
        with self.db.transaction() as tr:
            with self.assertRaises(KeyError):
                tr[b'missing']
            with self.assertRaises(TypeError):
                tr['missing']

    def test_get(self):
        """Test transaction get method."""
        with self.db.transaction() as tr:
            tr[b'key'] = b'value'
            self.assertEqual(tr.get(b'key'), b'value')
            self.assertEqual(tr.get(b'missing'), None)
            self.assertEqual(tr.get(b'missing', b'default'), b'default')
            tr.rollback()

    def test_delete(self):
        """Test transaction delitem."""
        with self.db.transaction() as tr:
            tr[b'to-delete'] = b'value'
            tr.commit()

        with self.db.transaction() as tr:
            self.assertEqual(tr[b'to-delete'], b'value')
            del tr[b'to-delete']
            tr.commit()

        with self.db.transaction() as tr:
            with self.assertRaises(KeyError):
                tr[b'to-delete']


if __name__ == '__main__':
    unittest.main()
