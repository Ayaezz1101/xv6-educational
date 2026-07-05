#!/usr/bin/env python3
"""
Cross-Platform Pipeline Ingestor to capture memcat traces from QEMU 
Supported Platforms: macOS, Windows, Linux
"""
import re
import sqlite3
import time
import uuid
import sys
import os
from pathlib import Path

LOG_PATH = "qemu.log"
SESSION_ID = str(uuid.uuid4())

# 💡 تحديد مسار الـ AppData المشترك ديناميكياً لكل أنظمة التشغيل ليتطابق مع الـ C++ المحسن
if sys.platform == "darwin":
    base_dir = Path.home() / "Library" / "Application Support" / "xv6ui"
elif sys.platform == "win32":
    base_dir = Path(os.getenv("APPDATA", ".")) / "xv6ui"
else:
    base_dir = Path.home() / ".local" / "share" / "xv6ui"

base_dir.mkdir(parents=True, exist_ok=True)
DB_PATH = str(base_dir / "events.db")

# 💡 تحديث الـ Regex ليتوافق حرفياً مع السجلات الفعلية المخزنة في قاعدة بياناتكِ
MEMCAT_RE = re.compile(
    r"seq=(?P<seq>\d+)\s+tick=(?P<tick>\d+)\s+cpu=(?P<cpu>-?\d+)\s+pid=(?P<pid>-?\d+)"
    r"\s+type=(?P<type>\S+)\s+src=(?P<src>\S+)\s+(?:name=(?P<name>\S+)\s+)?"
    r"old=(?P<old>\d+)\s+new=(?P<new>\d+)\s+pa=(?P<pa>\d+)\s+va=(?P<va>\d+)"
)

def parse_int(value: str) -> int:
    try:
        return int(value, 0)
    except (ValueError, TypeError):
        return 0

def parse_mem_event(line: str) -> dict | None:
    # تنظيف السطر من محارف الـ الـ # القديمة إن وجدت
    clean_line = line.replace('#', '').strip()
    m = MEMCAT_RE.search(clean_line)
    if not m:
        # محاولة فحص أخرى مرنة في حال كانت العناوين مفصولة بـ طابعات مختلفة
        fields = clean_line.split()
        if len(fields) >= 10 and "seq=" in clean_line:
            try:
                d = {}
                for f in fields:
                    if '=' in f:
                        k, v = f.split('=', 1)
                        d[k] = v
                return {
                    "seq": int(d.get("seq", 0)),
                    "tick": int(d.get("tick", 0)),
                    "cpu": int(d.get("cpu", 0)),
                    "pid": int(d.get("pid", 0)),
                    "type": d.get("type", "UNKNOWN"),
                    "src": d.get("src", "UNKNOWN"),
                    "va": parse_int(d.get("va", "0")),
                    "pa": parse_int(d.get("pa", "0")),
                    "perm": "rwx",
                    "kind": "page",
                    "name": d.get("name", "memcat"),
                    "old": parse_int(d.get("old", "0")),
                    "new": parse_int(d.get("new", "0")),
                }
            except Exception:
                return None
        return None

    return {
        "seq": int(m.group("seq")),
        "tick": int(m.group("tick")),
        "cpu": int(m.group("cpu")),
        "pid": int(m.group("pid")),
        "type": m.group("type"),
        "src": m.group("src"),
        "va": parse_int(m.group("va")),
        "pa": parse_int(m.group("pa")),
        "perm": "rwx",
        "kind": "page",
        "name": m.group("name") if m.group("name") else "memcat",
        "old": parse_int(m.group("old")),
        "new": parse_int(m.group("new")),
    }

def insert_mem_event(cur: sqlite3.Cursor, event: dict) -> None:
    cur.execute(
        """
        INSERT INTO mem_events
        (session_id, seq, tick, cpu, pid, type, src, va, pa, perm, kind, name, old, new)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """,
        (
            SESSION_ID, event["seq"], event["tick"], event["cpu"], event["pid"],
            event["type"], event["src"], event["va"], event["pa"],
            event["perm"], event["kind"], event["name"], event["old"], event["new"]
        ),
    )

def ensure_schema(cur: sqlite3.Cursor) -> None:
    cur.execute("""
        CREATE TABLE IF NOT EXISTS mem_events(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            session_id TEXT NOT NULL,
            seq INTEGER, tick INTEGER, cpu INTEGER, pid INTEGER,
            type TEXT, src TEXT, va INTEGER, pa INTEGER, perm TEXT,
            kind TEXT, name TEXT, old INTEGER, new INTEGER,
            timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
        )
    """)
    cur.execute("CREATE INDEX IF NOT EXISTS idx_mem_events_session_timestamp ON mem_events(session_id, timestamp)")

def wait_for_log_file(path: Path) -> None:
    while not path.exists():
        print(f"[WAIT] Waiting for {path} to appear... Make sure xv6/QEMU is running and writing logs.")
        time.sleep(1)

def main() -> None:
    log_file = Path(LOG_PATH)
    print(f"[INFO] Cross-Platform Memcat Pipeline starting. Platform={sys.platform} | Session={SESSION_ID}")
    print(f"[INFO] Targeted Pipeline Shared DB: {DB_PATH}")

    wait_for_log_file(log_file)

    con = sqlite3.connect(DB_PATH, timeout=10.0)
    cur = con.cursor()
    ensure_schema(cur)
    
    cur.execute("PRAGMA journal_mode=WAL;")
    con.commit()

    last_pos = 0
    print("[INFO] Pipeline initialized. Monitoring system traces...")

    try:
        while True:
            try:
                with open(LOG_PATH, "r", encoding="utf-8", errors="ignore") as f:
                    f.seek(last_pos)
                    lines = f.readlines()
                    last_pos = f.tell()

                    for line in lines:
                        mem_event = parse_mem_event(line)
                        if mem_event:
                            try:
                                insert_mem_event(cur, mem_event)
                                con.commit()
                                print(f"[PIPELINE-OK] Ingested log seq={mem_event['seq']} | PID={mem_event['pid']} | Event={mem_event['type']} | PA={hex(mem_event['pa'])}")
                            except sqlite3.Error as e:
                                print(f"[ERR] SQLite Transaction Failure: {e}")
            except IOError:
                pass

            time.sleep(1)
    except KeyboardInterrupt:
        print("\n[INFO] Cross-Platform Pipeline closed.")
        con.close()
        sys.exit(0)

if __name__ == "__main__":
    main()