FROM openresty/openresty:alpine-fat

RUN /usr/local/openresty/luajit/bin/luarocks install lua-resty-template

COPY nginx.conf /usr/local/openresty/nginx/conf/nginx.conf
COPY templates /usr/local/openresty/nginx/html/templates
COPY lua /usr/local/openresty/nginx/lua
COPY static /usr/local/openresty/nginx/static
