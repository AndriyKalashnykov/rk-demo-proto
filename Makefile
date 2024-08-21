.PHONY: all
all: fmt deps buf test build

.PHONY: fmt
fmt:
	@echo "[fmt] Format go project..."
	@gofmt -s -w . 2>&1
	@echo "------------------------------------[Done]"

.PHONY: deps
deps:
	@echo "[deps] Running deps..."
	@go install github.com/bufbuild/buf/cmd/buf@latest
	@go install github.com/grpc-ecosystem/grpc-gateway/v2/protoc-gen-grpc-gateway@latest
	@go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest
	@go install google.golang.org/protobuf/cmd/protoc-gen-go@latest
	@go install github.com/grpc-ecosystem/grpc-gateway/v2/protoc-gen-openapiv2@latest

.PHONY: buf
buf:
	@echo "[buf] Running buf..."
	@buf generate --path api/v1

.PHONY: test
test: deps buf
	go test ./.

.PHONY: build
build: deps buf test
	@echo "[build] Running build..."
	@go build

.PHONY: run
run: fmt build
	@go run main.go

.PHONY: update
update:
	@echo "[run] Running..."
	@go get -u; go mod tidy
