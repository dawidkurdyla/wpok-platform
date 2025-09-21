##
# WPOK FFmpeg worker
#
# This Dockerfile builds a container image that contains ffmpeg and the
# HyperFlow job executor.  It is intended to be used as a worker image
# within the WPOK platform. The image installs ffmpeg on top of a slim
# Node.js base, installs the HyperFlow job executor globally via npm

# ---- builder ----
FROM node:20-bookworm-slim AS builder
RUN apt-get update && apt-get install -y --no-install-recommends git ca-certificates && rm -rf /var/lib/apt/lists/*
RUN npm install -g --omit=dev --no-audit --no-fund --prefix /opt/hflow \
      git+https://github.com/dawidkurdyla/serverless-task-executor.git#feature/s3-compatible-file-management-support \
 && npm cache clean --force

# ---- runtime ----
FROM node:20-bookworm-slim
ENV NODE_ENV=production
WORKDIR /work_dir

RUN apt-get update && apt-get install -y --no-install-recommends \
      ffmpeg dumb-init ca-certificates \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /opt/hflow /opt/hflow
ENV PATH="/opt/hflow/bin:${PATH}"

ENTRYPOINT ["/usr/bin/dumb-init","--"]
CMD ["hflow-job-listener.js"]
