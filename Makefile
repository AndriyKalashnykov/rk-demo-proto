.DEFAULT_GOAL := help

# ── Pinned dependency versions ────────────────────────────────────────
BUF_VERSION          := v1.67.0
PROTOC_GEN_GO_VER    := v1.36.11
PROTOC_GEN_GRPC_VER  := v1.6.1
GRPC_GW_VERSION      := v2.28.0
GOLANGCI_VERSION     := 2.11.4
GOVULNCHECK_VERSION  := v1.1.4
GITLEAKS_VERSION     := 8.30.1
ACT_VERSION          := 0.2.87
NVM_VERSION          := 0.40.4
NODE_VERSION         := 22
GVM_SHA              := dd652539fa4b771840846f8319fad303c7d0a8d2 # v1.0.22

# ── Derived ───────────────────────────────────────────────────────────
GO_VERSION  := $(shell grep -oP '^go \K[0-9.]+' go.mod)
MODULE      := $(shell go list -m 2>/dev/null || grep '^module' go.mod | awk '{print $$2}')
BIN_NAME    := $(notdir $(MODULE))

# ── Go version manager (gvm) ─────────────────────────────────────────
# In CI, actions/setup-go provides Go directly — gvm is not needed.
# Locally, gvm sets GOROOT/GOPATH/PATH in a subshell.
# go-exec detects which environment we're in and wraps commands accordingly.
HAS_GVM := $(shell [ -s "$$HOME/.gvm/scripts/gvm" ] && echo true || echo false)
define go-exec
$(if $(filter true,$(HAS_GVM)),bash -c '. $$GVM_ROOT/scripts/gvm && gvm use go$(GO_VERSION) >/dev/null && $(1)',bash -c '$(1)')
endef

#help: @ List available tasks
help:
	@echo "Usage: make COMMAND"
	@echo "Commands :"
	@grep -E '[a-zA-Z\.\-]+:.*?@ .*$$' $(MAKEFILE_LIST)| tr -d '#' | awk 'BEGIN {FS = ":.*?@ "}; {printf "\033[32m%-22s\033[0m - %s\n", $$1, $$2}'

#format: @ Format Go source files
format: deps
	@echo "[format] Formatting Go project..."
	@$(call go-exec,gofmt -s -w . 2>&1)
	@echo "------------------------------------[Done]"

#fmt: @ Format Go source files (alias for format)
fmt: format

#deps: @ Install pinned protobuf/gRPC toolchain
deps:
	@# Install gvm if not present (local development only, CI uses actions/setup-go)
	@if [ -z "$$CI" ] && [ ! -s "$$HOME/.gvm/scripts/gvm" ]; then \
		echo "Installing gvm (Go Version Manager)..."; \
		curl -s -S -L https://raw.githubusercontent.com/moovweb/gvm/$(GVM_SHA)/binscripts/gvm-installer | bash -s $(GVM_SHA); \
		echo ""; \
		echo "gvm installed. Please restart your shell or run:"; \
		echo "  source $$HOME/.gvm/scripts/gvm"; \
		echo "Then re-run 'make deps' to install Go $(GO_VERSION) via gvm."; \
		exit 0; \
	fi
	@if [ "$(HAS_GVM)" = "true" ]; then \
		bash -c '. $$GVM_ROOT/scripts/gvm && gvm list' 2>/dev/null | grep -q "go$(GO_VERSION)" || { \
			echo "Installing Go $(GO_VERSION) via gvm..."; \
			bash -c '. $$GVM_ROOT/scripts/gvm && gvm install go$(GO_VERSION) -B'; \
		}; \
	else \
		command -v go >/dev/null 2>&1 || { echo "Error: Go required. Install gvm from https://github.com/moovweb/gvm or Go from https://go.dev/dl/"; exit 1; }; \
	fi
	@$(call go-exec,command -v buf)            >/dev/null 2>&1 || $(call go-exec,go install github.com/bufbuild/buf/cmd/buf@$(BUF_VERSION))
	@$(call go-exec,command -v protoc-gen-go)  >/dev/null 2>&1 || $(call go-exec,go install google.golang.org/protobuf/cmd/protoc-gen-go@$(PROTOC_GEN_GO_VER))
	@$(call go-exec,command -v protoc-gen-go-grpc)   >/dev/null 2>&1 || $(call go-exec,go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@$(PROTOC_GEN_GRPC_VER))
	@$(call go-exec,command -v protoc-gen-grpc-gateway) >/dev/null 2>&1 || $(call go-exec,go install github.com/grpc-ecosystem/grpc-gateway/v2/protoc-gen-grpc-gateway@$(GRPC_GW_VERSION))
	@$(call go-exec,command -v protoc-gen-openapiv2)    >/dev/null 2>&1 || $(call go-exec,go install github.com/grpc-ecosystem/grpc-gateway/v2/protoc-gen-openapiv2@$(GRPC_GW_VERSION))
	@$(call go-exec,command -v golangci-lint)  >/dev/null 2>&1 || $(call go-exec,go install github.com/golangci/golangci-lint/v2/cmd/golangci-lint@v$(GOLANGCI_VERSION))
	@$(call go-exec,command -v govulncheck)   >/dev/null 2>&1 || $(call go-exec,go install golang.org/x/vuln/cmd/govulncheck@$(GOVULNCHECK_VERSION))
	@command -v gitleaks >/dev/null 2>&1 || { echo "Installing gitleaks $(GITLEAKS_VERSION)..."; \
		curl -sSfL https://github.com/gitleaks/gitleaks/releases/download/v$(GITLEAKS_VERSION)/gitleaks_$(GITLEAKS_VERSION)_linux_x64.tar.gz | \
		sudo tar xz -C /usr/local/bin gitleaks; \
	}

