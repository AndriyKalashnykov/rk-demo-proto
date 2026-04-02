# Phase 4: rk-boot/rk-grpc Migration Checklist

## Background

`rk-boot/v2` and `rk-grpc/v2` are effectively abandoned:
- **rk-boot**: last release 2024-04-09 (24 months ago), last commit 2024-10-04
- **rk-grpc**: last release and last commit 2023-10-31 (30 months ago)
- Single maintainer (`rookie-ninja`) with no recent GitHub activity
- 575 stars (rk-boot), 81 stars (rk-grpc) — small community
- No deprecation notice, but all signals point to abandonment

### What rk-boot/rk-grpc provides

rk-boot is a YAML-driven bootstrapper that wires together:

1. **gRPC server** with grpc-gateway (REST) — `boot.yaml` config
2. **Swagger UI** — auto-served from generated OpenAPI specs
3. **Prometheus metrics** — `/metrics` endpoint with middleware
4. **Structured logging** — request/response logging middleware
5. **Common service endpoints** — health check, readiness, info
6. **Middleware chain** — logging, metrics, auth, rate limiting via YAML

### Migration target

Replace rk-boot/rk-grpc with direct usage of well-maintained libraries:
- **grpc-go** (v1.79+, 22K stars, daily commits) — already a transitive dep
- **grpc-gateway** (v2.28+, 20K stars, active) — already a transitive dep
- **prometheus/client_golang** — standard Prometheus client
- **slog** (stdlib) or **zap** — structured logging

---

## Pre-Migration Research

- [ ] **Read rk-boot source code** to understand the full middleware chain
  - `main.go` registers the gRPC server via rk-boot
  - `boot.yaml` configures all middleware and services
  - Map each `boot.yaml` section to its underlying library

- [ ] **Inventory all rk-boot features used** in this project:
  - [ ] gRPC server setup (port, TLS)
  - [ ] grpc-gateway REST endpoints
  - [ ] Swagger UI serving
  - [ ] Prometheus metrics middleware
  - [ ] Request logging middleware
  - [ ] Common service endpoints (health, readiness)
  - [ ] Any other middleware (auth, rate limiting, CORS)

- [ ] **Find replacement libraries** for each feature:
  | Feature | rk-boot provides | Replacement |
  |---------|-----------------|-------------|
  | gRPC server | Boot config | `google.golang.org/grpc` (direct) |
  | grpc-gateway | Boot config | `grpc-ecosystem/grpc-gateway/v2` (direct) |
  | Swagger UI | Auto-served | `swaggo/swag` + `swaggo/http-swagger` or static file serving |
  | Prometheus | Middleware | `prometheus/client_golang` + `grpc-ecosystem/go-grpc-middleware` |
  | Logging | Middleware | `log/slog` (stdlib) or `uber-go/zap` |
  | Health check | Common service | `grpc-health-v1` (standard gRPC health protocol) |
  | Readiness | Common service | Custom HTTP handler on management port |

- [ ] **Study reference implementations** for direct grpc-go + grpc-gateway setup:
  - grpc-gateway official examples: https://github.com/grpc-ecosystem/grpc-gateway/tree/main/examples
  - go-grpc-middleware v2: https://github.com/grpc-ecosystem/go-grpc-middleware

## Implementation

### Step 1: Scaffold the new server (no rk-boot)

- [ ] Create `internal/server/grpc.go` — direct gRPC server setup
  ```go
  // Register gRPC services
  // Configure TLS if needed
  // Add interceptors (logging, metrics)
  ```

- [ ] Create `internal/server/gateway.go` — grpc-gateway HTTP mux
  ```go
  // Register gateway handlers
  // Mount Swagger UI
  // Mount Prometheus /metrics
  // Mount health/readiness endpoints
  ```

- [ ] Create `internal/server/server.go` — combined server orchestration
  ```go
  // Start gRPC on one port, HTTP on another (or use cmux for single port)
  // Graceful shutdown with signal handling
  ```

### Step 2: Migrate middleware

- [ ] **Prometheus metrics**
  - Add `prometheus/client_golang` dependency
  - Create gRPC server interceptor for request metrics
  - Expose `/metrics` on the HTTP gateway
  - Verify same metric names as rk-boot produced (or document the change)

- [ ] **Request logging**
  - Add `log/slog` structured logging (stdlib, zero deps)
  - Create gRPC interceptor for request/response logging
  - Match log format from rk-boot or adopt standard JSON format

