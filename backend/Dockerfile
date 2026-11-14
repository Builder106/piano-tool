FROM python:3.12-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends ffmpeg \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY requirements.txt .
COPY scripts/install_basic_pitch.sh scripts/install_basic_pitch.sh
RUN pip install --no-cache-dir -r requirements.txt \
    && bash scripts/install_basic_pitch.sh

COPY app app
COPY scripts/start.sh scripts/start.sh

ENV PIANO_TOOL_DB=/data/jobs.sqlite3 \
    PIANO_TOOL_SPOOL=/data/jobs \
    PORT=8080

EXPOSE 8080

CMD ["bash", "scripts/start.sh"]
