FROM openresty/openresty:alpine-fat

RUN /usr/local/openresty/luajit/bin/luarocks install lua-resty-template
RUN /usr/local/openresty/luajit/bin/luarocks install lua-resty-http
RUN /usr/local/openresty/luajit/bin/luarocks install busted
RUN /usr/local/openresty/luajit/bin/luarocks install lrexlib-posix
ENV LUA_PATH=$LUA_PATH;/usr/local/openresty/nginx/lua/?.lua;/usr/local/openresty/nginx/lua/utils/?.lua

COPY nginx.conf /usr/local/openresty/nginx/conf/nginx.conf
COPY templates /usr/local/openresty/nginx/html/templates
COPY lua /usr/local/openresty/nginx/lua
COPY static /usr/local/openresty/nginx/static
