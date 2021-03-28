# https://www.mkdocs.org/user-guide/deploying-your-docs/

.PHONY: build-docker-misp build-docker-misp-module update-readme-toc add-remote-url update-from-origin

build-docker-misp:
	cp build-docker-compose.yml docker-compose.override.yml
	docker-compose build misp

build-docker-misp-module:
	cp build-docker-compose.yml docker-compose.override.yml
	docker-compose -fbuild misp-module

# DEV only
update-readme-toc:
	docker run -v $(shell pwd)":/app" -w /app --rm -it sebdah/markdown-toc README.md --skip-headers 2 --replace --inline --header "## Table of Contents"

docker-remove-build-run-logs-misp:
	docker-compose down -v
	$(MAKE) build-docker-misp
	docker-compose up -d misp
	docker-compose logs -f

# For Git forks
## Add remote url for mainstream
add-remote-url:
	git remote add base https://github.com/coolacid/docker-misp
## Update from mainstream
update-from-origin:
	git fetch base
	git merge base/master
