from sqlalchemy import Table, Column, Integer, String, MetaData


metadata = MetaData()


users = Table(
    "users", metadata,
    Column("id", Integer, primary_key=True),
    Column("username", String),
    Column("password", String)
)

questions = Table(
    "questions", metadata,
    Column("id", Integer, primary_key=True),
    Column("question", String)
)
