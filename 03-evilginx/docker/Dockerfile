FROM debian:12-slim AS builder

ARG EVILGINX_REPO=https://github.com/kgretzky/evilginx2.git
ARG EVILGINX_REF=master

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
      ca-certificates \
      git \
      golang-go \
      make \
      build-essential \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /src
RUN git clone --depth 1 --branch "${EVILGINX_REF}" "${EVILGINX_REPO}" evilginx2

WORKDIR /src/evilginx2
RUN make

FROM debian:12-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates tini \
    && rm -rf /var/lib/apt/lists/*

ENV HOME=/data

WORKDIR /opt/evilginx2
COPY --from=builder /src/evilginx2 /opt/evilginx2
COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh \
    && mkdir -p /data/phishlets /data/logs /data/config

VOLUME ["/data"]

ENTRYPOINT ["/usr/bin/tini", "--", "/entrypoint.sh"]
