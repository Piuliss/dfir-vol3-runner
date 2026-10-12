# dfir-vol3-runner

**A Docker runner for [Volatility 3](https://github.com/volatilityfoundation/volatility3) that emulates `linux/amd64` so it works on macOS arm64 (Apple Silicon).**

[![Docker Hub](https://img.shields.io/docker/pulls/honeyjack/dfir-vol3-runner.svg)](https://hub.docker.com/r/honeyjack/dfir-vol3-runner)

Built while responding to a ransomware incident (Inc Ransom variant BAA on a Windows Server 2016 DC, GRUPOALCON.LOCAL) where the native macOS arm64 Vol3 plugins returned empty rows for `pslist`, `pstree`, `netscan`, etc., but Docker Desktop's LinuxKit (amd64 emulation) recovered `windows.psscan` (25 processes) and `windows.netscan` (27 connections).

## Why does this exist?

Volatility 3 on macOS arm64 (Apple Silicon) is brittle for some EPROCESS walking plugins on Windows 10 / Server 2016 dumps captured with `winpmem_mini_x64_rc2`. Docker Desktop on macOS uses a LinuxKit x86_64 VM under the hood; running the same Vol3 against the same RAM under that amd64 emulation yielded real results where native macOS arm64 didn't.

This image bundles Vol3 2.28.2 + Capstone + two helper scripts that replicate the DFIR routine: a broad plugin sweep (`run_plugins.sh`) and a credential/extraction priority sweep (`run_priority.sh`).

## Image

```
docker pull honeyjack/dfir-vol3-runner:1.0.0
```

- Hub: https://hub.docker.com/r/honeyjack/dfir-vol3-runner
- Tag: `honeyjack/dfir-vol3-runner`
- Versions: `1.0.0`, `latest`
- Base image: `python:3.11-slim` (built `--platform=linux/amd64`)
- Size: ~54 MB compressed
- OS compat: native linux/amd64; on macOS arm64 uses Docker Desktop's LinuxKit (works)
- Published: 2026-10-11 by @Piuliss
- Digest (`latest` / `1.0.0`): `sha256:96bfeee25097bf06d1fc467552ded3f0a8a55b338475a48ab5aa0dd83e703870`

## Quick start

### Mount your dump, run a single plugin

```bash
docker run --rm --platform linux/amd64 \
    -v "$PWD/RAM.raw:/RAM.raw:ro" \
    honeyjack/dfir-vol3-runner:latest \
    windows.pslist
```

### Run the full DFIR sweep

```bash
docker run --rm --platform linux/amd64 \
    -v "$PWD/data/RAM.raw:/RAM.raw:ro" \
    -v "$PWD/out:/out" \
    honeyjack/dfir-vol3-runner:latest \
    bash /out/run_plugins.sh
```

Output: `/out/vol3_summary.txt` (≈ 200-400 lines for a typical DC RAM dump), plus `vol3_summary.done` marker file.

### Credential dumps (Domain Controller targeting)

```bash
docker run --rm --platform linux/amd64 \
    -v "$PWD/data/RAM.raw:/RAM.raw:ro" \
    -v "$PWD/out:/out" \
    honeyjack/dfir-vol3-runner:latest \
    bash /out/run_priority.sh
```

Output: `/out/vol3_priority.txt` (covers `hashdump`, `lsadump`, `cachedump`, `printkey`, etc.).

## Helper scripts

| Script | What it does |
|---|---|
| `scripts/run_plugins.sh` | `info` + `psscan` + `netscan` + `netstat` + `filescan` + first 16 PIDs of `dlllist` + `hivelist`. ~200-400 lines typical. |
| `scripts/run_priority.sh` | `hivelist` + `printkey` + `hashdump` + `lsadump` + `cachedump` + `sessions` + `info` + `envars` + `getsids` + `process_info` + `cmdline` + `pstree` + `pslist` + `privileges` + `malfind`. Use on hash extraction priority cases. |

Both take env vars: `RAM` (default `/RAM.raw`), `OUT` (default `/out`), `CACHE` (default `/tmp/cache`).

## Known limitations

- **Not all plugins work on every dump.** For some captured-by-winpmem Server 2016 images, `windows.pslist`/`pstree` return 0 rows even under amd64 emulation. The cause appears to be a dump-specific ISPDB / winpmem header offset mismatch, NOT a platform issue. Plugins that scan a tag pool (`psscan`, `netscan`) continue to work.
- **`hashdump`/`lsadump`/`cachedump`** also depend on `hivelist` walking and may return empty on the same dumps. Plan B: capture registry hives via KAPE / Velociraptor and parse with `regipy` standalone.
- **First run is slow** (~30-60 s) because Vol3 builds a per-image symbol cache. The `--cache-path /tmp/cache` volume keeps the cache across runs.

## Architecture decisions

- **Why Python 3.11-slim, not Alpine?** Volatility3 depends on `pefile`, `capstone`, and `construct`; many of those don't have Alpine wheels and require a build toolchain.
- **Why `--platform=linux/amd64`?** The toolchain for `capstone` and the ISPDB JSON layout are tuned for the x86_64 Windows symbols we care about. Running native arm64 forces a recompile and the ISPDB detection is unreliable for some PDBs.
- **Why entrypoint = `vol`?** So you can `docker run ... windows.psscan` directly without quoting.

## Verified case

> 2026-10-08 — DFIR on `GASRDC01` (Server 2016 DC, GRUPOALCON.LOCAL, captured via `winpmem_mini_x64_rc2`).
>
> Native macOS arm64 Vol3 returned 0 rows for `pslist` / `pstree` / `netscan` / `hashdump` / etc. — only `windows.info` worked.
>
> Same Vol3 under this image (LinuxKit amd64) recovered:
> - `windows.psscan`: 25 processes (incl. `MpDefenderCore`, `MpCmdRun.exe`, `Veeam.EndPoint`, `ksnproxy.exe`, `winpmem_mini_x`, `RAM_CAPTURE_UI`, terminated `firefox.exe`).
> - `windows.netscan`: 27 connections (incl. LDAP established 192.168.1.2:389, Kaspersky `ksnproxy.exe` UDP, Microsoft Activation Listener UDP).

## License

MIT. See [LICENSE](LICENSE).

## Contributing

PRs welcome. If you find a new combination of plugins / EVTX pairs that worked for your case, please open an issue with the plugin sweep output so we can extend the helpers.

## References

- [volatilityfoundation/volatility3](https://github.com/volatilityfoundation/volatility3)
- [OASIS Cyber Threat Intelligence — DFIR-on-macOS notes](https://cybolt.tech/)
- Original analysis: GRUPOALCON.LOCAL ransomware incident, 2026-02-17 to 2026-02-19.
