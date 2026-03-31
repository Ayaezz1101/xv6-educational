#!/usr/bin/env python3
import json
import sqlite3
import time
import uuid
<<<<<<< Updated upstream

LOG_PATH = "/mnt/c/Users/ASUS/rubaa/qemu.log"
DB_PATH = "/mnt/c/Users/ASUS/rubaa/events.db"

SESSION_ID = str(uuid.uuid4())

BATCH_SIZE = 50
SLEEP_WHEN_IDLE = 0.1
DB_RETRY_COUNT = 5
DB_RETRY_SLEEP = 0.2


def ensure_schema(cur: sqlite3.Cursor) -> None:
    cur.execute("""
    CREATE TABLE IF NOT EXISTS events(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id TEXT NOT NULL,
        seq INTEGER NOT NULL,
        tick INTEGER NOT NULL,
        cpu INTEGER NOT NULL,
        pid INTEGER NOT NULL,
        name TEXT NOT NULL,
        state INTEGER NOT NULL,
        type TEXT NOT NULL,
        UNIQUE(session_id, seq)
    )
    """)


def extract_event_payloads(line: str):
    """
    ترجع كل substrings من الشكل:
    EV { ... }
    حتى لو كان قبلها junk أو بعدها junk.
    """
    payloads = []
    i = 0

    while True:
        start = line.find("EV {", i)
        if start == -1:
            break

        brace_start = line.find("{", start)
        if brace_start == -1:
            break

        depth = 0
        end = -1
        for j in range(brace_start, len(line)):
            if line[j] == "{":
                depth += 1
=======
import re

LOG_PATH = "/mnt/c/Users/ASUS/rubaa/qemu.log"
DB_PATH = "/mnt/c/Users/ASUS/rubaa/events.db"
SESSION_ID = str(uuid.uuid4())
BATCH_SIZE = 1 
SLEEP_WHEN_IDLE = 0.1

def clean_payload(payload):
    # إزالة أي أحرف تحكم غير مرئية قد تسبب فشل الـ JSON
    return re.sub(r'[\x00-\x1f\x7f-\x9f]', '', payload)

def ensure_schema(cur):
    cur.execute("""
    CREATE TABLE IF NOT EXISTS events(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id TEXT, seq INTEGER UNIQUE, tick INTEGER,
        cpu INTEGER, pid INTEGER, name TEXT, state INTEGER, type TEXT
    )""")
    cur.execute("""
    CREATE TABLE IF NOT EXISTS fs_events(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id TEXT, seq INTEGER, tick INTEGER, type INTEGER,
        pid INTEGER, inum INTEGER, blockno INTEGER, size INTEGER, name TEXT
    )""")

def extract_event_payloads(line):
    payloads = []
    i = 0
    while True:
        start = line.find("EV {", i)
        if start == -1: break
        brace_start = line.find("{", start)
        depth, end = 0, -1
        for j in range(brace_start, len(line)):
            if line[j] == "{": depth += 1
>>>>>>> Stashed changes
            elif line[j] == "}":
                depth -= 1
                if depth == 0:
                    end = j
                    break
<<<<<<< Updated upstream

        if end != -1:
            payloads.append(line[brace_start:end + 1])
            i = end + 1
        else:
            # ما لقينا closing brace، نوقف هون
            break

    return payloads


def parse_event_payload(payload: str):
    try:
        obj = json.loads(payload)
    except json.JSONDecodeError as e:
        return None, f"bad_json: {e}"

    if not isinstance(obj, dict):
        return None, f"bad_type: {type(obj).__name__}"

    needed = ("seq", "tick", "cpu", "pid", "name", "state", "type")
    missing = [k for k in needed if k not in obj]
    if missing:
        return None, f"missing_keys: {missing}"

    try:
        event = {
            "seq": int(obj["seq"]),
            "tick": int(obj["tick"]),
            "cpu": int(obj["cpu"]),
            "pid": int(obj["pid"]),
            "name": str(obj["name"]),
            "state": int(obj["state"]),
            "type": str(obj["type"]),
        }
    except (ValueError, TypeError) as e:
        return None, f"bad_fields: {e}"

    return event, None


def insert_event(cur: sqlite3.Cursor, event: dict) -> None:
    cur.execute(
        """
        INSERT OR IGNORE INTO events
        (session_id, seq, tick, cpu, pid, name, state, type)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        """,
        (
            SESSION_ID,
            event["seq"],
            event["tick"],
            event["cpu"],
            event["pid"],
            event["name"],
            event["state"],
            event["type"],
        ),
    )


