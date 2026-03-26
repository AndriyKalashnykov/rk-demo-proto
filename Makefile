.DEFAULT_GOAL := help

# ── Pinned dependency versions ────────────────────────────────────────
BUF_VERSION          := v1.66.1
PROTOC_GEN_GO_VER    := v1.36.11
PROTOC_GEN_GRPC_VER  := v1.6.1
GRPC_GW_VERSION      := v2.28.0

# ── Derived ───────────────────────────────────────────────────────────
MODULE   := $(shell go list -m)
BIN_NAME := $(notdir $(MODULE))

.PHONY: help fmt deps buf test build run update clean ci release

#help: @ List available tasks
help:
	@echo "Usage: make COMMAND"
	@echo "Commands :"
	@grep -E '[a-zA-Z\.\-]+:.*?@ .*$$' $(MAKEFILE_LIST)| tr -d '#' | awk 'BEGIN {FS = ":.*?@ "}; {printf "\033[32m%-20s\033[0m - %s\n", $$1, $$2}'

#fmt: @ Format Go source files
fmt:
	@echo "[fmt] Formatting Go project..."
	@gofmt -s -w . 2>&1
	@echo "------------------------------------[Done]"

#deps: @ Install pinned protobuf/gRPC toolchain
deps:
	@command -v buf            >/dev/null 2>&1 || go install github.com/bufbuild/buf/cmd/buf@$(BUF_VERSION)
	@command -v protoc-gen-go  >/dev/null 2>&1 || go install google.golang.org/protobuf/cmd/protoc-gen-go@$(PROTOC_GEN_GO_VER)
	@command -v protoc-gen-go-grpc   >/dev/null 2>&1 || go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@$(PROTOC_GEN_GRPC_VER)
	@command -v protoc-gen-grpc-gateway >/dev/null 2>&1 || go install github.com/grpc-ecosystem/grpc-gateway/v2/protoc-gen-grpc-gateway@$(GRPC_GW_VERSION)
	@command -v protoc-gen-openapiv2    >/dev/null 2>&1 || go install github.com/grpc-ecosystem/grpc-gateway/v2/protoc-gen-openapiv2@$(GRPC_GW_VERSION)

#buf: @ Generate protobuf/gRPC stubs with buf
buf:
	@echo "[buf] Running buf generate..."
	@buf generate --path api/v1
	@echo "------------------------------------[Done]"

#test: @ Run unit tests
test: deps buf
	@echo "[test] Running tests..."
	@go test ./...
	@echo "------------------------------------[Done]"

#build: @ Build the Go binary
build: deps buf test
	@echo "[build] Building $(BIN_NAME)..."
	@go build -o $(BIN_NAME) .
	@echo "------------------------------------[Done]"

#run: @ Format, build, and run the application
run: fmt build
	@go run main.go

#update: @ Update Go dependencies
update:
	@echo "[update] Updating Go dependencies..."
	@go get -u
	@go mod tidy
	@echo "------------------------------------[Done]"

#clean: @ Remove generated files and build artifacts
clean:
	@echo "[clean] Removing generated files and build artifacts..."
	@rm -rf api/gen
	@rm -f $(BIN_NAME)
	@echo "------------------------------------[Done]"

#ci: @ Run full CI pipeline (fmt, deps, buf, test, build)
ci: fmt deps buf test build
	@echo "[ci] All checks passed."

#release: @ Tag a semver release (usage: make release V=1.2.3)
release:
	@if [ -z "$(V)" ]; then \
		echo "ERROR: version not set. Usage: make release V=1.2.3"; \
		exit 1; \
	fi
	@echo "$(V)" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$$' || \
		{ echo "ERROR: '$(V)' is not valid semver (expected X.Y.Z)"; exit 1; }
	@echo "[release] Tagging v$(V)..."
	@git tag -a "v$(V)" -m "Release v$(V)"
	@git push origin "v$(V)"
	@echo "------------------------------------[Done]"
