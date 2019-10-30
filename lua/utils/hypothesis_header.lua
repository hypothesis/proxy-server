
local hypothesis_header = {}

function _render_template_string (
    canonical_url,
    h_embed_url,
    request_config_from_frame,
    open_sidebar
    )

    local hypothesis_header = [[
    <!-- Set canonical url -->
    <link rel="canonical" href="{* canonical_url *}"/>
    
    <!-- Inject Hypothesis -->
    <script src="{* h_embed_url *}"></script>
    <script>
      // Configure Hypothesis client. 
      window.hypothesisConfig = function() {
        return {
          showHighlights: true,
          appType: 'via',
      
          {* h_request_config *}
          {* h_open_sidebar *}
      
        };
      }
    </script>
    ]]

    -- Generate the config options as strings.
    local h_request_config = ""
    if request_config_from_frame then
        h_request_config = "requestConfigFromFrame: '" .. request_config_from_frame .. "',"
    end

    local h_open_sidebar = ""
    if tonumber(open_sidebar) == 1 then
        h_open_sidebar = "openSidebar: true,"
    end

    -- Replace the html variables with actual values.
    hypothesis_header = hypothesis_header:gsub("%{%* canonical_url %*%}", canonical_url)
    hypothesis_header = hypothesis_header:gsub("%{%* h_embed_url %*%}", h_embed_url)
    hypothesis_header = hypothesis_header:gsub("%{%* h_request_config %*%}", h_request_config)
    hypothesis_header = hypothesis_header:gsub("%{%* h_open_sidebar %*%}", h_open_sidebar)
    return hypothesis_header
end

function hypothesis_header.generate_hypothesis_header (ngx)
    local original_scheme = ngx.var.original_scheme
    -- http_x_forwarded_proto or ngx.var.scheme;
    local query_params = ngx.req.get_query_args()
    
    -- The proxied third party url.
    local canonical_url = ngx.unescape_uri(ngx.var.upstream)
    
    -- The url to the embeded hypothesis client.
    local h_embed_url = os.getenv("H_EMBED_URL")
    
    -- The hypthesis client requestConfigFromFrame configuration option.
    local request_config = ngx.unescape_uri(query_params["via.request_config_from_frame"])
    
    -- The hypthesis client open_sidebar configuration option.
    local open_sidebar = query_params["via.open_sidebar"]
    
    return _render_template_string(
        canonical_url,
        h_embed_url,
        request_config,
        open_sidebar)
end

return hypothesis_header
