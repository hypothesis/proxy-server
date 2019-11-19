local http = require "resty.http"
local httpc = http.new()
httpc:connect("127.0.0.1", 9081)

-- parse_uri sets path = '/' for empty paths which is necessary to signal nginx to
-- treat the proxy_pass uri as the server + path as opposed to just the server.
-- See docs http://nginx.org/en/docs/http/ngx_http_proxy_module.html#proxy_pass for details.
local scheme, host, port, path = unpack(http:parse_uri(ngx.var.request_uri:sub(2)))
local request_uri = "/" .. scheme .. '://' .. host .. ":" .. port .. path

function request_content_type_header(method)
    local response, err = httpc:request({
      path = "/id_/follow_redirect" .. request_uri, 
      method = method,
      headers = ngx.req.get_headers(),
      keepalive_timeout = 60,
      keepalive_pool = 10,
    })
    if response and response.status then
        ngx.log(ngx.STDERR, method .. " request for " .. request_uri .. " responded with: " .. response.status)
    end
    return response, err
end

local response, err = request_content_type_header("HEAD")
local success = response and response.status >= 200 and response.status < 400

if not success then
    ngx.log(ngx.STDERR, "HEAD request for " .. request_uri .. " failed.")
    response, err = request_content_type_header("GET")
end

local content_type_header = response.headers["Content-Type"] or "nil"
ngx.log(ngx.STDERR, "Using Content-Type: " .. content_type_header .. " to direct request")
if (content_type_header == "application/pdf"
        or content_type_header == "application/x-pdf") then
    return ngx.exec("/pdf" .. request_uri)
else
    return ngx.redirect(os.getenv("VIA_URL") .. ngx.var.request_uri, 302)
end
