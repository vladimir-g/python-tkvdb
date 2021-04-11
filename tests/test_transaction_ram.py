import unittest

from tkvdb.transaction import Transaction
from tkvdb.errors import NotStartedError, EmptyError, NotFoundError
from .base import TestMixin


class TestTransactionRAM(TestMixin, unittest.TestCase):
    """Tests for RAM-mode transaction operations."""
    def test_transaction_begin(self):
        """Test transaction with and without begin."""
        transaction = Transaction()
        self.assertTrue(transaction.is_initialized)
        self.assertTrue(transaction.ram_only)
        self.assertFalse(transaction.is_started)
        with self.assertRaises(NotStartedError):
            transaction.put(b'key', b'value')
        transaction.begin()
        self.assertTrue(transaction.is_started)
        self.assertTrue(transaction.is_initialized)

    def test_transaction_free(self):
        """Test transaction free method."""
        transaction = Transaction()
        transaction.free()
        self.assertFalse(transaction.is_started)
        self.assertFalse(transaction.is_initialized)

    def test_get_put(self):
        """Test transaction get/put with rollbacks."""
        tr = Transaction()
        tr.begin()

        tr.put(b'put-1', b'value-1')
        self.assertEqual(tr.getvalue(b'put-1'), b'value-1')

        tr.rollback()
        tr.free()

    def test_get_put_with_stmt(self):
        """Test RAM transaction get/put."""
        with Transaction() as tr:
            tr.put(b'put-1', b'value-1')
            self.assertEqual(tr.getvalue(b'put-1'), b'value-1')

    def test_get_error(self):
        """Test RAM transaction get/put."""
        tr = Transaction()
        tr.begin()

        with self.assertRaises(EmptyError):
            tr.getvalue(b'key1')

        # Now put something and check different error
        tr.put(b'key2', b'value2')
        with self.assertRaises(NotFoundError):
            tr.getvalue(b'key1')

        tr.rollback()
        tr.free()

    def test_commit(self):
        """Test RAM transaction commit, must be empty after."""
        # Test with statement
        with Transaction() as tr:
            tr.put(b'put-commit-1', b'value-1')
            tr.put(b'put-commit-2', b'value-2')
            tr.commit()

        # RAM transaction is cleared on commit/rollback
        with Transaction() as tr:
            with self.assertRaises(EmptyError):
                self.assertEqual(tr.getvalue(b'put-commit-1'), b'value-1')
                self.assertEqual(tr.getvalue(b'put-commit-2'), b'value-2')

    def test_delete(self):
        """Test RAM transaction delete."""
        with Transaction() as tr:
            tr.put(b'to-delete', b'value')
            self.assertEqual(tr.getvalue(b'to-delete'), b'value')
            tr.delete(b'to-delete')
            with self.assertRaises(NotFoundError):
                tr.getvalue(b'to-delete')


if __name__ == '__main__':
    unittest.main()
