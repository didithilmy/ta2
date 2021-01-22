FROM haproxytech/haproxy-debian
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
CMD ["haproxy", "-d", "-f", "/usr/local/etc/haproxy/haproxy.cfg"]