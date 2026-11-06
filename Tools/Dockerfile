# Browser-accessible Linux desktop (XFCE) with draw.io desktop pre-installed.
# The Ignition Designer Launcher is downloaded from a gateway inside the desktop (see guide).
# draw.io is an Electron app, so its launcher gets --no-sandbox (required inside containers).
FROM lscr.io/linuxserver/webtop:ubuntu-xfce

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends curl ca-certificates; \
    url=$(curl -fsSL https://api.github.com/repos/jgraph/drawio-desktop/releases/latest \
          | grep -o 'https://[^"]*drawio-amd64-[^"]*\.deb' | head -n1); \
    echo "Installing $url"; \
    curl -fsSL -o /tmp/drawio.deb "$url"; \
    apt-get install -y /tmp/drawio.deb; \
    rm -f /tmp/drawio.deb; \
    sed -i 's|^Exec=/opt/drawio/drawio |Exec=/opt/drawio/drawio --no-sandbox |' /usr/share/applications/drawio.desktop; \
    rm -rf /var/lib/apt/lists/*

# Ignition Designer Launcher (Linux package, taken from the 8.3.10 gateway; bundles its own Java runtime).
COPY launcher/designerlauncher.tar.gz /tmp/designerlauncher.tar.gz
RUN set -eux; \
    tar -xzf /tmp/designerlauncher.tar.gz -C /opt; \
    rm -f /tmp/designerlauncher.tar.gz; \
    chmod -R a+rX /opt/designerlauncher; \
    chmod a+x /opt/designerlauncher/designerlauncher.sh /opt/designerlauncher/runtime/bin/*; \
    printf '%s\n' '[Desktop Entry]' 'Type=Application' 'Name=Ignition Designer Launcher' \
      'Exec=/opt/designerlauncher/designerlauncher.sh' 'Icon=/opt/designerlauncher/app/launcher.png' \
      'Categories=Development;' 'Terminal=false' > /usr/share/applications/designerlauncher.desktop
