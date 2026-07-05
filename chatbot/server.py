#!/usr/bin/env python3
"""
server.py
---------
FastAPI server — Qt بتتكلم معه عبر HTTP

Endpoints:
  POST /chat    ← أرسل سؤال، استقبل جواب
  POST /reset   ← امسح تاريخ المحادثة
  GET  /health  ← تأكد إن الـ server شغال
"""

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import uvicorn

from chatbot import XV6Chatbot


# ─── FastAPI App ────────────────────────────────────────────────────────────
app = FastAPI(
    title="xv6 Educational Chatbot API",
    description="RAG chatbot for xv6 book and custom kernel code",
    version="1.0.0"
)

# CORS (لو بدك تفتحه من browser أو Qt WebEngine)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# Chatbot instance (يتحمل مرة وحدة عند بدء الـ server)
chatbot: XV6Chatbot | None = None


@app.on_event("startup")
async def startup():
    global chatbot
    print("[SERVER] Loading chatbot...")
    chatbot = XV6Chatbot()
    print("[SERVER] Chatbot ready!")


# ─── Models ─────────────────────────────────────────────────────────────────
class ChatRequest(BaseModel):
    message: str

class ChatResponse(BaseModel):
    answer: str
    status: str = "ok"


# ─── Endpoints ──────────────────────────────────────────────────────────────
@app.get("/health")
def health():
    return {"status": "ok", "model": "xv6-chatbot"}


@app.post("/chat", response_model=ChatResponse)
def chat(req: ChatRequest):
    if not req.message.strip():
        raise HTTPException(status_code=400, detail="Empty message")
    try:
        answer = chatbot.chat(req.message)
        return ChatResponse(answer=answer)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/reset")
def reset():
    msg = chatbot.reset()
    return {"status": "ok", "message": msg}


# ─── Run ─────────────────────────────────────────────────────────────────────
if __name__ == "__main__":
    uvicorn.run(
        "server:app",
        host="127.0.0.1",
        port=8000,
        reload=False
    )