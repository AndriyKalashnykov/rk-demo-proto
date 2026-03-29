# CLAUDE.md

## Project Overview

Go gRPC microservice demo using [rk-boot](https://github.com/rookie-ninja/rk-boot) bootstrapper with [grpc-gateway](https://github.com/grpc-ecosystem/grpc-gateway). Exposes a simple `Greeter` service via both gRPC and REST (grpc-gateway), with built-in Swagger UI, Prometheus metrics, and logging middleware.

## Tech Stack

- **Language**: Go
- **Framework**: rk-boot v2 + rk-grpc v2
- **Protocol**: gRPC with grpc-gateway (REST)
- **Code Generation**: buf CLI (protobuf/gRPC stubs)
- **CI**: GitHub Actions

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

## Build & Development

```bash
make help      # List all available targets
make deps      # Install pinned protobuf/gRPC toolchain
make buf       # Generate protobuf/gRPC stubs
make fmt       # Format Go source files
make test      # Run unit tests (excludes generated code)
make build     # Full build (deps + buf + test + binary)
make run       # Format, build, and run the application
make ci        # Full CI pipeline (fmt, deps, buf, test, build)
make clean     # Remove generated files and build artifacts
make update    # Update Go dependencies
make release   # Tag a semver release (usage: make release V=1.2.3)
```

## Key Conventions

- Generated code lives in `api/gen/` and should never be edited manually
- Protobuf definitions live in `api/v1/`
- REST endpoints are mapped via `api/v1/gw_mapping.yaml`
- The application listens on port 8080 by default (configured in `boot.yaml`)
- Dependency versions are pinned in the Makefile

## Skills

Use the following skills when working on related files:

| File(s) | Skill |
|---------|-------|
| `Makefile` | `/makefile` |
| `renovate.json` | `/renovate` |
| `README.md` | `/readme` |
| `.github/workflows/*.yml` | `/ci-workflow` |

When spawning subagents, always pass conventions from the respective skill into the agent's prompt.
