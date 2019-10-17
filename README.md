# proxy-server
Serves third party webpages (currently limited to pdfs) with the hypothesis client embedded and configured.

# How it works
This is a prototype of a pdf cors proxy server implemented in nginx and lua.
Lua is an interpreted language similar to Python. It is used to perform some
simple logic and templating at the nginx layer.

When a request to the proxy is issued at for example:
`localhost:9081/http://example.com/pdf.pdf` it is routed to the '/' endpoint.
This is a non-blocking request. Once it completes, it looks at the 
Content-Type response header to see if it contains a pdf type and if it does
it issues an internal redirect to `localhost:9081/pdf/http://example.com/pdf.pdf`. If the
content type does not match a pdf it is routed to `localhost:9080/http://example.com/pdf.pdf`
(aka via).

The `/pdf/` endpoint responds with the pdf and the hypothesis client embeded in an html page.
This pdf page also contains a url to the proxied pdf: `localhost:9081/id_/http://example.com/pdf.pdf`

[Nginx + Lua Presentation Slides](https://docs.google.com/presentation/d/17DknFhjNm63XZAvynlMEZHxW1ZrIYZ7jgzdkjd8rr6Y/edit?usp=sharing)

# Getting Started
Note this is dependent on H, the Client, and Via so those services also need to be running.

To run:
```
docker-compose up -d
```

To stop:
```
docker-compose down
``` 

# Running in Development Mode
Alternatively, to see logging from nginx you can run:
```
docker-compose run --service-ports proxy-server
```

To stop ctrl-C and run:

```
docker-compose rm -f proxy-server
```

# Testing
1. Open a Canvas pdf assignment and in Chrome's Devtools, verify that all requests to the pdf go to the proxy-server service at localhost:9081 and not to via at localhost:9080. Verify that the sidebar is open automatically, the pdf renders as expected, the correct group is focused and the correct user is logged in the sidebar.

1. Create a service that serves a pdf and sets a cookie as part of the response. Verify that when that pdf is requested through the proxy server with auth and session cookies set via `http://localhost:9081/id_/<pdf-url>`, the service that serves the pdf does not recieve the auth or session cookies, and that the response from the request does not contain the cookie set by the service that serves the pdf.

1. Create a service that serves a pdf and sets a cookie as part of the response. Verify that when that pdf is requested through the proxy server with auth and session cookies set via `http://localhost:9081/id_/follow_redirect/<pdf-url>`, the service that serves the pdf does not recieve the auth or session cookies, and that the response from the request does not contain the cookie set by the service that serves the pdf.

1. Create a service that does not accept HEAD requests for a pdf. Verify that when that pdf is requested through the proxy server via `http://localhost:9081/<pdf-url>`, a failed HEAD request log message appears in the stderror output of the running proxy-server container. 

1. Try to request: `http://localhost:9081/pdf/http://www.pdf995.com/samples/pdf.pdf`. You should recieve a 404 Not Found.

1. Try to request: `http://localhost:9081/templates/pdfjs_viewer.html`. You should recieve a 404 Not Found.

1. Try to request: `http://localhost:9081/http://example.com`. It should redirect to `http://localhost:9080/http://example.com`.

Note in all of these tests it is a good idea to glance at the stderror output from the running proxy-server container and make sure there are no errors as well as check the console output in your browser.
