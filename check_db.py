from backend.config import engine
from backend.models import iso_builds
from sqlalchemy import select

with engine.connect() as conn:
    row = conn.execute(
        select(
            iso_builds.c.build_id,
            iso_builds.c.iso_filename
        ).where(
            iso_builds.c.status == "Completed"
        )
    ).fetchone()

print(row)