#!/usr/bin/env bash

# Simple wrapper for running BWA MEM on a single FASTQ file.  This
# script accepts three arguments: the path to the reference FASTA,
# the input FASTQ file, and the desired output SAM file.  It will
# index the reference if necessary and then run `bwa mem` using all
# available CPU cores.  If an environment variable named THREADS is
# defined it will use that many threads instead.  BWA writes the
# alignments to standard output; here we redirect them to the output
# file.  You can modify this script to change the alignment mode or
# convert SAM to BAM using samtools.

set -euo pipefail

if [[ $# -ne 3 ]]; then
  echo "Usage: $(basename "$0") <reference.fasta> <reads.fastq> <output.sam>" >&2
  exit 1
fi

REFERENCE="$1"
READS="$2"
OUTPUT="$3"

# Determine number of threads.  Use THREADS env var if defined,
# otherwise use all available processing cores.
THREADS="${THREADS:-$(nproc)}"

echo "[bwa_align.sh] Using ${THREADS} threads for alignment" >&2

# Check if the reference index exists.  BWA index writes several
# files with extensions .bwt/.pac/.ann/.amb/.sa.  We test one of
# these to decide whether to run indexing.
if [[ ! -f "${REFERENCE}.bwt" ]]; then
  echo "[bwa_align.sh] Indexing reference ${REFERENCE}" >&2
  bwa index "$REFERENCE"
fi

# Run BWA MEM.  The -t option sets the number of threads.  The
# -v option is omitted so BWA prints only errors.  Output is
# redirected to the specified file.  You can adjust parameters here
# (e.g. add -M to flag shorter split hits or -R for read group).
echo "[bwa_align.sh] Running bwa mem on ${READS}" >&2
bwa mem -t "${THREADS}" "${REFERENCE}" "${READS}" > "${OUTPUT}"

echo "[bwa_align.sh] Alignment complete.  Output written to ${OUTPUT}" >&2