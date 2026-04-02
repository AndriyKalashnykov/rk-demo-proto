[![CI](https://github.com/AndriyKalashnykov/rk-demo-proto/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/AndriyKalashnykov/rk-demo-proto/actions/workflows/ci.yml)
[![Hits](https://hits.sh/github.com/AndriyKalashnykov/rk-demo-proto.svg?view=today-total&style=plastic)](https://hits.sh/github.com/AndriyKalashnykov/rk-demo-proto/)
[![License: MIT](https://img.shields.io/badge/License-MIT-brightgreen.svg)](https://opensource.org/licenses/MIT)
[![Renovate enabled](https://img.shields.io/badge/renovate-enabled-brightgreen.svg)](https://app.renovatebot.com/dashboard#github/AndriyKalashnykov/rk-demo-proto)

# rk-demo-proto

Go gRPC microservice demo using [rk-boot](https://github.com/rookie-ninja/rk-boot) bootstrapper with [grpc-gateway](https://github.com/grpc-ecosystem/grpc-gateway). Exposes a `Greeter` service via both gRPC and REST, with built-in Swagger UI, Prometheus metrics, and logging middleware.

## Quick Start

```bash
make deps      # install protobuf/gRPC toolchain
make test      # run unit tests
make run       # format, build, and run the application
```

## Prerequisites

| Tool | Version | Purpose |
|------|---------|---------|
| [Go](https://go.dev/dl/) | 1.26+ | Language runtime and compiler |
| [GNU Make](https://www.gnu.org/software/make/) | 3.81+ | Build orchestration |
| [buf CLI](https://buf.build/docs/installation) | 1.66+ | Protobuf code generation |
| [Git](https://git-scm.com/) | 2.0+ | Version control |
| [gvm](https://github.com/moovweb/gvm) | latest | Go version management (optional, auto-installed by `make deps`) |
| [act](https://github.com/nektos/act) | 0.2+ | Run GitHub Actions locally (optional) |

Install all required dependencies:

```bash
make deps
```

## Available Make Targets

Run `make help` to see all available targets.

### Build & Run

| Target | Description |
|--------|-------------|
| `make help` | List available tasks |
| `make deps` | Install pinned protobuf/gRPC toolchain |
| `make buf` | Generate protobuf/gRPC stubs with buf |
| `make format` | Format Go source files |
| `make fmt` | Format Go source files (alias for format) |
| `make lint` | Run golangci-lint (excludes generated code) |
| `make vulncheck` | Run Go vulnerability scanner |
| `make secrets` | Scan for leaked secrets |
| `make static-check` | Run all static analysis (lint, vulncheck, secrets) |
| `make test` | Run unit tests |
| `make build` | Build the Go binary |
| `make run` | Format, build, and run the application |
| `make update` | Update Go dependencies |
| `make clean` | Remove generated files and build artifacts |

### CI

| Target | Description |
|--------|-------------|
| `make ci` | Run full CI pipeline (format, static-check, test, build) |
| `make ci-run` | Run GitHub Actions workflow locally using [act](https://github.com/nektos/act) |

### Utilities

| Target | Description |
|--------|-------------|
| `make deps-check` | Show required Go version and tool status |
| `make deps-act` | Install act for local CI |
| `make deps-renovate` | Install nvm and npm for Renovate |
| `make release V=x.y.z` | Tag a semver release (usage: make release V=1.2.3) |
| `make renovate-validate` | Validate Renovate configuration |

## CI/CD

GitHub Actions runs on every push to `main`, tags `v*`, and pull requests.

| Job | Triggers | Steps |
|-----|----------|-------|
| **static-check** | push (main), tags (v*), PR | Checkout, Setup Go, Static check (lint, vulncheck, secrets) |
| **build** | after static-check passes | Checkout, Setup Go, Build |
| **test** | after static-check passes | Checkout, Setup Go, Test |
| **cleanup** | weekly schedule (Sunday) | Delete old workflow runs |

[Renovate](https://docs.renovatebot.com/) keeps dependencies up to date with platform automerge enabled.

## Project Structure

```
main.go              # Application entry point (registers gRPC server)
boot.yaml            # rk-boot configuration (port, middleware, Swagger, Prometheus)
buf.yaml             # buf module definition
buf.gen.yaml         # buf code generation config
api/v1/              # Protobuf definitions and gw_mapping
api/gen/v1/          # Generated Go code (do not edit)
third-party/         # Third-party proto dependencies (googleapis)
Makefile             # Build, test, CI targets
.github/workflows/   # CI and cleanup workflows
```
