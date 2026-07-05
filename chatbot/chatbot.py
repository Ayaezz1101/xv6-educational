#!/usr/bin/env python3
"""
chatbot.py - RAG chatbot for xv6 educational project.
"""

import os
import sys
from pathlib import Path

import chromadb
from chromadb.utils import embedding_functions
from openai import OpenAI

# ─── Configuration ──────────────────────────────────────────────────────────
CHROMA_DIR    = "./chroma_db"
COLLECTION    = "xv6_knowledge"
EMBED_MODEL   = "all-MiniLM-L6-v2"
OPENROUTER_KEY = os.environ.get("OPENROUTER_API_KEY", "")
LLM_MODEL     = "openai/gpt-4o-mini"
TOP_K         = 6   
MAX_TOKENS    = 1024

SYSTEM_PROMPT = """You are an xv6 educational expert.
- Your primary goal is to help students understand xv6 concepts, kernel code, and system calls.
- If a question is related to xv6 (even if simple like 'what is scheduling?'), answer it using both the provided context AND your internal knowledge.
- If you find no relevant context, still answer the question based on your general knowledge about xv6 and operating systems, but mention that you are answering from general knowledge.
- Keep your answers concise, technical, and helpful.
- If the question is completely irrelevant to operating systems, then politely say: "أنا متخصص فقط في نظام التشغيل xv6."
"""
# ─── Database & Retrieval ──────────────────────────────────────────────────
def load_db():
    if not Path(CHROMA_DIR).exists():
        print("[ERR] chroma_db not found!")
        sys.exit(1)
    ef = embedding_functions.SentenceTransformerEmbeddingFunction(model_name=EMBED_MODEL)
    client = chromadb.PersistentClient(path=CHROMA_DIR)
    col    = client.get_collection(name=COLLECTION, embedding_function=ef)
    return col

def retrieve(collection, query: str, top_k=TOP_K) -> str:
    # 1. أولاً نحصل على النتائج
    results = collection.query(query_texts=[query], n_results=top_k, include=["documents", "metadatas", "distances"])
    
    # 2. الآن نطبع النتائج (بعد التعريف)
    print(f"[DEBUG] Results found: {len(results['documents'][0])}")
    
    docs = results["documents"][0]
    metas = results["metadatas"][0]
    dists = results["distances"][0]
    
    context_parts = []
    for doc, meta, dist in zip(docs, metas, dists):
        if dist > 1.2: continue 
        source = meta.get("source", "unknown")
        context_parts.append(f"[Source: {source}]\n{doc}")
    return "\n\n---\n\n".join(context_parts)

def ask_llm(client, messages: list) -> str:
    response = client.chat.completions.create(
        model=LLM_MODEL,
        messages=messages,
        max_tokens=MAX_TOKENS,
        temperature=0.0,
        extra_headers={"HTTP-Referer": "https://github.com/ruba-alsawaf/xv6-educational", "X-Title": "xv6 Chatbot"}
    )
    # --- تشريح الرد ---
    answer = response.choices[0].message.content
    print(f"[DEBUG] Raw Answer from LLM: '{answer}'") 
    return answer

# ─── Chatbot Class ─────────────────────────────────────────────────────────
class XV6Chatbot:
    def __init__(self):
        self.collection = load_db()
        self.llm_client = OpenAI(base_url="https://openrouter.ai/api/v1", api_key=OPENROUTER_KEY)
        self.history = []

    def chat(self, user_message: str) -> str:
        context = retrieve(self.collection, user_message)
        
        messages = [{"role": "system", "content": SYSTEM_PROMPT}]
        
        if context:
            messages.append({"role": "system", "content": f"Context available:\n{context}"})
        else:
            messages.append({"role": "system", "content": "No context found. Refuse to answer non-xv6 questions."})

        messages += self.history[-6:]
        messages.append({"role": "user", "content": user_message})

        answer = ask_llm(self.llm_client, messages)
        
        self.history.append({"role": "user", "content": user_message})
        self.history.append({"role": "assistant", "content": answer})
        return answer

    def reset(self):
        self.history = []
        return "Conversation reset."