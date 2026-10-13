import os

from fastapi import FastAPI

app = FastAPI(title="sample-service")
VERSION = os.getenv("APP_VERSION", "dev")


@app.get("/health")
def health():
    return {"status": "ok", "version": VERSION}


@app.get("/api/greeting/{name}")
def greeting(name: str):
    return {"message": f"Hello, {name}!"}
