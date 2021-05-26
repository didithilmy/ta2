# FROM golang:latest AS builder

# ENV DATAPLANE_MINOR 2.3.1
# ENV DATAPLANE_URL https://github.com/haproxytech/dataplaneapi.git

# RUN git clone "${DATAPLANE_URL}" "${GOPATH}/src/github.com/haproxytech/dataplaneapi"
# RUN cd "${GOPATH}/src/github.com/haproxytech/dataplaneapi" && \
#     git checkout "v${DATAPLANE_MINOR}" && \
#     make build && cp build/dataplaneapi /dataplaneapi

FROM debian:buster-slim

MAINTAINER Dinko Korunic <dkorunic@haproxy.com>

LABEL Name HAProxy
LABEL Release Community Edition
LABEL Vendor HAProxy
LABEL Version 2.3.10
LABEL RUN /usr/bin/docker -d IMAGE

ENV HAPROXY_BRANCH 2.3
ENV HAPROXY_MINOR 2.3.10
ENV HAPROXY_SHA256 9946e0cfc83f29072b3431e37246221cf9d4a9d28a158c075714d345266f4f35
ENV HAPROXY_SRC_URL http://www.haproxy.org/download

ENV LIBSLZ_MINOR 1.2.0
ENV LIBSLZ_SHA256 723a8ef648ac5b30e5074c013ff61a5e5f54a5aafc9496f7dab9f6b02030bf24
ENV LIBSLZ_URL https://github.com/wtarreau/libslz/archive/refs/tags

ENV HAPROXY_UID haproxy
ENV HAPROXY_GID haproxy

ENV DEBIAN_FRONTEND noninteractive

# COPY --from=builder /dataplaneapi /usr/local/bin/dataplaneapi

RUN apt-get update && \
    apt-get install -y --no-install-recommends procps libssl1.1 zlib1g "libpcre2-*" liblua5.3-0 libatomic1 tar curl socat ca-certificates && \
    apt-get install -y --no-install-recommends gcc make libc6-dev libssl-dev libpcre2-dev zlib1g-dev liblua5.3-dev && \
    curl -sfSL "${LIBSLZ_URL}/v${LIBSLZ_MINOR}.tar.gz" -o libslz.tar.gz && \
    echo "$LIBSLZ_SHA256 *libslz.tar.gz" | sha256sum -c - && \
    mkdir -p /tmp/libslz && \
    tar -xzf libslz.tar.gz -C /tmp/libslz --strip-components=1 && \
    make -C /tmp/libslz static && \
    rm -f libslz.tar.gz && \
    curl -sfSL "${HAPROXY_SRC_URL}/${HAPROXY_BRANCH}/src/haproxy-${HAPROXY_MINOR}.tar.gz" -o haproxy.tar.gz && \
    echo "$HAPROXY_SHA256 *haproxy.tar.gz" | sha256sum -c - && \
    groupadd "$HAPROXY_GID" && \
    useradd -g "$HAPROXY_GID" "$HAPROXY_UID" && \
    mkdir -p /tmp/haproxy && \
    tar -xzf haproxy.tar.gz -C /tmp/haproxy --strip-components=1 && \
    rm -f haproxy.tar.gz && \
    make -C /tmp/haproxy -j"$(nproc)" TARGET=linux-glibc CPU=generic USE_PCRE2=1 USE_PCRE2_JIT=1 USE_OPENSSL=1 \
                            USE_TFO=1 USE_LINUX_TPROXY=1 USE_LUA=1 USE_GETADDRINFO=1 \
                            EXTRA_OBJS="contrib/prometheus-exporter/service-prometheus.o" \
                            USE_SLZ=1 SLZ_INC=/tmp/libslz/src SLZ_LIB=/tmp/libslz \
                            DEBUG=-DDEBUG_THREAD \
                            all && \
    make -C /tmp/haproxy TARGET=linux-glibc install-bin install-man && \
    ln -s /usr/local/sbin/haproxy /usr/sbin/haproxy && \
    mkdir -p /var/lib/haproxy && \
    chown "$HAPROXY_UID:$HAPROXY_GID" /var/lib/haproxy && \
    mkdir -p /usr/local/etc/haproxy && \
    ln -s /usr/local/etc/haproxy /etc/haproxy && \
    cp -R /tmp/haproxy/examples/errorfiles /usr/local/etc/haproxy/errors && \
    rm -rf /tmp/libslz && \
    rm -rf /tmp/haproxy && \
    apt-get purge -y --auto-remove gcc make libc6-dev libssl-dev libpcre2-dev zlib1g-dev liblua5.3-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
    # chmod +x /usr/local/bin/dataplaneapi && \
    # ln -s /usr/local/bin/dataplaneapi /usr/bin/dataplaneapi && \
    # touch /usr/local/etc/haproxy/dataplaneapi.hcl && \
    # chown "$HAPROXY_UID:$HAPROXY_GID" /usr/local/etc/haproxy/dataplaneapi.hcl

