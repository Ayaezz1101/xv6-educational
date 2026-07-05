#!/usr/bin/env python3
"""
ingest.py
---------
يقرأ:
  1. كتاب xv6 (PDF)
  2. كل ملفات .c و .h من المشروع

ويبني ChromaDB vector store محلي في مجلد ./chroma_db
"""

import os
import re
import sys
from pathlib import Path

import chromadb
from chromadb.utils import embedding_functions
import fitz  # PyMuPDF


# ─── إعدادات ───────────────────────────────────────────────────────────────
CHROMA_DIR   = "./chroma_db"
COLLECTION   = "xv6_knowledge"
PDF_PATH     = "./data/xv6-book.pdf"
CODE_ROOTS   = ["../kernel", "../user"]   # مسارات الكود بالنسبة لمجلد chatbot
EMBED_MODEL  = "all-MiniLM-L6-v2"        # صغير وسريع ومجاني
CHUNK_SIZE   = 800    # حروف لكل chunk
CHUNK_OVERLAP = 100


# ─── Embedding (محلي بدون API) ─────────────────────────────────────────────
ef = embedding_functions.SentenceTransformerEmbeddingFunction(
    model_name=EMBED_MODEL
)


# ─── ChromaDB ──────────────────────────────────────────────────────────────
client     = chromadb.PersistentClient(path=CHROMA_DIR)
# احذف القديم لو موجود عشان نبدأ نظيف
try:
    client.delete_collection(COLLECTION)
    print("[INFO] Deleted old collection")
except:
    pass
collection = client.create_collection(
    name=COLLECTION,
    embedding_function=ef,
    metadata={"hnsw:space": "cosine"}
)


# ─── Helper: chunk نص طويل ─────────────────────────────────────────────────
def chunk_text(text: str, source: str, chunk_size=CHUNK_SIZE, overlap=CHUNK_OVERLAP):
    chunks = []
    start  = 0
    idx    = 0
    text   = text.strip()
    while start < len(text):
        end   = min(start + chunk_size, len(text))
        chunk = text[start:end].strip()
        if chunk:
            chunks.append({
                "id":   f"{source}::chunk{idx}",
                "text": chunk,
                "meta": {"source": source, "chunk": idx}
            })
            idx += 1
        start += chunk_size - overlap
    return chunks


# ─── 1. استخراج PDF ────────────────────────────────────────────────────────
def ingest_pdf(pdf_path: str):
    print(f"\n[PDF] Reading {pdf_path} ...")
    doc    = fitz.open(pdf_path)
    chunks = []
    for page_num, page in enumerate(doc, start=1):
        text = page.get_text("text")
        if not text.strip():
            continue
        source = f"book:page{page_num}"
        chunks += chunk_text(text, source)
    print(f"[PDF] {len(doc)} pages → {len(chunks)} chunks")
    return chunks


# ─── 2. استخراج functions من C ─────────────────────────────────────────────
FUNC_PATTERN = re.compile(
    r"""
    (?:^|\n)                          # بداية السطر
    (?:static\s+|inline\s+)*         # optional modifiers
    [\w\s\*]+?                        # return type
    \s+(\w+)\s*                       # اسم الدالة
    \(([^)]*)\)\s*                    # parameters
    \{                                # بداية الـ body
    """,
    re.VERBOSE | re.MULTILINE
)

def extract_functions(code: str, filepath: str):
    """يستخرج كل function مع اسمها وبدايتها"""
    functions = []
    for match in FUNC_PATTERN.finditer(code):
        func_name = match.group(1)
        start     = match.start()
        # ابحث عن نهاية الدالة بعد الـ {
        brace_start = code.find('{', match.start())
        if brace_start == -1:
            continue
        depth = 0
        end   = brace_start
        for i in range(brace_start, min(brace_start + 5000, len(code))):
            if code[i] == '{':
                depth += 1
            elif code[i] == '}':
                depth -= 1
                if depth == 0:
                    end = i + 1
                    break
        func_body = code[start:end].strip()
        if len(func_body) > 20:
            functions.append({
                "name": func_name,
                "body": func_body,
                "file": filepath
            })
    return functions


def ingest_code(code_roots: list):
    print(f"\n[CODE] Scanning: {code_roots}")
    all_chunks = []
    total_files = 0
    total_funcs = 0

    for root in code_roots:
        root_path = Path(root)
        if not root_path.exists():
            print(f"[WARN] Path not found: {root} — skipping")
            continue
        for ext in ["*.c", "*.h"]:
            for fpath in sorted(root_path.rglob(ext)):
                try:
                    code = fpath.read_text(encoding="utf-8", errors="ignore")
                except:
                    continue

                total_files += 1
                rel = str(fpath)

                # chunk الملف كله (للسياق العام)
                file_chunks = chunk_text(
                    f"// File: {rel}\n\n{code}",
                    source=f"code:{rel}"
                )
                all_chunks += file_chunks

                # chunk كل function لوحدها (للبحث الدقيق)
                funcs = extract_functions(code, rel)
                total_funcs += len(funcs)
                for func in funcs:
                    func_text = (
                        f"// File: {func['file']}\n"
                        f"// Function: {func['name']}\n\n"
                        f"{func['body']}"
                    )
                    all_chunks += chunk_text(
                        func_text,
                        source=f"func:{func['file']}:{func['name']}"
                    )

    print(f"[CODE] {total_files} files, {total_funcs} functions → {len(all_chunks)} chunks")
    return all_chunks


# ─── 3. حط كل شي بـ ChromaDB ──────────────────────────────────────────────
def add_to_db(chunks: list, batch_size=100):
    print(f"\n[DB] Inserting {len(chunks)} chunks into ChromaDB...")
    for i in range(0, len(chunks), batch_size):
        batch = chunks[i:i+batch_size]
        collection.add(
            ids        = [c["id"]   for c in batch],
            documents  = [c["text"] for c in batch],
            metadatas  = [c["meta"] for c in batch],
        )
        print(f"[DB] {min(i+batch_size, len(chunks))}/{len(chunks)}", end="\r")
    print(f"\n[DB] Done! Total: {collection.count()} documents")


# ─── Main ───────────────────────────────────────────────────────────────────
if __name__ == "__main__":
    print("=" * 50)
    print("  xv6 RAG — Ingest Script")
    print("=" * 50)

    all_chunks = []

    # PDF
    if Path(PDF_PATH).exists():
        all_chunks += ingest_pdf(PDF_PATH)
    else:
        print(f"[WARN] PDF not found at {PDF_PATH}")

    # Code
    all_chunks += ingest_code(CODE_ROOTS)

    if not all_chunks:
        print("[ERR] No data found!")
        sys.exit(1)

    # Remove duplicate IDs
    seen = set()
    unique = []
    for c in all_chunks:
        if c["id"] not in seen:
            seen.add(c["id"])
            unique.append(c)

    add_to_db(unique)
    print("\n✅ Ingest complete! Run chatbot.py next.")