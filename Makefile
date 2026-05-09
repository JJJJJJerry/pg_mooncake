PG_VERSION ?= pg18
VERBOSE ?= 0
DEBUG ?= 1

export PG_CONFIG := $(shell cargo pgrx info pg-config $(PG_VERSION))

ifeq ($(DEBUG), 1)
	CARGO_FLAGS =
	DUCKDB_FLAGS = DUCKDB_BUILD=Debug
else
	CARGO_FLAGS = --release
	DUCKDB_FLAGS =
endif

.PHONY: help clean duckdb_mooncake format install package pg_duckdb run test test-verbose test-debug test-trace

help:
	@echo "Usage: make <COMMAND> [OPTIONS]"
	@echo ""
	@echo "Commands:"
	@echo "  run           Build and run pg_mooncake for development"
	@echo "  install       Build and install pg_mooncake"
	@echo "  pg_duckdb     Build and install pg_duckdb"
	@echo "  package       Build an installation package for release"
	@echo "  format        Format the codebase"
	@echo "  test          Run all tests (default verbosity)"
	@echo "  test-verbose  Run tests with INFO level logs (-v)"
	@echo "  test-debug    Run tests with DEBUG level logs (-vv)"
	@echo "  test-trace    Run tests with TRACE level logs (-vvv)"
	@echo "  clean         Remove build artifacts"
	@echo ""
	@echo "Options:"
	@echo "  PG_VERSION    pg14, pg15, pg16, pg17, or pg18 (default: pg16)"
	@echo "  VERBOSE       0-3, controls log verbosity (default: 0)"
	@echo ""
	@echo "Examples:"
	@echo "  make test                    # Run tests with minimal logs"
	@echo "  make test-trace              # Run tests with full trace logs"
	@echo "  make test VERBOSE=3          # Same as test-trace"

clean:
	@cargo clean

duckdb_mooncake:
	@$(MAKE) -C duckdb_mooncake GEN=ninja OVERRIDE_GIT_DESCRIBE=v1.4.1

format:
	@cargo fmt
	@cargo clippy

install:
	@cargo pgrx install $(CARGO_FLAGS) --pg-config $(PG_CONFIG)

package:
	@cargo pgrx package

pg_duckdb:
	@$(MAKE) -C pg_duckdb install $(DUCKDB_FLAGS) PG_LDFLAGS="-L/opt/homebrew/opt/lz4/lib" -j$(shell sysctl -n hw.ncpu)

run: pg_duckdb
	@cargo pgrx run

test:
	@cargo pgrx regress --resetdb \
		--postgresql-conf shared_preload_libraries='pg_duckdb,pg_mooncake' \
		--postgresql-conf duckdb.allow_unsigned_extensions=true \
		--postgresql-conf wal_level=logical \
		$(shell printf '%0.s-v' $$(seq 1 $(VERBOSE)))

test-verbose:
	@$(MAKE) test VERBOSE=1

test-debug:
	@$(MAKE) test VERBOSE=2

test-trace:
	@$(MAKE) test VERBOSE=3
