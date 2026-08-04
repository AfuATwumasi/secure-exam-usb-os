import unittest

from sqlalchemy import create_engine
from werkzeug.security import check_password_hash

from backend.auth_setup import ensure_default_admin
from backend.models import metadata


class DefaultAdminBootstrapTests(unittest.TestCase):
    def setUp(self):
        self.engine = create_engine("sqlite:///:memory:")
        metadata.create_all(self.engine)

    def test_creates_a_real_admin_account_and_allows_login(self):
        row = ensure_default_admin(self.engine)

        self.assertEqual(row.username, "admin")
        self.assertEqual(row.email, "admin@secureexams.local")
        self.assertNotEqual(row.password_hash, "REPLACE_WITH_A_REAL_PASSWORD_HASH")
        self.assertTrue(check_password_hash(row.password_hash, "Admin@1234"))

        repeated = ensure_default_admin(self.engine)
        self.assertEqual(repeated.admin_id, row.admin_id)


if __name__ == "__main__":
    unittest.main()
