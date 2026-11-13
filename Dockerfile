# app-base — shared runtime base for the app-host apps (AiEstate/Listaro, Contenta, Aivy, Journy, AiStudy, Kebab).
#
# Why (09.11.2026): every Coolify deploy re-installed the same system packages (apt, Google Chrome, weasyprint) and
# re-exported them as image layers (~3.6 min of a ~22 min deploy). They almost never change, so they live here, built
# by GitHub Actions on the 1st of every month (security updates) and whenever this file changes. App Dockerfiles start
# with `FROM ghcr.io/notanerd21/app-base:node22` and only install npm packages + build.
#
# The package list = the union of the apps' nixpacks.toml [phases.setup] (aptPkgs + cmds) on 09.11.2026.
#
# Debian 13 trixie (13.11.2026, app-host 10): bookworm ships ffmpeg 5.1, trixie ships ffmpeg 7.1
# (https://packages.debian.org/trixie/ffmpeg → 7:7.1.5-0+deb13u1) with Debian security updates. The apps take the
# system ffmpeg first and the bundled @ffmpeg-installer 4.1 (2018) build only as a fallback. trixie renamed two libs in
# the 64-bit time_t transition: libvips42 → libvips42t64, libglib2.0-0 → libglib2.0-0t64.

FROM node:22-trixie-slim

ENV DEBIAN_FRONTEND=noninteractive \
    NEXT_TELEMETRY_DISABLED=1 \
    CHROME_PATH=/usr/bin/google-chrome \
    PUPPETEER_EXECUTABLE_PATH=/usr/bin/google-chrome \
    PIP_DISABLE_PIP_VERSION_CHECK=1

# System packages (all apps): PDF (ghostscript, weasyprint's pango/harfbuzz), fonts, ffmpeg, libvips for sharp,
# build tools for native npm modules (node-gyp), python for weasyprint.
RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates curl wget unzip git \
      ghostscript ffmpeg \
      python3 python3-pip \
      build-essential pkg-config \
      libpango-1.0-0 libpangoft2-1.0-0 libharfbuzz0b libuuid1 libgl1 libglib2.0-0t64 libvips42t64 \
      fonts-liberation fonts-dejavu-core fonts-noto-color-emoji \
 && rm -rf /var/lib/apt/lists/*

# Google Chrome (Chromium via apt is not usable in containers): the official .deb, its libs resolved by apt.
RUN wget -q -O /tmp/chrome.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb \
 && apt-get update \
 && apt-get install -y --no-install-recommends --fix-missing /tmp/chrome.deb \
 && rm -f /tmp/chrome.deb && rm -rf /var/lib/apt/lists/*

# weasyprint (same pin as the apps' nixpacks.toml)
RUN pip3 install --no-cache-dir --break-system-packages weasyprint==68.1

RUN mkdir -p /opt/print/icc /app/storage
WORKDIR /app

# Self-check at build time: a broken base never gets pushed. ffmpeg must be major 7 or newer, with ffprobe, libx264,
# libmp3lame and aac (what the reel/video/speech renders use).
RUN node --version && python3 -c "import weasyprint; print('weasyprint', weasyprint.__version__)" \
 && google-chrome --version && ffmpeg -version | head -1 && ffprobe -version | head -1 && gs --version \
 && ffmpeg -hide_banner -encoders | grep -q libx264 \
 && ffmpeg -hide_banner -encoders | grep -q libmp3lame \
 && ffmpeg -hide_banner -encoders | grep -qE '^ A.{5} aac ' \
 && FF_MAJOR="$(ffmpeg -version | head -1 | sed -E 's/^ffmpeg version [^0-9]*([0-9]+).*/\1/')" \
 && echo "ffmpeg major: $FF_MAJOR" && [ "$FF_MAJOR" -ge 7 ]
