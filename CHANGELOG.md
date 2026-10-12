# Changelog

## 1.0.0 (2026-10-11)

- Initial release.
- Volatility 3 2.28.2 + Capstone on `python:3.11-slim` built `--platform=linux/amd64`.
- Two helper scripts: `run_plugins.sh` (broad sweep), `run_priority.sh` (credential extraction).
- Verified against `RAM-GASRDC01-20261008-100857.raw` (12.65 GiB winpmem dump of Server 2016 DC):
  - `windows.psscan` recovered 25 processes (incl. terminated `MpDefenderCore`, `MpCmdRun.exe`, `ksnproxy.exe`).
  - `windows.netscan` recovered 27 connections (incl. LDAP established `192.168.1.2:389 -> 192.168.1.2:59882`).
- Known gap: `pslist`/`pstree`/`hashdump`/`lsadump` still return 0 rows on the same dump (dump-specific ActiveProcessLinks walk failure, not platform-related). Captured in top-level README.
