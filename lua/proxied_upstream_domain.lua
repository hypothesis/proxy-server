local http = require "resty.http"

-- Return the domain of the proxied third party url.
local scheme, host, port, path = unpack(http:parse_uri(ngx.var.upstream))

return host
