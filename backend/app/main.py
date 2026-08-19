from fastapi import FastAPI

app = FastAPI(title="Piano-Tool Ingestion Service")


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}
