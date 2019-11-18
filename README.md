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

# Making Changes to the openresty-alpine-fat Docker Base Image
The base docker image for the proxy-server is based on the official 
openresty alpine fat image with some additional nginx modules. This means 
that the base image for the proxy-server must be custom built and pushed 
to Hypothesis's Dockerhub. The Dockerfiles for these base images are 
located in the dockerfiles directory. Because the base image so rarely 
needs to be modified this process is not part of the proxy-server release 
flow.

## Building
To build the docker image run:
```
make openresty-alpine
```
This will build two docker images: openresty-alpine-fat and it's dependency
openresty-alpine. Both these images are tagged with "latest". 

```
docker images | grep "openresty-alpine"

hypothesis/openresty-alpine-fat   latest   8c3f9d5fdf7c   About 1 min ago   308MB
hypothesis/openresty-alpine       latest   0c1e272acd66   About 1 min ago   101MB
```

## Releasing
In order to release a new version of openresty-alpine-fat two tags of each 
of the base images must be pushed: the new version tagged with the version 
number and the one already built for you by the make command tagged with 
"latest". Note `<version>` should be replaced with the new version number 
such as 1.0.1. 
```
docker tag 8c3f9d5fdf7c hypothesis/openresty-alpine-fat:<version>
docker tag 0c1e272acd66 hypothesis/openresty-alpine:<version>

docker images | grep "openresty-alpine"

hypothesis/openresty-alpine-fat   1.0.1     8c3f9d5fdf7c  About 1 min ago   308MB
hypothesis/openresty-alpine-fat   latest    8c3f9d5fdf7c  About 1 min ago   308MB
hypothesis/openresty-alpine       1.0.1     0c1e272acd66  About 1 min ago   101MB
hypothesis/openresty-alpine       latest    0c1e272acd66  About 1 min ago   101MB
```

To push these images to Hypothesis's Dockerhub run:
```
docker push hypothesis/openresty-alpine-fat:<version>
docker push hypothesis/openresty-alpine-fat:latest
docker push hypothesis/openresty-alpine:<version>
docker push hypothesis/openresty-alpine:latest
```
Note you may need to login to docker using `docker login` before pushing. 

## Running/Testing
In order to pull these changes into your local dev environment you may need
 to force a rebuild of the proxy-server docker container by running:
```
docker pull hypothesis/openresty-alpine-fat:latest
docker-compose build proxy-server
```

# Testing
For any test that makes use of a /test endpoint you will need to remove the `internal;` from that location block during testing. The `internal;` hides this endpoint from being proxied on production.

1. Open a Canvas pdf assignment and in Chrome's Devtools, verify that all requests to the pdf go to the proxy-server service at localhost:9081 and not to via at localhost:9080. Verify that the sidebar is open automatically, the pdf renders as expected, the correct group is focused and the correct user is logged in in the sidebar.

1. Verify that when a pdf is requested through the proxy server with auth and session cookies set via `http://localhost:9081/id_/http://127.0.0.1:9081/test/example.pdf`:
    * The service that serves the pdf does not recieve the auth or session cookies present in your browser. This can be verified by checking the proxy-server stdout for the Cookie header contents. You should see something like the following:
   ```
   2019/10/21 17:49:10 [] 6#6: *3 [lua] log_cookie_header.lua:3: cookie header: <cookie contents>
   ``` 
    * The response from the request does not contain the cookie set by the /test/example.pdf endpoint. This can be verified by the absense of the request response header Set-Cookie in the Chrome Devtools->Network tab and the absense of test=example-cookie in the contents of your Cookie in the Chrome Devtools->Application tab. 
1. Verify that when a pdf is requested through the proxy server with auth and session cookies set via `http://localhost:9081/id_/follow_redirect/http://127.0.0.1:9081/test/example.pdf`:
    * The service that serves the pdf does not recieve the auth or session cookies present in your browser. This can be verified by checking the proxy-server stdout for the Cookie header contents. You should see something like the following:
   ```
   2019/10/21 17:49:10 [] 6#6: *3 [lua] log_cookie_header.lua:3: cookie header: <cookie contents>
   ``` 
    * The response from the request does not contain the cookie set by the /test/restricted/example.pdf endpoint. This can be verified by the absense of the request response header Set-Cookie in the Chrome Devtools->Network tab and the absense of test=example-cookie in the contents of your Cookie in the Chrome Devtools->Application tab. 

1. Verify that when a pdf is requested through the proxy server via `http://localhost:9081/http://127.0.0.1:9081/test/restricted/example.pdf`, the following log message appears in the stderror output of the running proxy-server container. 
   ```
   HEAD request for /http://127.0.0.1:9081/test/restricted/example.pdf failed
   ```

1. Try to request: `http://localhost:9081/pdf/http://www.pdf995.com/samples/pdf.pdf`. You should recieve a 404 Not Found.

1. Try to request: `http://localhost:9081/templates/pdfjs_viewer.html`. You should recieve a 404 Not Found.

1. Try to request: `http://localhost:9081/http://example.com`. It should redirect to via at `http://localhost:9080/http://example.com`.

Note in all of these tests it is a good idea to glance at the stderror output from the running proxy-server container and make sure there are no errors as well as check the console output in your browser.
