import os

import pyramid.config


def settings():
    """
    Return the app's configuration settings as a dict.

    Settings are read from environment variables and fall back to hardcoded
    defaults if those variables aren't defined.

    """
    embed_url = os.environ.get("H_EMBED_URL", "https://hypothes.is/embed.js")
    nginx_server = os.environ.get("NGINX_SERVER", "https://via2.hypothes.is")
    via_url = os.environ.get("VIA_URL", "https://via.hypothes.is")

    result = {
        "embed_url": embed_url,
        "nginx_server": nginx_server,
        "via_url": via_url,
    }
    return result


def app():
    """Configure and return the WSGI app."""
    config = pyramid.config.Configurator(settings=settings())
    config.add_static_view(name="static", path="static")
    config.include("pyramid_jinja2")
    #config.registry.settings["jinja2.filters"] = {
    #    "static_path": "pyramid_jinja2.filters:static_path_filter",
    #    "static_url": "pyramid_jinja2.filters:static_url_filter",
    #}
    config.include("proxy_server.views")
    return config.make_wsgi_app()
