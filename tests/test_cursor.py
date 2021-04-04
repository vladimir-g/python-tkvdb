import unittest

from tkvdb import Tkvdb
from tkvdb.errors import NotFoundError, EmptyError
from .base import TestMixin


class TestCursor(TestMixin, unittest.TestCase):
    """Test cursors."""
    def test_init(self):
        """Test cursor initialization."""
        with self.db.transaction() as tr:
            c = tr.cursor()
            self.assertTrue(c.is_initialized)
            self.assertFalse(c.is_started)
            c.free()
            self.assertFalse(c.is_initialized)

    def test_first(self):
        """Test cursor first method."""
        with self.db.transaction() as tr:
            c = tr.cursor()
            with self.assertRaises(EmptyError):
                c.first()
            with self.assertRaises(NotFoundError):
                c.next()
            tr[b'key'] = b'value'
            tr.commit()

        with self.db.transaction() as tr:
            c = tr.cursor()
            c.first()
            self.assertTrue(c.is_started)
            self.assertEqual(c.key(), b'key')
            self.assertEqual(c.val(), b'value')

    def test_next(self):
        """Test cursor next iteration."""
        values = self.create_data('next')

        with self.db.transaction() as tr:
            c = tr.cursor()
            c.first()
            # Two sets for comparing db keys and values
            keys = set()
            vals = set()
            while True:
                k, v = c.key(), c.val()
                keys.add(k)
                vals.add(v)
                self.assertEqual(v, values[k])
                self.assertEqual(len(k), c.keysize())
                self.assertEqual(len(v), c.valsize())
                try:
                    c.next()
                except NotFoundError:
                    break
            self.assertEqual(set(keys), set(values.keys()))
            self.assertEqual(set(vals), set(values.values()))

    def test_context_manager(self):
        """Test with statement ."""
        values = self.create_data('next')

        with self.db.transaction() as tr:
            with tr.cursor() as c:
                c.first()
                # Same as test_next
                keys = set()
                vals = set()
                while True:
                    k, v = c.key(), c.val()
                    keys.add(k)
                    vals.add(v)
                    self.assertEqual(v, values[k])
                    self.assertEqual(len(k), c.keysize())
                    self.assertEqual(len(v), c.valsize())
                    try:
                        c.next()
                    except NotFoundError:
                        break
                self.assertEqual(set(keys), set(values.keys()))
                self.assertEqual(set(vals), set(values.values()))


if __name__ == '__main__':
    unittest.main()
