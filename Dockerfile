FROM hypothesis/openresty-alpine-fat:latest

RUN /usr/local/openresty/luajit/bin/luarocks install lua-resty-template
RUN /usr/local/openresty/luajit/bin/luarocks install lua-resty-http

COPY nginx.conf /usr/local/openresty/nginx/conf/nginx.conf
COPY templates /usr/local/openresty/nginx/html/templates
COPY lua /usr/local/openresty/nginx/lua
COPY static /usr/local/openresty/nginx/static
