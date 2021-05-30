import unittest

from tkvdb import Tkvdb
from tkvdb.errors import NotStartedError, EmptyError, NotFoundError
from .base import TestMixin


class TestTransaction(TestMixin, unittest.TestCase):
    """Tests for transaction operations."""
    def test_transaction_begin(self):
        """Test transaction with and without begin."""
        transaction = self.db.transaction()
        self.assertTrue(transaction.is_initialized)
        self.assertFalse(transaction.is_started)
        self.assertFalse(transaction.ram_only)
        with self.assertRaises(NotStartedError):
            transaction.put(b'key', b'value')
        transaction.begin()
        self.assertTrue(transaction.is_started)
        transaction.rollback()

    def test_transaction_free(self):
        """Test transaction free method."""
        transaction = self.db.transaction()
        transaction.free()
        self.assertFalse(transaction.is_started)
        self.assertFalse(transaction.is_initialized)

    def test_get_put(self):
        """Test transaction get/put with rollbacks."""
        tr = self.db.transaction()
        tr.begin()

        tr.put(b'put-1', b'value-1')
        self.assertEqual(tr.getvalue(b'put-1'), b'value-1')

        tr.rollback()
        tr.free()

    def test_get_put_with_stmt(self):
        """Test transaction get/put with rollbacks."""
        with self.db.transaction() as tr:
            tr.put(b'put-1', b'value-1')
            self.assertEqual(tr.getvalue(b'put-1'), b'value-1')
            tr.rollback()

    def test_get_error(self):
        """Test transaction get/put with rollbacks."""
        tr = self.db.transaction()
        tr.begin()

        with self.assertRaises(EmptyError):
            tr.getvalue(b'key1')

        # Now put something and check different error
        tr.put(b'key2', b'value2')
        with self.assertRaises(NotFoundError):
            tr.getvalue(b'key1')

        tr.rollback()
        tr.free()

    def test_get_put_commit(self):
        """Test transaction get/put with commits."""
        # Test with statement
        with self.db.transaction() as tr:
            tr.put(b'put-commit-1', b'value-1')
            tr.put(b'put-commit-2', b'value-2')
            tr.commit()

        with self.db.transaction() as tr:
            self.assertEqual(tr.getvalue(b'put-commit-1'), b'value-1')
            self.assertEqual(tr.getvalue(b'put-commit-2'), b'value-2')

    def test_commit_reopen(self):
        """Test transaction get/put with commits."""
        with self.db.transaction() as tr:
            tr.put(b'put-reopen-1', b'value-1')
            tr.put(b'put-reopen-2', b'value-2')
            tr.commit()

        # Reopen database
        self.db.close()
        self.db = Tkvdb(self.path)

        with self.db.transaction() as tr:
            self.assertEqual(tr.getvalue(b'put-reopen-1'), b'value-1')
            self.assertEqual(tr.getvalue(b'put-reopen-2'), b'value-2')

    def test_rollback(self):
        """Test transaction rollback."""
        with self.db.transaction() as tr:
            tr.put(b'rollback', b'value')
            tr.rollback()

        with self.db.transaction() as tr:
            with self.assertRaises(EmptyError):
                tr.getvalue(b'rollback')

    def test_delete(self):
        """Test transaction delete."""
        with self.db.transaction() as tr:
            tr.put(b'to-delete', b'value')
            tr.commit()

        with self.db.transaction() as tr:
            self.assertEqual(tr.getvalue(b'to-delete'), b'value')
            tr.delete(b'to-delete')
            tr.commit()

        with self.db.transaction() as tr:
            with self.assertRaises(NotFoundError):
                tr.getvalue(b'to-delete')

    def test_delete_rollback(self):
        """Test transaction delete."""
        with self.db.transaction() as tr:
            tr.put(b'to-delete-rb', b'value')
            tr.commit()

        with self.db.transaction() as tr:
            self.assertEqual(tr.getvalue(b'to-delete-rb'), b'value')
            tr.delete(b'to-delete-rb')
            tr.rollback()

        with self.db.transaction() as tr:
            self.assertEqual(tr.getvalue(b'to-delete-rb'), b'value')

    def test_delete_prefix(self):
        """Test transaction delete with prefix."""
        with self.db.transaction() as tr:
            tr.put(b'to-delete-1', b'value')
            tr.put(b'to-delete-2', b'value')
            tr.put(b'other-prefix', b'value')
            tr.commit()

        with self.db.transaction() as tr:
            self.assertEqual(tr.getvalue(b'to-delete-1'), b'value')
            self.assertEqual(tr.getvalue(b'to-delete-2'), b'value')
            tr.delete(b'to-delete', prefix=True)
            with self.assertRaises(NotFoundError):
                tr.getvalue(b'to-delete-1')
                tr.getvalue(b'to-delete-2')
            self.assertEqual(tr.getvalue(b'other-prefix'), b'value')


if __name__ == '__main__':
    unittest.main()
