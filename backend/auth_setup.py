from __future__ import annotations

from sqlalchemy import select
from sqlalchemy.engine import Engine
from werkzeug.security import generate_password_hash

from backend.models import admins


DEFAULT_ADMIN_USERNAME = "admin"
DEFAULT_ADMIN_EMAIL = "admin@secureexams.local"
DEFAULT_ADMIN_PASSWORD = "Admin@1234"


def ensure_default_admin(engine: Engine):
    with engine.begin() as conn:
        existing = conn.execute(
            select(admins).where((admins.c.username == DEFAULT_ADMIN_USERNAME) | (admins.c.email == DEFAULT_ADMIN_EMAIL))
        ).fetchone()

        if existing is not None:
            conn.execute(
                admins.update()
                .where(admins.c.admin_id == existing.admin_id)
                .values(
                    username=DEFAULT_ADMIN_USERNAME,
                    email=DEFAULT_ADMIN_EMAIL,
                    password_hash=generate_password_hash(DEFAULT_ADMIN_PASSWORD),
                    role="Super Admin",
                )
            )
            return conn.execute(select(admins).where(admins.c.admin_id == existing.admin_id)).fetchone()

        password_hash = generate_password_hash(DEFAULT_ADMIN_PASSWORD)
        result = conn.execute(
            admins.insert().values(
                username=DEFAULT_ADMIN_USERNAME,
                email=DEFAULT_ADMIN_EMAIL,
                password_hash=password_hash,
                role="Super Admin",
            )
        )
        inserted_id = result.inserted_primary_key[0]
        return conn.execute(select(admins).where(admins.c.admin_id == inserted_id)).fetchone()
