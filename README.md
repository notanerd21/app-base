# app-base

Shared runtime base image for the app-host apps: Node 22 (Debian bookworm) + Google Chrome, weasyprint 68.1,
ghostscript, ffmpeg, libvips (sharp), pango/harfbuzz, fonts, build tools.

```
FROM ghcr.io/notanerd21/app-base:node22-20261109 # fixed tag — apps always pin one of these
FROM ghcr.io/notanerd21/app-base:node22          # moving tag = newest build, only for trying
```

Built only on purpose: a change to the `Dockerfile`, or by hand (Actions → build app-base → Run workflow) — no
schedule, so nothing changes under the apps by itself. A new build gets a new dated tag; an app uses it only after its
`FROM` line is changed. The build runs a self-check (node, weasyprint, Chrome, ffmpeg, ghostscript) — a broken image is
never pushed.

To add a system package for all apps: add it to the `apt-get install` list in `Dockerfile` and push.
