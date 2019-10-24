local http = require "resty.http"
local httpc = http.new()
--httpc:set_timeout(4000)
httpc:connect("127.0.0.1", 9081)

function request_content_type_header(method)
    local response, err = httpc:request({
      path = "/id_/follow_redirect" .. ngx.var.request_uri, 
      method = method,
      headers = ngx.req.get_headers(),
      keepalive_timeout = 60,
      keepalive_pool = 10,
    })
    if response and response.status then
        ngx.log(ngx.STDERR, method .. " request for " .. ngx.var.request_uri .. " responded with: " .. response.status)
    end
    return response, err
end

local response, err = request_content_type_header("HEAD")
local success = response and response.status >= 200 and response.status < 400

if not success then
    ngx.log(ngx.STDERR, "HEAD request for " .. ngx.var.request_uri .. " failed.")
    response, err = request_content_type_header("GET")
end

ngx.log(ngx.STDERR, "Using Content-Type: " .. response.headers["Content-Type"] .. " to direct request")
if (response.headers["Content-Type"] == "application/pdf" 
        or response.headers["Content-Type"] == "application/x-pdf") then
    return ngx.exec("/pdf" .. ngx.var.request_uri)
else
    return ngx.redirect(os.getenv("VIA_URL") .. ngx.var.request_uri, 302)
end
