include .env
BINARY := oauth2_proxy
VERSION := $(shell git describe --always --dirty --tags 2>/dev/null || echo "undefined")
.NOTPARALLEL:

.PHONY: all
all: dep lint $(BINARY)

.PHONY: clean
clean:
	rm -rf release
	rm -f $(BINARY)

.PHONY: distclean
distclean: clean
	rm -rf vendor

.PHONY: lint
lint:
	$(GOMETALINTER) --vendor --disable-all \
		--enable=vet \
		--enable=vetshadow \
		--enable=golint \
		--enable=ineffassign \
		--enable=goconst \
		--enable=deadcode \
		--enable=gofmt \
		--enable=goimports \
		--deadline=120s \
		--tests ./...

.PHONY: dep
dep:
	$(DEP) ensure --vendor-only

.PHONY: build
build: clean $(BINARY)

$(BINARY):
	CGO_ENABLED=0 $(GO) build -a -installsuffix cgo -ldflags="-X main.VERSION=${VERSION}" -o $@ github.com/pusher/oauth2_proxy

.PHONY: docker
docker:
	docker build -f Dockerfile -t 769352775470.dkr.ecr.us-east-1.amazonaws.com/oauth2_proxy:latest .

.PHONY: docker-push
docker-push:
	docker push 769352775470.dkr.ecr.us-east-1.amazonaws.com/oauth2_proxy:latest

.PHONY: test
test: dep lint
	$(GO) test -v -race ./...

.PHONY: release
release: lint test
	mkdir release
	mkdir release/$(BINARY)-$(VERSION).darwin-amd64.$(GO_VERSION)
	mkdir release/$(BINARY)-$(VERSION).linux-amd64.$(GO_VERSION)
	mkdir release/$(BINARY)-$(VERSION).linux-arm64.$(GO_VERSION)
	mkdir release/$(BINARY)-$(VERSION).linux-armv6.$(GO_VERSION)
	mkdir release/$(BINARY)-$(VERSION).windows-amd64.$(GO_VERSION)
	GOOS=darwin GOARCH=amd64 go build -ldflags="-X main.VERSION=${VERSION}" \
		-o release/$(BINARY)-$(VERSION).darwin-amd64.$(GO_VERSION)/$(BINARY) github.com/pusher/oauth2_proxy
	GOOS=linux GOARCH=amd64 go build -ldflags="-X main.VERSION=${VERSION}" \
		-o release/$(BINARY)-$(VERSION).linux-amd64.$(GO_VERSION)/$(BINARY) github.com/pusher/oauth2_proxy
	GOOS=linux GOARCH=arm64 go build -ldflags="-X main.VERSION=${VERSION}" \
		-o release/$(BINARY)-$(VERSION).linux-arm64.$(GO_VERSION)/$(BINARY) github.com/pusher/oauth2_proxy
	GOOS=linux GOARCH=arm GOARM=6 go build -ldflags="-X main.VERSION=${VERSION}" \
		-o release/$(BINARY)-$(VERSION).linux-armv6.$(GO_VERSION)/$(BINARY) github.com/pusher/oauth2_proxy
	GOOS=windows GOARCH=amd64 go build -ldflags="-X main.VERSION=${VERSION}" \
		-o release/$(BINARY)-$(VERSION).windows-amd64.$(GO_VERSION)/$(BINARY) github.com/pusher/oauth2_proxy
	shasum -a 256 release/$(BINARY)-$(VERSION).darwin-amd64.$(GO_VERSION)/$(BINARY) > release/$(BINARY)-$(VERSION).darwin-amd64-sha256sum.txt
	shasum -a 256 release/$(BINARY)-$(VERSION).linux-amd64.$(GO_VERSION)/$(BINARY) > release/$(BINARY)-$(VERSION).linux-amd64-sha256sum.txt
	shasum -a 256 release/$(BINARY)-$(VERSION).linux-arm64.$(GO_VERSION)/$(BINARY) > release/$(BINARY)-$(VERSION).linux-arm64-sha256sum.txt
	shasum -a 256 release/$(BINARY)-$(VERSION).linux-armv6.$(GO_VERSION)/$(BINARY) > release/$(BINARY)-$(VERSION).linux-armv6-sha256sum.txt
	shasum -a 256 release/$(BINARY)-$(VERSION).windows-amd64.$(GO_VERSION)/$(BINARY) > release/$(BINARY)-$(VERSION).windows-amd64-sha256sum.txt
	tar -C release -czvf release/$(BINARY)-$(VERSION).darwin-amd64.$(GO_VERSION).tar.gz $(BINARY)-$(VERSION).darwin-amd64.$(GO_VERSION)
	tar -C release -czvf release/$(BINARY)-$(VERSION).linux-amd64.$(GO_VERSION).tar.gz $(BINARY)-$(VERSION).linux-amd64.$(GO_VERSION)
	tar -C release -czvf release/$(BINARY)-$(VERSION).linux-arm64.$(GO_VERSION).tar.gz $(BINARY)-$(VERSION).linux-arm64.$(GO_VERSION)
	tar -C release -czvf release/$(BINARY)-$(VERSION).linux-armv6.$(GO_VERSION).tar.gz $(BINARY)-$(VERSION).linux-armv6.$(GO_VERSION)
	tar -C release -czvf release/$(BINARY)-$(VERSION).windows-amd64.$(GO_VERSION).tar.gz $(BINARY)-$(VERSION).windows-amd64.$(GO_VERSION)
