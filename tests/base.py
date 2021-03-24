import os
import tempfile

from tkvdb import Tkvdb


class TestMixin:
    """Basic mixin for tests."""
    def setUp(self):
        """Create Tkvdb instance in temporary file."""
        self.dbfile = tempfile.NamedTemporaryFile(delete=False)
        self.path = self.dbfile.name
        self.db = Tkvdb(self.path)

    def tearDown(self):
        """Close database and remove tempfile."""
        self.db.close()
        self.dbfile.close()
        os.unlink(self.path)
