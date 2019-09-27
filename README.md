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