- [ ] **Health check**
  - Implement `grpc.health.v1.Health` service (standard gRPC health)
  - Add `/healthz` and `/readyz` HTTP endpoints on gateway

### Step 3: Migrate configuration

- [ ] **Replace `boot.yaml`** with either:
  - Environment variables (12-factor app style)
  - A simpler YAML config with `gopkg.in/yaml.v3` or `koanf`
  - CLI flags with `flag` package
  - Decide which approach fits your deployment model

- [ ] **Port mapping**:
  - Current: single port 8080 (gRPC + REST via rk-boot)
  - Target: decide on single-port (cmux) or dual-port (gRPC:8080, HTTP:8081)

### Step 4: Migrate Swagger UI

- [ ] **Option A**: Static file serving
  - Copy generated OpenAPI spec to `api/gen/v1/`
  - Serve Swagger UI static files at `/swagger/`
  - Use `swaggo/http-swagger` or embed swagger-ui dist

- [ ] **Option B**: Drop Swagger UI from the binary
  - Serve OpenAPI spec as JSON at `/openapi.json`
  - Users access Swagger Editor or Swagger UI externally
  - Simpler binary, fewer dependencies

### Step 5: Update dependencies

- [ ] Remove from `go.mod`:
  - `github.com/rookie-ninja/rk-boot/v2`
  - `github.com/rookie-ninja/rk-grpc/v2`
  - All `rk-entry`, `rk-common`, `rk-prom`, `rk-logger` transitive deps

- [ ] Add to `go.mod` (if not already transitive):
  - `github.com/prometheus/client_golang`
  - `github.com/grpc-ecosystem/go-grpc-middleware/v2` (optional, for interceptors)

- [ ] Run `go mod tidy` to clean up

### Step 6: Update main.go

- [ ] Replace rk-boot initialization with direct server setup
- [ ] Remove `boot.yaml` (or repurpose as app config)
- [ ] Verify the Greeter service works via both gRPC and REST

### Step 7: Update tests

- [ ] Update any tests that depend on rk-boot server startup
- [ ] Add integration test for gRPC endpoint
- [ ] Add integration test for REST endpoint (grpc-gateway)
- [ ] Add test for `/metrics` endpoint
- [ ] Add test for health check endpoint

### Step 8: Update protobuf generation

- [ ] Verify `buf generate` still works (no rk-boot-specific plugins)
- [ ] Verify gateway mapping (`gw_mapping.yaml`) still applies
- [ ] Verify OpenAPI spec generation still works

## Post-Migration Verification

- [ ] `make ci` passes (format, static-check, test, build)
- [ ] `make ci-run` passes (GitHub Actions via act)
- [ ] `make run` starts the server successfully
- [ ] gRPC endpoint responds: `grpcurl -plaintext localhost:8080 ...`
- [ ] REST endpoint responds: `curl http://localhost:8080/v1/greeter?name=World`
- [ ] Swagger UI accessible (if kept): `curl http://localhost:8080/swagger/`
- [ ] Prometheus metrics available: `curl http://localhost:8080/metrics`
- [ ] Health check responds: `curl http://localhost:8080/healthz`
- [ ] No rk-boot or rk-grpc imports remain: `grep -r "rookie-ninja" .`
- [ ] `go mod tidy` produces no changes
- [ ] Binary size comparison (should decrease — fewer deps)

## Risk Mitigation

- [ ] **Create a feature branch** for the migration — do not merge to main until fully verified
- [ ] **Keep boot.yaml as reference** during migration (delete in final cleanup commit)
- [ ] **Compare HTTP response formats** before and after — rk-boot may add custom headers or envelope the response differently
- [ ] **Compare Prometheus metric names** — dashboards may break if metric names change
- [ ] **Test with existing clients** if any consumers depend on specific response formats

## Estimated Effort

| Step | Effort | Risk |
|------|--------|------|
| Research & scaffold | 2-4 hours | Low |
| Migrate middleware (metrics, logging) | 2-3 hours | Medium |
| Migrate configuration | 1-2 hours | Low |
| Migrate Swagger UI | 1-2 hours | Low |
| Update dependencies & main.go | 1 hour | Low |
| Testing & verification | 2-3 hours | Medium |
| **Total** | **~1-2 days** | **Medium** |

The main risk is discovering rk-boot behaviors that aren't immediately visible (custom response wrapping, middleware ordering, error format). The research step mitigates this by mapping all features before writing code.
