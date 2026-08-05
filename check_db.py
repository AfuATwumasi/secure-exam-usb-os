import sqlite3

conn = sqlite3.connect("backend/exam.db")
cursor = conn.cursor()

cursor.execute("SELECT COUNT(*) FROM iso_builds")
print(cursor.fetchone())

conn.close()