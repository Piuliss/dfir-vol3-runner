# In-container quick reference (mirrors top-level README.md so the image is self-describing)

## What this image does

This is a Volatility 3 runner, built specifically so DFIR against Windows RAM dumps works on macOS arm64 (Apple Silicon) via Docker Desktop's LinuxKit amd64 emulation.

## Why it matters

In the original case (GRUPOALCON ransomware incident), native macOS arm64 Vol3 returned 0 rows for several key plugins including `pslist`, `pstree`, `netscan`, and `hashdump`. Under LinuxKit amd64 the same Vol3 recovered 25 processes via `psscan` and 27 network connections via `netscan`. Other plugins still return empty rows on that dump — see the top-level `README.md` for full limitations and per-plugin results.

## Use cases

- Recover terminating-process pool snapshots when `pslist` is empty.
- Recover network scan with `netscan` and `netstat` even when `pslist` is empty.
- Try a credential-extraction sweep with `hashdump` and `lsadump` against the same RAM (often still empty, see limitations).
- Cross-check results with KAPE / Velociraptor outputs of the same host.

## See also

- Top-level `README.md` for the full quick-start and limitations.
