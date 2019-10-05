.PHONY: help
help:
	@echo "make help              Show this help message"
	@echo "make docker            Make the app's Docker image"
	@echo "make run-docker        Run the app's Docker image locally. "

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
