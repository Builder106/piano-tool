from __future__ import annotations

import os
import time
import uuid

from app.jobs import JobStore


def main() -> None:
    store = JobStore(start_workers=False)
    worker_id = f"worker-{uuid.uuid4()}"
    store.recover()
    while True:
        if not store.run_worker_once(worker_id):
            time.sleep(float(os.getenv("PIANO_TOOL_WORKER_POLL_SECONDS", "1")))


if __name__ == "__main__":
    main()
