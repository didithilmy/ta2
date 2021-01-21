FROM haproxytech/haproxy-alpine
RUN mkdir /run/haproxy/
RUN adduser haproxy haproxy
COPY haproxy.cfg /usr/local/etc/haproxy/haproxy.cfg
