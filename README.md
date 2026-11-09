# app-base

Shared runtime base image for the app-host apps: Node 22 (Debian bookworm) + Google Chrome, weasyprint 68.1,
ghostscript, ffmpeg, libvips (sharp), pango/harfbuzz, fonts, build tools.

```
FROM ghcr.io/notanerd21/app-base:node22          # moving tag, rebuilt monthly
FROM ghcr.io/notanerd21/app-base:node22-20261109 # fixed tag, to pin or roll back
```

Rebuilt automatically by GitHub Actions: on the 1st of every month (OS security updates), on every change to the
`Dockerfile`, or by hand (Actions → build app-base → Run workflow). The build runs a self-check (node, weasyprint,
Chrome, ffmpeg, ghostscript) — a broken image is never pushed.

To add a system package for all apps: add it to the `apt-get install` list in `Dockerfile` and push.
