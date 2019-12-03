import mock
import pytest
from pyramid import httpexceptions

from proxy_server import views


class TestIndexRoute:
    def test_index_renders_index_template(self, pyramid_request):
        #pyramid_request.override_renderer = mock.PropertyMock()
        result = views.index(pyramid_request)

        #assert "index.html" in pyramid_request.override_renderer
        assert result == {}

class TestPdfRoute:
    #def test_pdf_renders_pdf_template(self, pyramid_request):
    #    pyramid_request.override_renderer = mock.PropertyMock()
    #    result = views.pdf(pyramid_request)
    #    import pdb; pdb.set_trace()

    #    assert "pdfjs_viewer.html" in pyramid_request.override_renderer

    def test_pdf_passes_thirdparty_url_to_renderer(self, pyramid_request, pdf_url):
        nginx_server = pyramid_request.registry.settings.get("nginx_server")
        result = views.pdf(pyramid_request)

        assert result["url"] == f'{nginx_server}/proxy/static/{pdf_url}'

    def test_pdf_passes_h_embed_url_to_renderer(self, pyramid_request):
        result = views.pdf(pyramid_request)

        assert result["h_embed_url"] == pyramid_request.registry.settings["embed_url"]

    @pytest.mark.parametrize("h_open_sidebar,expected_h_open_sidebar",
        [("1", 1), ("0", 0), (None, 0)]
    )
    def test_pdf_passes_open_sidebar_query_parameter_to_renderer(self, pyramid_request, h_open_sidebar, expected_h_open_sidebar):
        if h_open_sidebar is not None:
            pyramid_request.params["via.open_sidebar"] = h_open_sidebar
        result = views.pdf(pyramid_request)

        assert result["h_open_sidebar"] == expected_h_open_sidebar

    @pytest.mark.parametrize("h_request_config,expected_h_request_config",
        [("http://lms.hypothes.is", "http://lms.hypothes.is"), (None, None)]
    )
    def test_pdf_passes_request_config_from_frame_query_parameter_to_renderer(self, pyramid_request, h_request_config, expected_h_request_config):
        if h_request_config is not None:
            pyramid_request.params["via.request_config_from_frame"] = h_request_config

        result = views.pdf(pyramid_request)

        assert result["h_request_config"] == expected_h_request_config

    @pytest.fixture
    def pdf_url(self):
        return "http://thirdparty.url/foo.pdf"

    @pytest.fixture
    def pyramid_request(self, pyramid_request, pdf_url):
        pyramid_request.matchdict = {"pdf_url": pdf_url}
        return pyramid_request


class TestPdfRoute:
    @pytest.mark.parametrize("content_type,redirect_location",
        [
            ("application/pdf", "/pdf/http://thirdparty.url"),
            ("application/x-pdf", "/pdf/http://thirdparty.url"),
            ("text/html", "http://via.hypothes.is/http://thirdparty.url")]
    )
    def test_redirects_based_on_content_type_header(self, pyramid_request, requests, content_type, redirect_location):
        requests.get.return_value.headers.get.return_value = content_type
        with pytest.raises(httpexceptions.HTTPFound) as exc:
            views.content_type(pyramid_request)
        assert exc.value.location == redirect_location

    @pytest.fixture
    def requests(self, patch):
        patched_requests = patch("proxy_server.views.requests")
        patched_requests.get.return_value = mock.Mock()
        return patched_requests

    @pytest.fixture
    def pyramid_request(self, pyramid_request):
        pyramid_request.matchdict = {"url": "http://thirdparty.url"}
        def route_url(path, pdf_url):
            return f'/{path}/{pdf_url}'
        pyramid_request.route_url = route_url
        return pyramid_request