#deps-check: @ Show required Go version and tool status
deps-check:
	@echo "Go version required: $(GO_VERSION)"
	@if [ "$(HAS_GVM)" = "true" ]; then \
		bash -c '. $$GVM_ROOT/scripts/gvm && gvm list'; \
	else \
		echo "gvm not installed — install from https://github.com/moovweb/gvm"; \
		command -v go >/dev/null 2>&1 && go version || echo "go: NOT installed"; \
	fi

#deps-act: @ Install act for local CI
deps-act: deps
	@command -v act >/dev/null 2>&1 || { echo "Installing act $(ACT_VERSION)..."; \
		curl -sSfL https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash -s -- -b /usr/local/bin v$(ACT_VERSION); \
	}

#deps-renovate: @ Install nvm and npm for Renovate
deps-renovate:
	@command -v node >/dev/null 2>&1 || { \
		echo "Installing nvm $(NVM_VERSION) + Node $(NODE_VERSION)..."; \
		curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v$(NVM_VERSION)/install.sh | bash; \
		export NVM_DIR="$$HOME/.nvm"; \
		[ -s "$$NVM_DIR/nvm.sh" ] && . "$$NVM_DIR/nvm.sh"; \
		nvm install $(NODE_VERSION); \
	}

#buf: @ Generate protobuf/gRPC stubs with buf
buf: deps
	@echo "[buf] Running buf generate..."
	@$(call go-exec,buf generate --path api/v1)
	@echo "------------------------------------[Done]"

#lint: @ Run golangci-lint (excludes generated code)
lint: deps buf
	@echo "[lint] Running golangci-lint..."
	@$(call go-exec,golangci-lint run .)
	@echo "------------------------------------[Done]"

#vulncheck: @ Run Go vulnerability scanner
vulncheck: deps buf
	@echo "[vulncheck] Running govulncheck..."
	@$(call go-exec,govulncheck $$(go list ./... | grep -v /api/gen/))
	@echo "------------------------------------[Done]"

#secrets: @ Scan for leaked secrets
secrets: deps
	@echo "[secrets] Running gitleaks..."
	@gitleaks detect --source . --no-banner -v
	@echo "------------------------------------[Done]"

#static-check: @ Run all static analysis (lint, vulncheck, secrets)
static-check: lint vulncheck secrets
	@echo "[static-check] All static checks passed."

#test: @ Run unit tests
test: deps buf
	@echo "[test] Running tests..."
	@$(call go-exec,go test -race $$(go list ./... | grep -v /api/gen/) -v)
	@echo "------------------------------------[Done]"

#build: @ Build the Go binary
build: deps buf
	@echo "[build] Building $(BIN_NAME)..."
	@$(call go-exec,go build -o $(BIN_NAME) .)
	@echo "------------------------------------[Done]"

#run: @ Format, build, and run the application
run: format build
	@$(call go-exec,go run main.go)

#update: @ Update Go dependencies
update: deps
	@echo "[update] Updating Go dependencies..."
	@$(call go-exec,go get -u && go mod tidy)
	@echo "------------------------------------[Done]"

#clean: @ Remove generated files and build artifacts
clean:
	@echo "[clean] Removing generated files and build artifacts..."
	@rm -rf api/gen
	@rm -f $(BIN_NAME)
	@echo "------------------------------------[Done]"

#ci: @ Run full CI pipeline (format, static-check, test, build)
ci: format static-check test build
	@echo "[ci] All checks passed."

#ci-run: @ Run GitHub Actions workflow locally using act
ci-run: deps-act
	@act push --container-architecture linux/amd64 \
		--artifact-server-path /tmp/act-artifacts

#release: @ Tag a semver release (usage: make release V=1.2.3)
release: deps
	@if [ -z "$(V)" ]; then \
		echo "ERROR: version not set. Usage: make release V=1.2.3"; \
		exit 1; \
	fi
	@echo "$(V)" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$$' || \
		{ echo "ERROR: '$(V)' is not valid semver (expected X.Y.Z)"; exit 1; }
	@echo -n "Create and push tag v$(V)? [y/N] " && read ans && [ "$${ans:-N}" = y ] || { echo "Aborted."; exit 1; }
	@echo "[release] Tagging v$(V)..."
	@git tag -a "v$(V)" -m "Release v$(V)"
	@git push origin "v$(V)"
	@echo "------------------------------------[Done]"

#renovate-validate: @ Validate Renovate configuration
renovate-validate: deps-renovate
	@npx --yes renovate --platform=local

.PHONY: help format fmt deps deps-check deps-act deps-renovate buf lint \
	vulncheck secrets static-check test build run update clean ci ci-run \
	release renovate-validate
