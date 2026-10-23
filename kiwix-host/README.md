# Kiwix library host (Mac mini)

Serves the ZIMs in `~/NAS/archives/project-nomad-data` at http://192.168.68.174:8090
with a grouped index page and A–Z appendix. Everything lives in `~/kiwix` on the mini.

| File | Role |
|------|------|
| `build_kiwix_index.py` | Builds `index.html` (sections by NAS folder + A–Z appendix) |
| `sync-library.sh` | Runs inside the container: adds new ZIMs to `library.xml`, drops missing ones |
| `nightly.sh` | 02:30 daily: sync, rebuild index, open every book, restart if hung. Log: `~/kiwix/logs/nightly.log` |
| `watchdog.sh` | Every 5 min: restarts the server after two failed checks. Log: `~/kiwix/logs/watchdog.log` |

## Install / reinstall on the mini

```bash
scp kiwix-host/*.sh kiwix-host/*.py macmini:kiwix/
scp kiwix-host/*.plist macmini:Library/LaunchAgents/
ssh macmini 'for p in kiwix-watchdog kiwix-nightly; do launchctl bootout gui/$(id -u)/com.waltersignal.$p 2>/dev/null; launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.waltersignal.$p.plist; done'
```

Server container (recreate only if missing):

```bash
docker run -d --name kiwix --restart unless-stopped -p 8090:8080 \
  -v ~/NAS/archives/project-nomad-data:/data:ro -v ~/kiwix:/library \
  ghcr.io/kiwix/kiwix-serve:3.7.0 --library --monitorLibrary \
  --customIndex /library/index.html /library/library.xml
```

Do not mount anything at `/lib` in the container; it hides the image's C library.
