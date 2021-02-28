# https://www.mkdocs.org/user-guide/deploying-your-docs/

.PHONY: update-readme-toc add-remote-url update-from-origin

# DEV only
update-readme-toc:
	docker run -v $(shell pwd)":/app" -w /app --rm -it sebdah/markdown-toc README.md --skip-headers 2 --replace --inline --header "## Table of Contents"

# For Git forks
## Add remote url for mainstream
add-remote-url:
	git remote add base https://github.com/coolacid/docker-misp
## Update from mainstream
update-from-origin:
	git fetch base
	git merge base/master
