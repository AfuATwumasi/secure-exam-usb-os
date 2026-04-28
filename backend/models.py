from dataclasses import dataclass


@dataclass
class User:
    id: int | None = None
    name: str = ""
    email: str = ""
