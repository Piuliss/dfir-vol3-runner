# Dockerfile for dfir-vol3-runner
#
# Cross-arch (linux/amd64 emulation on apple silicon, native on intel)
# Volatility 3 + Capstone + helper scripts pre-installed.
# Used during DFIR against RAM-GASRDC01 (Incident ransomware Inc.BAA, GRUPOALCON.LOCAL).
#
# Build:
#   docker build -t honeyjack/dfir-vol3-runner:1.0.0 \
#                -t honeyjack/dfir-vol3-runner:latest .
#
# Run with a RAM file mounted:
#   docker run --rm --platform linux/amd64 \
#       -v "$PWD/data:/data:ro" \
#       -v "$PWD/out:/out" \
#       honeyjack/dfir-vol3-runner:latest \
#       bash -c "vol -f /data/RAM.raw --cache-path /tmp/cache windows.pslist"
#
# Or the bundled helper:
#   docker run --rm --platform linux/amd64 \
#       -v "$PWD/data/RAM.raw:/RAM.raw:ro" \
#       -v "$PWD/out:/out" \
#       honeyjack/dfir-vol3-runner:latest bash /out/run_plugins.sh
FROM --platform=linux/amd64 python:3.11-slim

LABEL org.opencontainers.image.title="dfir-vol3-runner" \
      org.opencontainers.image.description="Volatility 3 + helpers for RAM DFIR on macOS arm64 via LinuxKit amd64 emulation." \
      org.opencontainers.image.source="https://github.com/Piuliss/dfir-vol3-runner" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.authors="Raul Benitez Netto <raulbeni@gmail.com>"

RUN apt-get update -qq \
 && DEBIAN_BUILD_TOOLS="curl ca-certificates" \
    apt-get install -y --no-install-recommends $DEBIAN_BUILD_TOOLS \
 && pip install --no-cache-dir -q \
      'volatility3==2.28.2' \
      'capstone' \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /work
COPY scripts/run_plugins.sh /work/run_plugins.sh
COPY scripts/run_priority.sh /work/run_priority.sh
COPY README.runner.md /work/README.md
RUN chmod +x /work/*.sh

# Default: print banner + help
ENTRYPOINT ["python", "-m", "volatility3", "-v"]
CMD ["--help"]
