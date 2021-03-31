import unittest
import tempfile
import os

from tkvdb import Tkvdb


class TestDB(unittest.TestCase):
    """Tests for db handling operations."""
    def setUp(self):
        """Create temporary file for db."""
        self.dbfile = tempfile.NamedTemporaryFile(delete=False)
        self.path = self.dbfile.name

    def tearDown(self):
        """Remove tempfile."""
        self.dbfile.close()
        os.unlink(self.path)

    def open_db(self):
        """Create Tkvdb instance in temporary file."""
        self.db = Tkvdb(self.path)

    def close_db(self):
        """Close database and remove tempfile."""
        self.db.close()

    def test_open(self):
        """Test if database os opened correctly."""
        self.open_db()
        self.assertTrue(self.db.is_opened)
        self.assertEqual(self.db.path, self.path)

    def test_close(self):
        """Test if database is closed properly."""
        self.open_db()
        self.close_db()
        self.assertFalse(self.db.is_opened)

    def test_context_manager(self):
        """Test context manager with statement."""
        with Tkvdb(self.path) as db:
            self.assertTrue(db.is_opened)
            self.assertEqual(db.path, self.path)
        # Not really a good test for closing


if __name__ == '__main__':
    unittest.main()
