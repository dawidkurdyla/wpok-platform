# ---- builder ----
FROM node:20-bookworm-slim AS builder
RUN apt-get update && apt-get install -y --no-install-recommends git ca-certificates && rm -rf /var/lib/apt/lists/*
WORKDIR /src
RUN git clone --depth 1 -b feature/s3-compatible-file-management-support \
  https://github.com/dawidkurdyla/serverless-task-executor.git .
RUN npm ci --omit=dev

FROM node:20-bookworm-slim
ENV NODE_ENV=production
WORKDIR /work_dir

RUN apt-get update && apt-get install -y --no-install-recommends \
      python3 python3-venv ca-certificates ffmpeg dumb-init \
  && rm -rf /var/lib/apt/lists/*

ENV VENV_PATH=/opt/venv
RUN python3 -m venv "$VENV_PATH"
ENV PATH="$VENV_PATH/bin:/usr/local/bin:$PATH"

RUN pip install --no-cache-dir --upgrade pip setuptools wheel \
 && pip install --no-cache-dir faster-whisper whisper-ctranslate2

COPY --from=builder /src /opt/hflow/pkg
RUN cd /opt/hflow/pkg && npm link --omit=dev

ENV OMP_NUM_THREADS=2

ENTRYPOINT ["/usr/bin/dumb-init","--"]
CMD ["hflow-job-listener.js"]
