local http = require "resty.http"

local original_scheme = ngx.var.http_x_forwarded_proto or ngx.var.scheme;
local query_params = ngx.req.get_query_args()

local hypothesis_header = [[
<script>
window.viaUrl = "{* via_url *}/id_/{* upstream_host *}";
</script>
<script src='{* via_url *}/static/scripts/replace_links.js'></script>

<!-- Set canonical url -->
<link rel="canonical" href="{* url *}"/>

<!-- Inject Hypothesis -->
<script>

/**
  * Return `true` if this frame has no ancestors or its nearest ancestor was
  * not served through Via.
  *
  * The implementation relies on all documents proxied through Via sharing the
  * same origin.
  */
function isTopViaFrame() {
  if (window === window.top) {
    // Trivial case - This is the top-most frame in the tab so it must be the
    // top Via frame.
    return true;
  }

  try {
    // Get a reference to the parent frame. Via's "wombat.js" frontend code
    // monkey-patches `window.parent` in certain cases, in which case
    // `window.__WB_orig_parent` is the _real_ parent frame.
    var parent = window.parent;

    // Try to access the parent frame's location. This will trigger an
    // exception if the frame comes from a different, non-Via origin.
    //
    // This test assumes that all documents proxied through Via are served from
    // the same origin. If a future change to Via means that is no longer the
    // case, this function will need to be implemented differently.
    parent.location.href;

    // If the access succeeded, the parent frame was proxied through Via and so
    // this is not the top Via frame.
    return false;
  } catch (err) {
    // If the access failed, the parent frame was not proxied through Via and
    // so this is the top Via frame.
    return true;
  }
}

(function () {

  if (!isTopViaFrame()) {
    // Do not inject Hypothesis into iframes in documents proxied through Via.
    // As well as slowing down the loading of the proxied page even more, this
    // causes problems with the way that the client "discovers" annotate-able iframes.
    //
    // See https://github.com/hypothesis/client/issues/568,
    // https://github.com/hypothesis/via/issues/119 and
    // https://github.com/hypothesis/lms/issues/701.
    return;
  }
  
  var embed_script = document.createElement("script");
  embed_script.src = "{* h_embed_url *}";
  document.head.appendChild(embed_script);
  
  
  // Configure Hypothesis client. 
  window.hypothesisConfig = function() {
    return {
      showHighlights: true,
      appType: 'via',
  
      {* h_request_config *}
      {* h_open_sidebar *}
  
    };
  }
})();

</script>
]]

local scheme, host, port, path = unpack(http:parse_uri(ngx.var.upstream))
-- The proxied third party url.
local url = ngx.unescape_uri(ngx.var.upstream)
-- The scheme + domain of the proxy server.
local via_url = original_scheme .. "://" .. ngx.var.http_host 
-- The url to the embeded hypothesis client.
local h_embed_url = os.getenv("H_EMBED_URL")
-- The hypthesis client requestConfigFromFrame configuration option.
h_request_config = ""
if not (ngx.unescape_uri(query_params["via.request_config_from_frame"]) == nill) then
    h_request_config = "requestConfigFromFrame: '" .. ngx.unescape_uri(query_params["via.request_config_from_frame"]) .. "',"
end
-- The hypthesis client open_sidebar configuration option.
h_open_sidebar = ""
if not (ngx.unescape_uri(query_params["via.open_sidebar"]) == nill) then
    h_open_sidebar = "open_sidebar: true,"
end

-- Replace the html variables with actual values.
hypothesis_header = hypothesis_header:gsub("%{%* upstream_host %*%}", scheme .. "://" .. host)
hypothesis_header = hypothesis_header:gsub("%{%* url %*%}", url)
hypothesis_header = hypothesis_header:gsub("%{%* via_url %*%}", via_url)
hypothesis_header = hypothesis_header:gsub("%{%* h_embed_url %*%}", h_embed_url)
hypothesis_header = hypothesis_header:gsub("%{%* h_request_config %*%}", h_request_config)
hypothesis_header = hypothesis_header:gsub("%{%* h_open_sidebar %*%}", tostring(h_open_sidebar))
return hypothesis_header
