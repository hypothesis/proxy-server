local hypothesis_header = require('hypothesis_header') 

local _getenv = os.getenv

describe("hypothesis_header", function()
    setup(function()
        -- Patch os.getenv to return H_EMBED_URL value.
        os.getenv = function(env_var) 
            if env_var == "H_EMBED_URL" then
                return "http://hypothes.is/embed.js"
            end
            return nil
        end
    end)

    teardown(function()
        -- Restore os.getenv.
        os.getenv = _getenv
    end)

    function mock_ngx (query_args)
        -- Mock openresty's ngx api.
        local mocked_ngx = mock({
            req = {
                get_query_args = function() return query_args end
            },
            var = {
                original_scheme = "http",
                http_host = "via.hypothes.is",
                upstream = "http://thirdparty.com/"
            },
            unescape_uri = function(uri) return uri end
        })
        return mocked_ngx
    end

    function mock_query_args (request_config, open_sidebar)
        -- Mock client configuration options.
        local via_request_config = "via.request_config_from_frame"
        local via_open_sidebar = "via.open_sidebar"
        local query_args = {}
        query_args[via_request_config] = request_config
        query_args[via_open_sidebar] = open_sidebar
        return query_args
    end

    it("excludes open_sidebar if 0", function()
        query_args = mock_query_args("http://lms.hypothes.is", "0")
        mocked_ngx = mock_ngx(query_args)

        local header = hypothesis_header.generate_hypothesis_header(mocked_ngx)

        assert.falsy(string.find(header, "openSidebar: true"))
    end)

    it("excludes open_sidebar if nil", function()
        query_args = mock_query_args("http://lms.hypothes.is", nil)
        mocked_ngx = mock_ngx(query_args)

        local header = hypothesis_header.generate_hypothesis_header(mocked_ngx)

        assert.falsy(string.find(header, "openSidebar: true"))
    end)

    it("excludes request config from frame if nil", function()
        query_args = mock_query_args(nil, "1")
        mocked_ngx = mock_ngx(query_args)

        local header = hypothesis_header.generate_hypothesis_header(mocked_ngx)

        assert.falsy(string.find(header, "requestConfigFromFrame: 'http://lms.hypothes.is'"))
    end)


    it("contains embeded hypothesis configuration", function()
        query_args = mock_query_args("http://lms.hypothes.is", "1")
        mocked_ngx = mock_ngx(query_args)

        local header = hypothesis_header.generate_hypothesis_header(mocked_ngx)

        assert.truthy(string.find(header, "requestConfigFromFrame: 'http://lms.hypothes.is'"))
        assert.truthy(string.find(header, "openSidebar: true"))
    end)

    it("contains canonical link to thirdyparty url", function()
        query_args = mock_query_args("http://lms.hypothes.is", "1")
        mocked_ngx = mock_ngx(query_args)

        local header = hypothesis_header.generate_hypothesis_header(mocked_ngx)

        local expected = [[<link rel="canonical" href="http://thirdparty.com/"/>]]
        assert.truthy(string.find(header, expected))
    end)

    it("contains embed.js script", function()
        query_args = mock_query_args("http://lms.hypothes.is", "1")
        mocked_ngx = mock_ngx(query_args)

        local header = hypothesis_header.generate_hypothesis_header(mocked_ngx)

        local expected = [[<script src="http://hypothes.is/embed.js"></script>]]
        assert.truthy(string.find(header, expected))
    end)
end)
