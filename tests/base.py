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

    def create_data(self, prefix='prefix', num=10):
        """Insert range of k-v pairs to db for testing."""
        values = {}
        with self.db.transaction() as tr:
            for i in range(num):
                key = '{}-{}'.format(prefix, i).encode('utf-8')
                value = '{}-val-{}'.format(prefix, i).encode('utf-8')
                tr[key] = values[key] = value
            tr.commit()
        return values

