from pyramid import view
import pyramid.httpexceptions as exc
import requests
from urllib.parse import urlsplit

@view.view_config(renderer="proxy_server:templates/index.html.jinja2", route_name="index")
def index(request):
    return {}

@view.view_config(renderer="proxy_server:templates/pdfjs_viewer.html.jinja2", route_name="pdf")
def pdf(request):
    nginx_server = request.registry.settings["nginx_server"]
    pdf_url = request.matchdict["pdf_url"]
    return {
        "url": f'{nginx_server}/proxy/static/{pdf_url}',
        "h_embed_url": request.registry.settings["embed_url"],
        "h_open_sidebar": int(request.params.get("via.open_sidebar", "0")),
        "h_request_config": request.params.get("via.request_config_from_frame", None),

    }

@view.view_config(route_name="content_type")
def content_type(request):
    url = request.matchdict["url"]
    response = requests.get(url, stream=True)
    if response.headers.get("Content-Type") in ("application/x-pdf", "application/pdf"):
        raise exc.HTTPFound(request.route_url("pdf", pdf_url=url))
    via_url = request.registry.settings["via_url"]
    raise exc.HTTPFound(f'{via_url}/{url}')

def includeme(config):
    config.add_route("index", "/")
    config.add_route("pdf", "/pdf/{pdf_url:.*}")
    config.add_route("content_type", "/{url:.*}")
    config.scan(__name__)
