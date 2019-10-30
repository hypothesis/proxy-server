.PHONY: help
help:
	@echo "make help              Show this help message"
	@echo "make docker            Make the app's Docker image"
	@echo "make run-docker        Run the app's Docker image locally. "
	@echo "make test              Run tests locally"
	@echo "make ci-test           Run tests on the app's Docker image"

DOCKER_TAG = dev
ROOT_DIR:=$(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))

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
.PHONY: test
test:
	docker-compose run --service-ports proxy-server-test

.PHONY: ci-test
test:
	docker run \
		--net hypothesis-dev_default \
		-v $(ROOT_DIR)/tests:/usr/local/openresty/nginx/tests \
		-it \
		hypothesis/proxy-server:$(DOCKER_TAG) \
		busted --pattern=test_ /usr/local/openresty/nginx/tests/lua/ --cpath=/usr/local/openresty/nginx/tests/lua/?.lua;/usr/local/openresty/nginx/tests/lua/utils/?.lua

