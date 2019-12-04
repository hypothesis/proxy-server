# -*- coding: utf-8 -*-
# pylint: disable=no-self-use
"""
The `conftest` module is automatically loaded by pytest and serves as a place
to put fixture functions that are useful application-wide.
"""
import functools
from unittest import mock

import pytest
from pyramid import testing


def autopatcher(request, target, **kwargs):
    """Patch and cleanup automatically. Wraps :py:func:`mock.patch`."""
    options = {"autospec": True}
    options.update(kwargs)
    patcher = mock.patch(target, **options)
    obj = patcher.start()
    request.addfinalizer(patcher.stop)
    return obj

@pytest.fixture
def patch(request):
    return functools.partial(autopatcher, request)

@pytest.fixture
def pyramid_request(pyramid_settings):
    """Dummy Pyramid request object."""
    request = testing.DummyRequest()
    request.matched_route = mock.Mock()
    request.registry.settings = pyramid_settings
    request.params = {}
    request.GET = request.params
    request.POST = request.params
    return request

@pytest.fixture
def pyramid_settings():
    """Default app settings."""
    return {
        "embed_url": "http://hypothes.is/embed.js",
        "nginx_server": "http://via2.hypothes.is",
        "via_url": "http://via.hypothes.is"}
