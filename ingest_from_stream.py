import json
import sqlite3

LOG_PATH = "/home/ruba/xv6-test/qemu.log"
DB_PATH = "/home/ruba/xv6-test/events.db"

con = sqlite3.connect(DB_PATH)
cur = con.cursor()

cur.execute("""
CREATE TABLE IF NOT EXISTS events(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  seq INTEGER UNIQUE,
  tick INTEGER,
  cpu INTEGER,
  pid INTEGER,
  name TEXT,
  state INTEGER,
  type TEXT
)
""")
con.commit()

with open(LOG_PATH, "r", encoding="utf-8", errors="ignore") as f:
    for line in f:
        if not line.startswith("EV "):
            continue
        try:
            obj = json.loads(line[3:])
        except Exception:
            continue

        cur.execute(
            "INSERT OR IGNORE INTO events(seq,tick,cpu,pid,name,state,type) VALUES (?,?,?,?,?,?,?)",
            (
                obj["seq"],
                obj["tick"],
                obj["cpu"],
                obj["pid"],
                obj["name"],
                obj["state"],
                obj["type"],
            )
        )

con.commit()
con.close()