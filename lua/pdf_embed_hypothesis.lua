local template = require("resty.template")

local template_string = ngx.location.capture("/templates/pdfjs_viewer.html")
local query_params = ngx.req.get_query_args()
template.render(template_string.body, {
    url = ngx.var.request_uri:sub(2),
    h_embed_url = os.getenv("H_EMBED_URL"),
    h_request_config = ngx.unescape_uri(query_params["via.request_config_from_frame"]),
    h_open_sidebar = query_params["via.open_sidebar"],
})
