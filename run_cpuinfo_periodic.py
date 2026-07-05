#!/usr/bin/env python3
"""
Script to run cpuinfo command periodically in QEMU and collect the output
"""
import json
import sqlite3
import time
import uuid
import re
import subprocess
import sys
from pathlib import Path
from datetime import datetime

LOG_PATH = "qemu.log"
DB_PATH = "events.db"
SESSION_ID = str(uuid.uuid4())

def clean_payload(payload: str) -> str:
    return re.sub(r'[\x00-\x1f\x7f-\x9f]', '', payload)

def parse_cpu_info(line: str) -> dict | None:
    """Parse CPU info JSON from log line"""
    # Look for CPU {...} pattern - use balanced braces
    if 'CPU' not in line or '{' not in line:
        return None
    
    # Find the position of 'CPU'
    cpu_pos = line.find('CPU')
    if cpu_pos == -1:
        return None
    
    # Find the opening brace after CPU
    brace_start = line.find('{', cpu_pos)
    if brace_start == -1:
        return None
    
    # Match balanced braces
    depth = 0
    end = -1
    for i in range(brace_start, len(line)):
        if line[i] == '{':
            depth += 1
        elif line[i] == '}':
            depth -= 1
            if depth == 0:
                end = i
                break
    
    if end == -1:
        return None
    
    try:
        payload = line[brace_start:end+1]
        cleaned = clean_payload(payload)
        return json.loads(cleaned)
    except:
        return None

def parse_proc_stats(line: str) -> dict | None:
    """Parse PROC stats JSON from log line"""
    # Look for PROC {...} pattern - use balanced braces
    if 'PROC' not in line or '{' not in line:
        return None
    
    # Find the position of 'PROC'
    proc_pos = line.find('PROC')
    if proc_pos == -1:
        return None
    
    # Find the opening brace after PROC
    brace_start = line.find('{', proc_pos)
    if brace_start == -1:
        return None
    
    # Match balanced braces
    depth = 0
    end = -1
    for i in range(brace_start, len(line)):
        if line[i] == '{':
            depth += 1
        elif line[i] == '}':
            depth -= 1
            if depth == 0:
                end = i
                break
    
    if end == -1:
        return None
    
    try:
        payload = line[brace_start:end+1]
        cleaned = clean_payload(payload)
        return json.loads(cleaned)
    except:
        return None

def insert_cpu_info(cur: sqlite3.Cursor, event: dict) -> None:
    """Insert CPU info into database"""
    cur.execute("""
    INSERT INTO cpu_info
    (session_id, cpu, active, current_pid, current_state, last_pid, last_state, busy_percent, active_ticks)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    """, (
        SESSION_ID,
        event.get("cpu"),
        event.get("active"),
        event.get("current_pid"),
        event.get("current_state"),
        event.get("last_pid"),
        event.get("last_state"),
        event.get("busy_percent"),
        event.get("active_ticks")
    ))

def insert_proc_stats(cur: sqlite3.Cursor, event: dict) -> None:
    """Insert PROC stats into database"""
    cur.execute("""
    INSERT INTO proc_stats
    (session_id, total_created, total_exited,
     current_unused, current_used, current_sleeping, current_runnable, current_running, current_zombie,
     unique_unused, unique_used, unique_sleeping, unique_runnable, unique_running, unique_zombie)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    """, (
        SESSION_ID,
        event.get("total_created"),
        event.get("total_exited"),
        event.get("current", {}).get("UNUSED", 0),
        event.get("current", {}).get("USED", 0),
        event.get("current", {}).get("SLEEPING", 0),
        event.get("current", {}).get("RUNNABLE", 0),
        event.get("current", {}).get("RUNNING", 0),
        event.get("current", {}).get("ZOMBIE", 0),
        event.get("unique", {}).get("UNUSED", 0),
        event.get("unique", {}).get("USED", 0),
        event.get("unique", {}).get("SLEEPING", 0),
        event.get("unique", {}).get("RUNNABLE", 0),
        event.get("unique", {}).get("RUNNING", 0),
        event.get("unique", {}).get("ZOMBIE", 0)
    ))

def ensure_schema(cur: sqlite3.Cursor) -> None:
    """Create database schema if not exists"""
    cur.execute("""
    CREATE TABLE IF NOT EXISTS cpu_info(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id TEXT NOT NULL,
        cpu INTEGER,
        active INTEGER,
        current_pid INTEGER,
        current_state TEXT,
        last_pid INTEGER,
        last_state TEXT,
        busy_percent INTEGER,
        active_ticks INTEGER,
        timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
    )
    """)

    cur.execute("""
    CREATE TABLE IF NOT EXISTS proc_stats(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id TEXT NOT NULL,
        total_created INTEGER,
        total_exited INTEGER,
        current_unused INTEGER,
        current_used INTEGER,
        current_sleeping INTEGER,
        current_runnable INTEGER,
        current_running INTEGER,
        current_zombie INTEGER,
        unique_unused INTEGER,
        unique_used INTEGER,
        unique_sleeping INTEGER,
        unique_runnable INTEGER,
        unique_running INTEGER,
        unique_zombie INTEGER,
        timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
    )
    """)

    cur.execute("""
    CREATE INDEX IF NOT EXISTS idx_cpu_info_session_timestamp
    ON cpu_info(session_id, timestamp)
    """)

    cur.execute("""
    CREATE INDEX IF NOT EXISTS idx_proc_stats_session_timestamp
    ON proc_stats(session_id, timestamp)
    """)

def main() -> None:
    log_file = Path(LOG_PATH)
    if not log_file.exists():
        print(f"[ERR] Log file not found: {LOG_PATH}")
        return

    con = sqlite3.connect(DB_PATH, timeout=10.0)
    cur = con.cursor()
    ensure_schema(cur)
    con.commit()

    last_pos = 0
    print(f"[INFO] Started CPU Info periodic reader. Session: {SESSION_ID}")
    print(f"[INFO] Log: {LOG_PATH}")
    print(f"[INFO] DB : {DB_PATH}")
    print(f"[INFO] Running cpuinfo every 5 seconds...")

    try:
        while True:
            try:
                with open(LOG_PATH, "r", encoding="utf-8", errors="ignore") as f:
                    f.seek(last_pos)
                    lines = f.readlines()
                    last_pos = f.tell()

                    for line in lines:
                        # Try to parse CPU info
                        cpu_event = parse_cpu_info(line)
                        if cpu_event:
                            try:
                                insert_cpu_info(cur, cpu_event)
                                con.commit()
                                print(f"[OK] Saved CPU info for cpu={cpu_event.get('cpu')}")
                            except sqlite3.Error as e:
                                print(f"[ERR] SQLite failed: {e}")

                        # Try to parse PROC stats
                        proc_event = parse_proc_stats(line)
                        if proc_event:
                            try:
                                insert_proc_stats(cur, proc_event)
                                con.commit()
                                print(f"[OK] Saved PROC stats: created={proc_event.get('total_created')}")
                            except sqlite3.Error as e:
                                print(f"[ERR] SQLite failed: {e}")

            except IOError:
                pass
            
            time.sleep(5)  # Wait 5 seconds before checking again

    except KeyboardInterrupt:
        print("\n[INFO] Shutting down...")
        con.close()
        sys.exit(0)

if __name__ == "__main__":
    main()
