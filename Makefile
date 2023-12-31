.PHONY: all
all: fmt buf deps build

.PHONY: fmt
fmt:
	@echo "[fmt] Format go project..."
	@gofmt -s -w . 2>&1
	@echo "------------------------------------[Done]"

.PHONY: buf
buf:
	@echo "[buf] Running buf..."
	@buf generate --path api/v1

.PHONY: deps
deps:
	@echo "[deps] Running deps..."
	@go install google.golang.org/protobuf/cmd/protoc-gen-go
	@go install github.com/grpc-ecosystem/grpc-gateway/v2/protoc-gen-openapiv2

.PHONY: build
build:
	@echo "[build] Running build..."
	@go build

.PHONY: run
run: fmt build
	@go run main.go

.PHONY: update
update:
	@echo "[run] Running..."
	@go get -u; go mod tidy
