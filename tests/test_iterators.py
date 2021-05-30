import unittest

from tkvdb import Tkvdb
from tkvdb.errors import NotFoundError, EmptyError
from .base import TestMixin


class TestIterators(TestMixin, unittest.TestCase):
    """Test python iterators for cursor and transaction."""
    def test_transaction_keys(self):
        """Test transaction keys iterator."""
        keys = self.create_data('keys-transaction')
        with self.db.transaction() as tr:
            for key in tr:
                self.assertTrue(key in keys)
                self.assertEqual(tr[key], keys[key])

    def test_transaction_values(self):
        """Test transaction values iterator."""
        data = self.create_data('values-transaction')
        with self.db.transaction() as tr:
            for value in tr.values():
                self.assertTrue(value in data.values())
                k = list(data.keys())[list(data.values()).index(value)]
                self.assertEqual(value, data[k])

    def test_transaction_items(self):
        """Test transaction items iterator."""
        data = self.create_data('items-transaction')
        with self.db.transaction() as tr:
            for key, value in tr.items():
                self.assertTrue(key in data)
                self.assertTrue(value in data.values())
                self.assertEqual(tr[key], data[key])

    def test_cursor_keys(self):
        """Test cursor keys iterator."""
        keys = self.create_data('keys-cursor')
        with self.db.transaction() as tr:
            with tr.cursor() as c:
                for key in c:
                    self.assertEqual(c.key(), key)
                    self.assertTrue(key in keys)
                    self.assertEqual(tr[key], keys[key])

    def test_cursor_values(self):
        """Test cursor values iterator."""
        data = self.create_data('values-cursor')
        with self.db.transaction() as tr:
            with tr.cursor() as c:
                for value in c.values():
                    self.assertTrue(value in data.values())
                    k = list(data.keys())[list(data.values()).index(value)]
                    self.assertEqual(value, data[k])

    def test_cursor_items(self):
        """Test cursor items iterator."""
        data = self.create_data('items-cursor')
        with self.db.transaction() as tr:
            with tr.cursor() as c:
                for key, value in c.items():
                    self.assertTrue(key in data)
                    self.assertTrue(value in data.values())
                    self.assertEqual(tr[key], data[key])

    def test_cursor_reversed(self):
        """Test cursor reversed iterators."""
        keys = self.create_data('keys-reversed')
        sorted_keys = list(reversed(sorted(list(keys.keys()))))
        with self.db.transaction() as tr:
            with tr.cursor() as c:
                for i, key in enumerate(reversed(c.keys())):
                    self.assertEqual(sorted_keys[i], key)

    def test_transaction_reversed(self):
        """Test cursor reversed iterators."""
        keys = self.create_data('keys-reversed')
        sorted_keys = list(reversed(sorted(list(keys.keys()))))

        # Test default iterator
        with self.db.transaction() as tr:
            for i, key in enumerate(reversed(tr)):
                self.assertEqual(sorted_keys[i], key)

        # Test named iterator
        with self.db.transaction() as tr:
            for i, kv in enumerate(reversed(tr.items())):
                self.assertEqual(sorted_keys[i], kv[0])

    def test_cursor_consistency(self):
        """Test cursor iterator consistency, it must be same cursor."""
        data = self.create_data('cons-cursor', num=10)
        with self.db.transaction() as tr:
            with tr.cursor() as c:
                keys = list()
                for i, key in enumerate(c):
                    keys.append(key)
                    self.assertTrue(key in data)
                    self.assertEqual(tr[key], data[key])
                    if i == 4:
                        break
                for i, value in enumerate(c.values()):
                    self.assertTrue(value in data.values())
                    k = list(data.keys())[list(data.values()).index(value)]
                    keys.append(k)
                    # Only five items remain in second loop
                    self.assertTrue(i < 5)
                self.assertEqual(list(data.keys()), keys)


if __name__ == '__main__':
    unittest.main()
