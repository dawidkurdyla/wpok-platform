##
## Dockerfile for the WPOK BWA worker
##
## This image bundles the Hyperflow task executor together with the
## Burrows‑Wheeler Aligner (BWA) for running sequence alignment tasks.
## It follows the best practices from the WPOK worker guidelines: a
## multi‑stage build that clones the executor from the feature branch with
## S3 support, installs dependencies with npm, and uses dumb‑init as
## the entrypoint to ensure proper signal handling.  In the runtime
## stage the BWA package is installed from the Debian repositories.  A
## simple wrapper script (bwa_align.sh) is copied into the image to
## facilitate running BWA through a Task spec if desired.
##

#############################
# Builder stage             #
#############################
FROM node:20-bookworm-slim AS builder

# Install git so we can clone the executor repository.  We also
# install ca‑certificates to allow TLS when cloning from GitHub.
RUN apt-get update && \
    apt-get install -y --no-install-recommends git ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Clone only the desired branch of the executor.  Pinning to the
# feature/s3-compatible-file-management-support branch avoids AMQP
# frame_max issues (frame_max=4096 < 8192) as noted in the WPOK
# guidelines.  For maximum reproducibility you can pin to a specific
# commit by replacing the branch name with `<commit_sha>`.
WORKDIR /src
RUN git clone --depth 1 -b feature/s3-compatible-file-management-support \
    https://github.com/dawidkurdyla/serverless-task-executor.git .

# Install production dependencies and avoid dev packages.  This step
# generates a node_modules tree under /src which will be copied into
# the runtime image.  We use npm ci instead of npm install for
# reproducibility.
RUN npm ci --omit=dev

#############################
# Runtime stage             #
#############################
FROM node:20-bookworm-slim

# Set the NODE_ENV to production so that any Node.js packages behave
# appropriately (e.g. disable dev logging).  Define the work
# directory for Hyperflow which matches the paths used by the WPOK
# platform.
ENV NODE_ENV=production \
    HF_VAR_WORK_DIR=/work_dir \
    HF_VAR_INPUT_DIR=/work_dir/input \
    HF_VAR_OUTPUT_DIR=/work_dir/output

WORKDIR /work_dir

# Install system packages:
#  - dumb-init: minimal init system handling SIGTERM/SIGINT properly
#  - ca-certificates: TLS certificate bundle for secure connections
#  - bwa: the Burrows‑Wheeler Aligner used for sequence alignment
#  - samtools: optional but useful for converting SAM to BAM
#  - any other dependencies can be added here
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      dumb-init \
      ca-certificates \
      bwa \
      samtools && \
    rm -rf /var/lib/apt/lists/*

COPY --from=builder /src /opt/hflow/pkg

RUN cd /opt/hflow/pkg && npm link --omit=dev

COPY bwa_align.sh /usr/local/bin/bwa_align.sh

RUN chmod +x /usr/local/bin/bwa_align.sh

ENV PATH="/usr/local/bin:${PATH}"

ENTRYPOINT ["/usr/bin/dumb-init", "--"]
CMD ["hflow-job-listener.js"]