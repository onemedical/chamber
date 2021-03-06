RELEASE := $(GOPATH)/bin/github-release
VERSION := $(shell git describe --tags --always --dirty="-dev")
LDFLAGS := -ldflags='-X "main.Version=$(VERSION)"'

release: gh-release clean dist sync
	$(RELEASE) release \
	--security-token $$GH_LOGIN \
	--user segmentio \
	--repo chamber \
	--tag $(VERSION) \
	--name $(VERSION)

	$(RELEASE) upload \
	--security-token $$GH_LOGIN \
	--user segmentio \
	--repo chamber \
	--tag $(VERSION) \
	--name chamber-$(VERSION)-darwin-amd64 \
	--file dist/chamber-$(VERSION)-darwin-amd64

	$(RELEASE) upload \
	--security-token $$GH_LOGIN \
	--user segmentio \
	--repo chamber \
	--tag $(VERSION) \
	--name chamber-$(VERSION)-linux-amd64 \
	--file dist/chamber-$(VERSION)-linux-amd64

clean:
	rm -rf ./dist

dist:
	mkdir -p releases/$(VERSION)
	GOOS=darwin GOARCH=amd64 CGO_ENABLED=0 go build $(LDFLAGS) -o releases/$(VERSION)/chamber-darwin-amd64
	GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go build $(LDFLAGS) -o releases/$(VERSION)/chamber-linux-amd64

gh-release:
	go get -u github.com/aktau/github-release

govendor:
	go get -u github.com/kardianos/govendor

sync: govendor
	govendor sync

release-binary: sync dist
ifndef GITHUB_TOKEN
	@echo "Please set GITHUB_TOKEN in the environment"
	exit 1
endif
	# These commands are not idempotent, so ignore failures if an upload repeats
	$(RELEASE) release --user onemedical --repo chamber --tag $(VERSION) || true
	$(RELEASE) upload --user onemedical --repo chamber --tag $(VERSION) --name chamber-linux-amd64 --file releases/$(VERSION)/chamber-linux-amd64 || true
	$(RELEASE) upload --user onemedical --repo chamber --tag $(VERSION) --name chamber-darwin-amd64 --file releases/$(VERSION)/chamber-darwin-amd64 || true
