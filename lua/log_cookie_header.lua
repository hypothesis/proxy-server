local headers = ngx.req.get_headers()
ngx.log(ngx.STDERR, "cookie header:" .. headers["Cookie"] .."\n\n")
