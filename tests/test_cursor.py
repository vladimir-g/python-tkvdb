import unittest

from tkvdb import Tkvdb
from tkvdb.errors import NotFoundError, EmptyError
from tkvdb.cursor import Seek
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
            tr[b'key1'] = b'value1'
            tr[b'key2'] = b'value2'
            tr.commit()

        with self.db.transaction() as tr:
            c = tr.cursor()
            c.first()
            self.assertTrue(c.is_started)
            self.assertEqual(c.key(), b'key1')
            self.assertEqual(c.val(), b'value1')

    def test_last(self):
        """Test cursor last method."""
        with self.db.transaction() as tr:
            c = tr.cursor()
            with self.assertRaises(EmptyError):
                c.last()
            with self.assertRaises(NotFoundError):
                c.prev()
            tr[b'key1'] = b'value1'
            tr[b'key2'] = b'value2'
            tr.commit()

        with self.db.transaction() as tr:
            c = tr.cursor()
            c.last()
            self.assertTrue(c.is_started)
            self.assertEqual(c.key(), b'key2')
            self.assertEqual(c.val(), b'value2')

    def test_next(self):
        """Test cursor next iteration."""
        values = self.create_data('next')

        with self.db.transaction() as tr:
            c = tr.cursor()
            c.first()
            # Sequences for comparing db keys and values
            keys = []
            vals = set()
            while True:
                k, v = c.key(), c.val()
                keys.append(k)
                vals.add(v)
                self.assertEqual(v, values[k])
                self.assertEqual(len(k), c.keysize())
                self.assertEqual(len(v), c.valsize())
                try:
                    c.next()
                except NotFoundError:
                    break
            self.assertEqual(keys, list(values.keys()))
            self.assertEqual(set(vals), set(values.values()))

    def test_prev(self):
        """Test cursor prev iteration."""
        values = self.create_data('next')

        with self.db.transaction() as tr:
            c = tr.cursor()
            c.last()
            # Sequences for comparing db keys and values
            keys = []
            vals = set()
            while True:
                k, v = c.key(), c.val()
                keys.append(k)
                vals.add(v)
                self.assertEqual(v, values[k])
                self.assertEqual(len(k), c.keysize())
                self.assertEqual(len(v), c.valsize())
                try:
                    c.prev()
                except NotFoundError:
                    break
            self.assertEqual(keys, list(reversed(list(values.keys()))))
            self.assertEqual(set(vals), set(values.values()))

    def test_context_manager(self):
        """Test with statement."""
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

    def test_seek_eq(self):
        """Test cursor seek iteration with Seek.EQ."""
        values = self.create_data('seek')

        # Check seek from third element, EQ
        with self.db.transaction() as tr:
            with tr.cursor() as c:
                c.seek(b'seek-3', Seek.EQ)
                # Two sets for comparing db keys and values
                keys = set()
                while True:
                    k, v = c.key(), c.val()
                    keys.add(k)
                    self.assertEqual(v, values[k])
                    self.assertEqual(len(k), c.keysize())
                    try:
                        c.next()
                    except NotFoundError:
                        break
                self.assertEqual(set(keys), set(sorted(values.keys())[3:]))

    def seek_common(self, type_, index):
        """Common code for testing Seek.GE and Seek.LE."""
        values = []
        with self.db.transaction() as tr:
            for i in range(10):
                if i == 5:
                    continue
                k = str(i).encode('utf-8')
                tr[k] = k
                values.append(k)
            tr.commit()
        with self.db.transaction() as tr:
            with tr.cursor() as c:
                c.seek(b'5', type_)
                keys = set()
                while True:
                    k = c.key()
                    keys.add(k)
                    self.assertEqual(len(k), c.keysize())
                    try:
                        c.next()
                    except NotFoundError:
                        break
                self.assertEqual(set(keys), set(values[index:]))

    def test_seek_ge(self):
        """Test cursor seek iteration with Seek.GE."""
        self.seek_common(Seek.GE, 5)

    def test_seek_le(self):
        """Test cursor seek iteration with Seek.LE."""
        self.seek_common(Seek.LE, 4)

    def test_seek_transaction(self):
        """Test cursor seek when called from transaction."""
        values = self.create_data('seek-tr')

        with self.db.transaction() as tr:
            # Test default
            with tr.cursor(seek_key=b'seek-tr-3') as c:
                keys = set()
                while True:
                    k, v = c.key(), c.val()
                    keys.add(k)
                    try:
                        c.next()
                    except NotFoundError:
                        break
                self.assertEqual(set(keys), set(sorted(values.keys())[3:]))

            # Test GE
            with tr.cursor(seek_key=b'seek-tr-31', seek_type=Seek.GE) as c:
                keys = set()
                while True:
                    k, v = c.key(), c.val()
                    keys.add(k)
                    try:
                        c.next()
                    except NotFoundError:
                        break
                self.assertEqual(set(keys), set(sorted(values.keys())[4:]))



if __name__ == '__main__':
    unittest.main()