COPY haproxy.cfg /usr/local/etc/haproxy
COPY docker-entrypoint.sh /

STOPSIGNAL SIGUSR1

ENTRYPOINT ["/docker-entrypoint.sh"]
# CMD ["haproxy", "-f", "/usr/local/etc/haproxy/haproxy.cfg"]

# FROM haproxytech/haproxy-debian
RUN mkdir /run/haproxy/
RUN adduser haproxy haproxy

RUN apt update && apt install -y unzip build-essential wget libssl-dev

RUN set -ex \
    && saved_apt_mark="$(apt-mark showmanual)" \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    gcc \
    libc6-dev \
    make \
    libreadline-dev \
    dirmngr \
    gnupg \
    unzip \
    && curl -fsSL -o /tmp/lua.tar.gz "https://www.lua.org/ftp/lua-5.3.6.tar.gz" \
    && cd /tmp \
    && echo "f27d20d6c81292149bc4308525a9d6733c224fa5 *lua.tar.gz" | sha1sum -c - \
    && mkdir /tmp/lua \
    && tar -xf /tmp/lua.tar.gz -C /tmp/lua --strip-components=1 \
    && cd /tmp/lua \
    && make linux \
    && make install \
    && curl -fsSL -o /tmp/luarocks.tar.gz "https://luarocks.org/releases/luarocks-3.5.0.tar.gz" \
    && curl -fsSL -o /tmp/luarocks.tar.gz.asc "https://luarocks.org/releases/luarocks-3.5.0.tar.gz.asc" \
    && cd /tmp \
    && export GNUPGHOME="$(mktemp -d)" \
    && export GPG_KEYS="8460980B2B79786DE0C7FCC83FD8F43C2BB3C478" \
    && (gpg --batch --keyserver hkp://ha.pool.sks-keyservers.net:80 --recv-keys "$GPG_KEYS" || gpg --batch --keyserver hkp://ipv4.pool.sks-keyservers.net:80 --recv-keys "$GPG_KEYS" || gpg --batch --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys "$GPG_KEYS" || gpg --batch --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys "$GPG_KEYS") \
    && gpg --batch --verify luarocks.tar.gz.asc luarocks.tar.gz \
    && rm -rf "$GNUPGHOME" \
    && mkdir /tmp/luarocks \
    && tar -xf /tmp/luarocks.tar.gz -C /tmp/luarocks --strip-components=1 \
    && cd /tmp/luarocks \
    && ./configure \
    && make \
    && make install \
    && cd / \
    && apt-mark auto '.*' > /dev/null \
    && apt-mark manual $saved_apt_mark \
    && dpkg-query --show --showformat '${package}\n' | grep -P '^libreadline\d+$' | xargs apt-mark manual \
    && apt-mark manual \
    ca-certificates \
    curl \
    unzip \
    && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /tmp/lua /tmp/lua.tar.gz \
    && rm -rf /tmp/luarocks /tmp/luarocks.tar.gz \
    && luarocks --version \
    && lua -v

RUN luarocks install luaossl \
    && luarocks install luasocket \
    && luarocks install luajson

WORKDIR /webqueue

COPY haproxy.cfg /usr/local/etc/haproxy/haproxy.cfg
COPY ./webqueue/ /webqueue/
CMD ["haproxy", "-d",  "-f", "/usr/local/etc/haproxy/haproxy.cfg"]