# Ubuntu 24.04 matches the binary's glibc (2.39); a zip/provided.al2023 runtime is glibc 2.34 and won't load it.
FROM ubuntu:24.04
ARG ITBAA_VERSION=v1.1.0

# fonts-noto-core: itbaa falls back to system fonts for non-Latin glyphs, and a bare image has none (Arabic → tofu).
RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates curl jq \
      libstdc++6 libgcc-s1 libatomic1 \
      fonts-liberation fonts-noto-core \
 && rm -rf /var/lib/apt/lists/* \
 && curl -fsSL https://raw.githubusercontent.com/ahmedrowaihi/itbaa/main/install.sh \
      | ITBAA_VERSION="${ITBAA_VERSION}" sh

ENV HOME=/tmp XDG_CACHE_HOME=/tmp
COPY bootstrap /bootstrap
RUN chmod +x /bootstrap
ENTRYPOINT ["/bootstrap"]
