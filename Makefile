.PHONY: help
help:
	@echo "make help              Show this help message"
	@echo "make docker            Make the app's Docker image"
	@echo "make run-docker        Run the app's Docker image locally. "
	@echo "make openresty-alpine  Make the app's base openresty-alpine-fat docker image (and it's dependency openresty-alpine)"

DOCKER_TAG = dev

.PHONY: docker
docker:
	git archive --format=tar.gz HEAD | docker build -t hypothesis/proxy-server:$(DOCKER_TAG) -f Dockerfile -

.PHONY: run-docker
run-docker:
	docker run \
		--net hypothesis-dev_default \
        -e H_EMBED_URL=http://localhost:5000/embed.js \
        -e VIA_URL=http://localhost:9080 \
		-p 9081:9081 \
		hypothesis/proxy-server:$(DOCKER_TAG)

.PHONY: openresty-alpine
openresty-alpine:
	docker build --build-arg RESTY_CONFIG_OPTIONS_MORE="--add-module=/usr/src/ngx_http_substitutions_filter_module" --tag=hypothesis/openresty-alpine:latest -f dockerfiles/Dockerfile .
	docker build --build-arg RESTY_IMAGE_BASE="hypothesis/openresty-alpine" --build-arg RESTY_IMAGE_TAG="latest" --tag=hypothesis/openresty-alpine-fat:latest -f dockerfiles/Dockerfile.fat .

