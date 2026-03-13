#!/usr/bin/env python3
import re
import sqlite3
import time

LOG_PATH = "/home/ruba/xv6-test/qemu.log"
DB_PATH = "/home/ruba/xv6-test/events.db"

pat = re.compile(
    r"seq=(\d+)\s+tick=(\d+)\s+cpu=(\d+)\s+pid=(\d+)\s+name=([^\s]+)\s+state=(\d+)"
)

def main():
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
      state INTEGER
    )
    """)
    con.commit()

    with open(LOG_PATH, "r", encoding="utf-8", errors="ignore") as f:
        f.seek(0, 0)  # ابدأ من أول الملف

        while True:
            line = f.readline()
            if not line:
                time.sleep(0.1)
                continue

            m = pat.search(line)
            if not m:
                continue

            seq, tick, cpu, pid, name, state = m.groups()

            cur.execute(
                "INSERT OR IGNORE INTO events(seq,tick,cpu,pid,name,state) VALUES (?,?,?,?,?,?)",
                (int(seq), int(tick), int(cpu), int(pid), name, int(state))
            )
            con.commit()

if __name__ == "__main__":
    main()