def commit_with_retry(con: sqlite3.Connection) -> bool:
    for attempt in range(DB_RETRY_COUNT):
        try:
            con.commit()
            return True
        except sqlite3.OperationalError as e:
            if "locked" in str(e).lower():
                print(f"[DB WAIT] database locked, retry {attempt + 1}/{DB_RETRY_COUNT}")
                time.sleep(DB_RETRY_SLEEP)
                continue
            print(f"[DB ERROR] commit failed: {e}")
            return False
        except sqlite3.DatabaseError as e:
            print(f"[DB ERROR] commit failed: {e}")
            return False

    print("[DB ERROR] commit failed after retries")
    return False


def main() -> None:
    con = sqlite3.connect(DB_PATH, timeout=5.0)
    cur = con.cursor()

    ensure_schema(cur)

    cur.execute("PRAGMA journal_mode=WAL;")
    cur.execute("PRAGMA synchronous=NORMAL;")
    cur.execute("PRAGMA busy_timeout = 5000;")
    con.commit()

    inserted = 0
    bad = 0
    pending = ""
    pending_writes = 0

    print(f"[INFO] session_id={SESSION_ID}")

    with open(LOG_PATH, "r", encoding="utf-8", errors="ignore") as f:
        f.seek(0, 0)

        while True:
            chunk = f.read(4096)

            if not chunk:
                if pending_writes > 0:
                    if commit_with_retry(con):
                        pending_writes = 0
                time.sleep(SLEEP_WHEN_IDLE)
                continue

            pending += chunk

            while "\n" in pending:
                line, pending = pending.split("\n", 1)
                line = line.rstrip("\r\n")

                if not line:
                    continue

                payloads = extract_event_payloads(line)

                if not payloads:
                    continue

                for payload in payloads:
                    event, err = parse_event_payload(payload)

                    if err is not None:
                        bad += 1
                        print(f"[BAD {bad}] {err} :: {repr(payload)}")
                        continue

                    try:
                        insert_event(cur, event)
                    except sqlite3.OperationalError as e:
                        if "locked" in str(e).lower():
                            print(f"[DB WAIT] insert locked for seq={event['seq']}")
                            if not commit_with_retry(con):
                                continue
                            try:
                                insert_event(cur, event)
                            except sqlite3.DatabaseError as e2:
                                print(f"[DB ERROR] insert failed after retry :: {event} :: {e2}")
                                continue
                        else:
                            print(f"[DB ERROR] insert failed :: {event} :: {e}")
                            continue
                    except sqlite3.DatabaseError as e:
                        print(f"[DB ERROR] insert failed :: {event} :: {e}")
                        continue

                    if cur.rowcount == 1:
                        inserted += 1
                        pending_writes += 1
                        print(f"[OK] inserted seq={event['seq']} total={inserted}")
                    else:
                        print(f"[SKIP] duplicate seq={event['seq']}")

                    if pending_writes >= BATCH_SIZE:
                        if commit_with_retry(con):
                            pending_writes = 0


if __name__ == "__main__":
    main()

=======
        if end != -1:
            payloads.append(line[brace_start:end + 1])
            i = end + 1
        else: break
    return payloads

def main():
    con = sqlite3.connect(DB_PATH, timeout=10.0)
    cur = con.cursor()
    ensure_schema(cur)
    con.commit()

    pending = ""
    print(f"[INFO] Started Clean Ingestor. Session: {SESSION_ID}")

    with open(LOG_PATH, "r", encoding="utf-8", errors="ignore") as f:
        while True:
            chunk = f.read(4096)
            if not chunk:
                time.sleep(SLEEP_WHEN_IDLE)
                continue
            pending += chunk
            while "\n" in pending:
                line, pending = pending.split("\n", 1)
                for payload in extract_event_payloads(line):
                    cleaned = clean_payload(payload)
                    try:
                        event = json.loads(cleaned)
                        if event.get("type") == "FS":
                            cur.execute("INSERT INTO fs_events (session_id, seq, tick, type, pid, inum, blockno, size, name) VALUES (?,?,?,?,?,?,?,?,?)",
                                (SESSION_ID, event["seq"], event["tick"], event.get("fs_type", 0), event["pid"], event.get("inum", 0), event.get("block", 0), event.get("size", 0), event.get("name", "")))
                        else:
                            cur.execute("INSERT OR IGNORE INTO events (session_id, seq, tick, cpu, pid, name, state, type) VALUES (?,?,?,?,?,?,?,?)",
                                (SESSION_ID, event["seq"], event["tick"], event.get("cpu", 0), event["pid"], event.get("name", "unknown"), event.get("state", 0), event["type"]))
                        con.commit()
                        print(f"[OK] Saved seq={event['seq']}")
                    except Exception as e:
                        print(f"[ERR] {e}")

if __name__ == "__main__":
    main()
>>>>>>> Stashed changes
