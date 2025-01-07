# Conditionally include .env file if not running in CI/CD environment
ifndef GITHUB_ACTIONS
  -include .env
endif

# ===================== PROFILES ===================== #

# aave base profiles
AAVE_BASE_PROFILES_KEY_MAP = aave_acl=$(AAVE_ACL_PRIVATE_KEY) \
                 aave_config=$(AAVE_CONFIG_PRIVATE_KEY) \
                 aave_math=$(AAVE_MATH_PRIVATE_KEY) \
				 aave_rate=$(AAVE_RATE_PRIVATE_KEY) \
                 aave_oracle=$(AAVE_ORACLE_PRIVATE_KEY) \
                 aave_pool=$(AAVE_POOL_PRIVATE_KEY) \
                 a_tokens=$(A_TOKENS_PRIVATE_KEY) \
                 underlying_tokens=$(UNDERLYING_TOKENS_PRIVATE_KEY) \
                 variable_tokens=$(VARIABLE_TOKENS_PRIVATE_KEY) \
                 aave_large_packages=$(AAVE_LARGE_PACKAGES_PRIVATE_KEY) \
                 aave_data=$(AAVE_DATA_PRIVATE_KEY)

ifeq ($(APTOS_NETWORK), local)
  AAVE_PROFILES_KEY_MAP = $(AAVE_BASE_PROFILES_KEY_MAP) data_feeds=$(AAVE_DATA_FEEDS_PRIVATE_KEY) platform=$(AAVE_PLATFORM_PRIVATE_KEY)
else
  AAVE_PROFILES_KEY_MAP = $(AAVE_BASE_PROFILES_KEY_MAP)
endif

AAVE_PROFILES := $(shell echo $(AAVE_PROFILES_KEY_MAP) | tr ' ' '\n' | cut -d '=' -f1)

# test user profiles
TEST_PROFILES_KEY_MAP = test_account_0=$(TEST_ACCOUNT_0_PRIVATE_KEY) \
                      test_account_1=$(TEST_ACCOUNT_1_PRIVATE_KEY) \
                      test_account_2=$(TEST_ACCOUNT_2_PRIVATE_KEY) \
                      test_account_3=$(TEST_ACCOUNT_3_PRIVATE_KEY) \
                      test_account_4=$(TEST_ACCOUNT_4_PRIVATE_KEY) \
                      test_account_5=$(TEST_ACCOUNT_5_PRIVATE_KEY)

TEST_PROFILES := $(shell echo $(TEST_PROFILES_KEY_MAP) | tr ' ' '\n' | cut -d '=' -f1)

# ===================== NAMED ADDRESSES ===================== #

# resource named addresses
AAVE_ORACLE_ADDRESS := $(shell [ -f .aptos/config.yaml ] && yq '.profiles.aave_oracle.account' .aptos/config.yaml || echo "")
LARGE_PACKAGE_ADDRESS := $(shell [ -f .aptos/config.yaml ] && yq '.profiles.aave_large_packages.account' .aptos/config.yaml || echo "")

RESOURCE_NAMED_ADDRESSES := aave_oracle_racc_address=$(shell \
    [ -n "$(AAVE_ORACLE_ADDRESS)" ] && \
    aptos account derive-resource-account-address \
        --address "$(AAVE_ORACLE_ADDRESS)" \
        --seed "AAVE_ORACLE" \
        --seed-encoding "Utf8" | jq -r '.Result' || \
    echo "")

ORACLE_NAMED_ADDRESSES := $(shell \
  if [ -n "$(CHAINLINK_DATA_FEEDS)" ] && [ -n "$(CHAINLINK_PLATFORM)" ]; then \
    echo ", data_feeds=$(CHAINLINK_DATA_FEEDS), platform=$(CHAINLINK_PLATFORM)"; \
  else \
    echo ""; \
  fi)

define AAVE_NAMED_ADDRESSES
$(foreach profile,$(AAVE_PROFILES),$(profile)=$(profile),) \
$(RESOURCE_NAMED_ADDRESSES) \
$(ORACLE_NAMED_ADDRESSES)
endef

# ======================= CLEAN ====================== #

clean-package-%:
	cd ./aave-core/aave-$* && rm -rf build

clean-core:
	cd ./aave-core && rm -rf build

# ===================== CONFIG ===================== #

set-workspace-config:
	aptos config set-global-config \
	--config-type workspace \
	--default-prompt-response yes

init-workspace-config:
	@echo | aptos init \
	--network $(APTOS_NETWORK) \
	--private-key $(DEFAULT_FUNDER_PRIVATE_KEY) \
	--skip-faucet \
	--assume-yes

# ===================== TESTING ===================== #

local-testnet:
	aptos node run-localnet \
	--assume-yes \
	--no-txn-stream \
	--force-restart \
	--faucet-port 8081 \
	--performance

local-testnet-docker:
	aptos node run-localnet \
	--force-restart \
	--performance \
	--with-indexer-api \
	--indexer-api-port 8090 \
	--faucet-port 8081 \
	--use-host-postgres \
	--host-postgres-host "postgres" \
	--host-postgres-port 5432 \
	--host-postgres-password "postgres" \
	--postgres-user "postgres" \
	--postgres-database "indexer" \
	--existing-hasura-url http://hasura:8092

ts-test:
	cd test-suites && \
	@pnpm i && \
	@pnpm run deploy:init-data && \
	@pnpm run deploy:core-operations && \
	@pnpm run test

test-all:
	make test-acl
	make test-config
	make test-math
	make test-rate
	make test-chainlink-platform
	make test-chainlink-data-feeds
	make test-oracle
	make test-pool

# ===================== PROFILES ===================== #

init-profiles:
	@if [ "$(UPGRADE_CONTRACTS)" = "true" ]; then \
		echo "UPGRADE_CONTRACTS is true, using fixed aave profiles"; \
		for profile in $(shell echo $(AAVE_PROFILES_KEY_MAP) | tr ' ' '\n' | cut -d '=' -f 1); do \
			PRIVATE_KEY=$$(echo $(AAVE_PROFILES_KEY_MAP) | tr ' ' '\n' | grep "^$$profile=" | cut -d '=' -f2); \
			echo "Initializing profile: $$profile ..."; \
			echo | aptos init --profile $$profile --network $(APTOS_NETWORK) --assume-yes --skip-faucet --private-key $$PRIVATE_KEY; \
		done; \
	else \
		echo "UPGRADE_CONTRACTS is false, generating new aave profiles ..."; \
		for profile in $(AAVE_PROFILES); do \
			echo "Initializing aave profile: $$profile with random private key"; \
			echo | aptos init --profile $$profile --network $(APTOS_NETWORK) --assume-yes --skip-faucet; \
		done; \
	fi

init-test-profiles:
	@if [ "$(UPGRADE_CONTRACTS)" = "true" ]; then \
		echo "UPGRADE_CONTRACTS is true, using fixed test profiles"; \
		for profile in $(shell echo $(TEST_PROFILES_KEY_MAP) | tr ' ' '\n' | cut -d '=' -f 1); do \
			PRIVATE_KEY=$$(echo $(TEST_PROFILES_KEY_MAP) | tr ' ' '\n' | grep "^$$profile=" | cut -d '=' -f2); \
			echo "Initializing test profile: $$profile ..."; \
			echo | aptos init --profile $$profile --network $(APTOS_NETWORK) --assume-yes --skip-faucet --private-key $$PRIVATE_KEY; \
		done; \
	else \
		echo "UPGRADE_CONTRACTS is false, generating new test profiles ..."; \
		for profile in $(TEST_PROFILES); do \
			echo "Initializing test profile: $$profile with random private key"; \
			echo | aptos init --profile $$profile --network $(APTOS_NETWORK) --assume-yes --skip-faucet; \
		done; \
	fi

fund-profiles:
	@for profile in $(AAVE_PROFILES); do \
		aptos account fund-with-faucet --account $$profile --amount $(DEFAULT_FUND_AMOUNT) --profile $$profile; \
	done

fund-test-profiles:
	@for profile in $(TEST_PROFILES); do \
		aptos account fund-with-faucet --account $$profile --amount $(DEFAULT_FUND_AMOUNT) --profile $$profile; \
	done

top-up-profiles:
	@for profile in $(AAVE_PROFILES); do \
		aptos account transfer --account $$profile --amount $(DEFAULT_FUND_AMOUNT) --assume-yes --private-key $(DEFAULT_FUNDER_PRIVATE_KEY); \
	done

top-up-test-profiles:
	@for profile in $(TEST_PROFILES); do \
		aptos account transfer --account $$profile --amount $(DEFAULT_FUND_AMOUNT) --assume-yes --private-key $(DEFAULT_FUNDER_PRIVATE_KEY); \
	done

# ===================== PACKAGE AAVE-ACL ===================== #

compile-acl:
	cd aave-core && aptos move compile \
	--included-artifacts $(ARTIFACTS_LEVEL) \
	--save-metadata \
	--package-dir "aave-acl" \
	--skip-fetch-latest-git-deps \
	--named-addresses "${AAVE_NAMED_ADDRESSES}"

publish-acl:
	cd aave-core && aptos move publish --assume-yes \
	--package-dir "aave-acl" \
	--included-artifacts $(ARTIFACTS_LEVEL) \
	--sender-account aave_acl \
	--profile aave_acl \
	--skip-fetch-latest-git-deps \
	--named-addresses "${AAVE_NAMED_ADDRESSES}" \
	--gas-unit-price 100 \
	--max-gas 10000

test-acl:
	cd aave-core && aptos move test \
	--ignore-compile-warnings \
	--skip-attribute-checks \
	--package-dir "aave-acl" \
	--skip-fetch-latest-git-deps \
	--named-addresses "${AAVE_NAMED_ADDRESSES}" \
  	--coverage

doc-acl:
	cd aave-core && aptos move document \
	--skip-attribute-checks \
	--package-dir "aave-acl" \
	--named-addresses "${AAVE_NAMED_ADDRESSES}"

fmt-acl:
	aptos move fmt \
	--package-path "aave-core/aave-acl" \
	--config-path ./movefmt.toml \
	--emit-mode "overwrite" \
	-v

# ===================== PACKAGE AAVE-CONFIG ===================== #

compile-config:
	cd aave-core && aptos move compile \
	--included-artifacts $(ARTIFACTS_LEVEL) \
	--save-metadata \
	--package-dir "aave-config" \
	--skip-fetch-latest-git-deps \
	--named-addresses "${AAVE_NAMED_ADDRESSES}"

publish-config:
	cd aave-core && aptos move publish --assume-yes \
	--package-dir "aave-config" \
	--included-artifacts $(ARTIFACTS_LEVEL) \
	--sender-account aave_config \
	--profile aave_config \
	--skip-fetch-latest-git-deps \
	--named-addresses "${AAVE_NAMED_ADDRESSES}" \
	--gas-unit-price 100 \
	--max-gas 50000

test-config:
	cd aave-core && aptos move test \
	--ignore-compile-warnings \
	--skip-attribute-checks \
	--package-dir "aave-config" \
	--skip-fetch-latest-git-deps \
	--named-addresses "${AAVE_NAMED_ADDRESSES}" \
  	--coverage

doc-config:
	cd aave-core && aptos move document \
	--skip-attribute-checks \
	--package-dir "aave-config" \
	--named-addresses "${AAVE_NAMED_ADDRESSES}"

fmt-config:
	aptos move fmt \
	--package-path "aave-core/aave-config" \
	--config-path ./movefmt.toml \
	--emit-mode "overwrite" \
	-v

# ===================== PACKAGE AAVE-LARGE-PACKAGES ===================== #

compile-large-packages:
	cd aave-core && aptos move compile \
	--included-artifacts $(ARTIFACTS_LEVEL) \
	--save-metadata \
	--package-dir "aave-large-packages" \
	--skip-fetch-latest-git-deps \
	--named-addresses "${AAVE_NAMED_ADDRESSES}"

publish-large-packages:
	cd aave-core && aptos move publish --assume-yes \
	--package-dir "aave-large-packages" \
	--included-artifacts $(ARTIFACTS_LEVEL) \
	--sender-account aave_large_packages \
	--profile aave_large_packages \
	--skip-fetch-latest-git-deps \
	--named-addresses "${AAVE_NAMED_ADDRESSES}" \
	--gas-unit-price 100 \
	--max-gas 10000

test-large-packages:
	cd aave-core && aptos move test \
	--ignore-compile-warnings \
	--skip-attribute-checks \
	--package-dir "aave-large-packages" \
	--skip-fetch-latest-git-deps \
	--named-addresses "${AAVE_NAMED_ADDRESSES}" \
  	--coverage

doc-large-packages:
	cd aave-core && aptos move document \
	--skip-attribute-checks \
	--package-dir "aave-large-packages" \
	--named-addresses "${AAVE_NAMED_ADDRESSES}"

fmt-large-packages:
	aptos move fmt \
	--package-path "aave-core/aave-large-packages" \
	--config-path ./movefmt.toml \
	--emit-mode "overwrite" \
	-v

# ===================== PACKAGE AAVE-MATH ===================== #

compile-math:
	cd aave-core && aptos move compile \
	--included-artifacts $(ARTIFACTS_LEVEL) \
	--save-metadata \
	--package-dir "aave-math" \
	--skip-fetch-latest-git-deps \
	--named-addresses "${AAVE_NAMED_ADDRESSES}"

publish-math:
	cd aave-core && aptos move publish --assume-yes \
	--package-dir "aave-math" \
	--included-artifacts $(ARTIFACTS_LEVEL) \
	--sender-account aave_math \
	--profile aave_math \
	--skip-fetch-latest-git-deps \
	--named-addresses "${AAVE_NAMED_ADDRESSES}" \
	--gas-unit-price 100 \
	--max-gas 10000

test-math:
	cd aave-core && aptos move test \
	--ignore-compile-warnings \
	--skip-attribute-checks \
	--package-dir "aave-math" \
	--skip-fetch-latest-git-deps \
	--named-addresses "${AAVE_NAMED_ADDRESSES}" \
  	--coverage

doc-math:
	cd aave-core && aptos move document \
	--skip-attribute-checks \
	--package-dir "aave-math" \
	--named-addresses "${AAVE_NAMED_ADDRESSES}"

fmt-math:
	aptos move fmt \
	--package-path "aave-core/aave-math" \
	--config-path ./movefmt.toml \
	--emit-mode "overwrite" \
	-v

# ===================== PACKAGE AAVE-RATE ===================== #

compile-rate:
	cd aave-core && aptos move compile \
	--included-artifacts $(ARTIFACTS_LEVEL) \
	--save-metadata \
	--package-dir "aave-rate" \
	--skip-fetch-latest-git-deps \
	--named-addresses "${AAVE_NAMED_ADDRESSES}"

publish-rate:
	cd aave-core && aptos move publish --assume-yes \
	--package-dir "aave-rate" \
	--included-artifacts $(ARTIFACTS_LEVEL) \
	--sender-account aave_rate \
	--profile aave_rate \
	--skip-fetch-latest-git-deps \
	--named-addresses "${AAVE_NAMED_ADDRESSES}" \
	--gas-unit-price 100 \
	--max-gas 20000

test-rate:
	cd aave-core && aptos move test \
	--ignore-compile-warnings \
	--skip-attribute-checks \
	--package-dir "aave-rate" \
	--skip-fetch-latest-git-deps \
	--named-addresses "${AAVE_NAMED_ADDRESSES}" \
  	--coverage

doc-rate:
	cd aave-core && aptos move document \
	--skip-attribute-checks \
	--package-dir "aave-rate" \
	--named-addresses "${AAVE_NAMED_ADDRESSES}"

fmt-rate:
	aptos move fmt \
	--package-path "aave-core/aave-rate" \
	--config-path ./movefmt.toml \
	--emit-mode "overwrite" \
	-v

# ===================== PACKAGE AAVE-DATA ===================== #

compile-data:
	cd aave-core && aptos move compile \
	--included-artifacts $(ARTIFACTS_LEVEL) \
	--save-metadata \
	--package-dir "aave-data" \
	--skip-fetch-latest-git-deps \
	--named-addresses "${AAVE_NAMED_ADDRESSES}"

publish-data:
	cd aave-core && aptos move publish --assume-yes \
	--package-dir "aave-data" \
	--included-artifacts $(ARTIFACTS_LEVEL) \
	--sender-account aave_data \
	--profile aave_data \
	--skip-fetch-latest-git-deps \
	--named-addresses "${AAVE_NAMED_ADDRESSES}"

test-data:
	cd aave-core && aptos move test \
	--ignore-compile-warnings \
	--skip-attribute-checks \
	--package-dir "aave-data" \
	--skip-fetch-latest-git-deps \
	--named-addresses "${AAVE_NAMED_ADDRESSES}" \
  	--coverage

fmt-data:
	aptos move fmt \
	--package-path "aave-core/aave-data" \
	--config-path ./movefmt.toml \
	--emit-mode "overwrite" \
	-v

# ===================== PACKAGES CHAINLINK ===================== #

compile-chainlink-platform:
	cd aave-core && aptos move compile \
	--included-artifacts $(ARTIFACTS_LEVEL) \
    --save-metadata \
	--package-dir "chainlink-platform" \
	--skip-fetch-latest-git-deps \
	--named-addresses "${AAVE_NAMED_ADDRESSES}"

test-chainlink-platform:
	cd aave-core && aptos move test \
	--ignore-compile-warnings \
	--skip-attribute-checks \
	--package-dir "chainlink-platform" \
	--skip-fetch-latest-git-deps \
	--named-addresses "${AAVE_NAMED_ADDRESSES}" \
  	--coverage

publish-chainlink-platform:
	cd aave-core && aptos move publish --assume-yes \
	--package-dir "chainlink-platform" \
	--included-artifacts $(ARTIFACTS_LEVEL) \
	--sender-account platform \
	--profile platform \
	--skip-fetch-latest-git-deps \
	--named-addresses "${AAVE_NAMED_ADDRESSES}"

compile-chainlink-data-feeds:
	cd aave-core && aptos move compile \
	--included-artifacts $(ARTIFACTS_LEVEL) \
    --save-metadata \
	--package-dir "chainlink-data-feeds" \
	--skip-fetch-latest-git-deps \
	--named-addresses "${AAVE_NAMED_ADDRESSES}"

test-chainlink-data-feeds:
	cd aave-core && aptos move test \
	--ignore-compile-warnings \
	--skip-attribute-checks \
	--package-dir "chainlink-data-feeds" \
	--skip-fetch-latest-git-deps \
	--named-addresses "${AAVE_NAMED_ADDRESSES}" \
  	--coverage

publish-chainlink-data-feeds:
	cd aave-core && aptos move publish --assume-yes \
	--package-dir "chainlink-data-feeds" \
	--included-artifacts $(ARTIFACTS_LEVEL) \
	--sender-account data_feeds \
	--profile data_feeds \
	--skip-fetch-latest-git-deps \
	--named-addresses "${AAVE_NAMED_ADDRESSES}"

# ===================== PACKAGE AAVE-ORACLE ===================== #

compile-oracle:
	cd aave-core && aptos move compile \
	--included-artifacts $(ARTIFACTS_LEVEL) \
    --save-metadata \
	--package-dir "aave-oracle" \
	--skip-fetch-latest-git-deps \
	--named-addresses "${AAVE_NAMED_ADDRESSES}"

publish-oracle:
	cd aave-core && aptos move publish --assume-yes \
	--package-dir "aave-oracle" \
	--included-artifacts $(ARTIFACTS_LEVEL) \
	--sender-account aave_oracle \
	--profile aave_oracle \
	--skip-fetch-latest-git-deps \
	--named-addresses "${AAVE_NAMED_ADDRESSES}" \
	--gas-unit-price 100 \
	--max-gas 30000

test-oracle:
	cd aave-core && aptos move test \
	--ignore-compile-warnings \
	--skip-attribute-checks \
	--package-dir "aave-oracle" \
	--skip-fetch-latest-git-deps \
	--named-addresses "${AAVE_NAMED_ADDRESSES}" \
  	--coverage

doc-oracle:
	cd aave-core && aptos move document \
	--skip-attribute-checks \
	--package-dir "aave-oracle" \
	--named-addresses "${AAVE_NAMED_ADDRESSES}"

fmt-oracle:
	aptos move fmt \
	--package-path "aave-core/aave-oracle" \
	--config-path ./movefmt.toml \
	--emit-mode "overwrite" \
	-v

# ===================== PACKAGE AAVE-POOL ===================== #

compile-pool:
	cd aave-core && aptos move compile \
	--included-artifacts $(ARTIFACTS_LEVEL) \
	--save-metadata \
	--skip-fetch-latest-git-deps \
	--named-addresses "${AAVE_NAMED_ADDRESSES}"

publish-pool:
	cd aave-core && aptos move publish --assume-yes \
	--included-artifacts $(ARTIFACTS_LEVEL) \
	--chunked-publish \
	--sender-account aave_pool \
	--profile aave_pool \
	--skip-fetch-latest-git-deps \
	--large-packages-module-address "$(LARGE_PACKAGE_ADDRESS)" \
	--named-addresses "${AAVE_NAMED_ADDRESSES}" \
	--chunk-size 45000

publish-pool-local:
	cd test-suites && \
	pnpm run publish-pool-package

test-pool:
	cd aave-core && aptos move test \
	--ignore-compile-warnings \
	--skip-attribute-checks \
	--skip-fetch-latest-git-deps \
	--named-addresses "${AAVE_NAMED_ADDRESSES}" \
  	--coverage

doc-pool:
	cd aave-core && aptos move document \
	--skip-attribute-checks \
	--named-addresses "${AAVE_NAMED_ADDRESSES}"

fmt-pool:
	aptos move fmt \
	--package-path "aave-core" \
	--config-path ./movefmt.toml \
	--emit-mode "overwrite" \
	-v

# ===================== AAVE-SCRIPTS ===================== #

configure-acl:
	aptos move run-script \
	--assume-yes \
	--compiled-script-path aave-scripts/build/AaveScripts/bytecode_scripts/configure_acl.mv \
    --sender-account=aave_acl \
    --profile=aave_acl

create-reserves:
	aptos move run-script \
	--assume-yes \
	--compiled-script-path aave-scripts/build/AaveScripts/bytecode_scripts/create_reserves.mv \
    --sender-account=aave_pool \
    --profile=aave_pool

create-emodes:
	aptos move run-script \
	--assume-yes \
	--compiled-script-path aave-scripts/build/AaveScripts/bytecode_scripts/create_emodes.mv \
    --sender-account=aave_pool \
    --profile=aave_pool

configure-reserves:
	aptos move run-script \
	--assume-yes \
	--compiled-script-path aave-scripts/build/AaveScripts/bytecode_scripts/configure_reserves.mv \
    --sender-account=aave_pool \
    --profile=aave_pool

configure-interest-rates:
	aptos move run-script \
	--assume-yes \
	--compiled-script-path aave-scripts/build/AaveScripts/bytecode_scripts/configure_interest_rates.mv \
    --sender-account=aave_pool \
    --profile=aave_pool

configure-price-feeds:
	aptos move run-script \
	--assume-yes \
	--compiled-script-path aave-scripts/build/AaveScripts/bytecode_scripts/configure_price_feeds.mv \
    --sender-account=aave_pool \
    --profile=aave_pool

fmt-scripts:
	aptos move fmt \
	--package-path "aave-core/aave-scripts" \
	--config-path ./movefmt.toml \
	--emit-mode "overwrite" \
	-v

# ===================== GLOBAL COMMANDS ===================== #

ifeq ($(APTOS_NETWORK), local)
COMPILE_CHAINLINK_TARGETS := compile-chainlink-platform compile-chainlink-data-feeds
PUBLISH_CHAINLINK_TARGETS := publish-chainlink-platform publish-chainlink-data-feeds
else
COMPILE_CHAINLINK_TARGETS :=
PUBLISH_CHAINLINK_TARGETS :=
endif

compile-all:
	make compile-config
	make compile-acl
	make compile-large-packages
	make compile-math
	make compile-rate
	@for target in $(COMPILE_CHAINLINK_TARGETS); do \
	    make $$target; \
	done
	make compile-oracle
	make compile-pool
	make compile-data

publish-all:
	make publish-config
	make publish-acl
	make publish-large-packages
	make publish-math
	make publish-rate
	@for target in $(PUBLISH_CHAINLINK_TARGETS); do \
	    make $$target; \
	done
	make publish-oracle
	make publish-pool
	make publish-data

doc-all:
	make doc-config
	make doc-acl
	make doc-large-packages
	make doc-math
	make doc-rate
	make doc-oracle
	make doc-pool

clean-all:
	make clean-package-config
	make clean-package-acl
	make clean-package-large-packages
	make clean-package-math
	make clean-package-rate
	make clean-chainlink-platform
	make clean-chainlink-data-feeds
	make clean-package-oracle
	make clean-core
	make clean-data

# ------------------------------------------------------------
# Formatting
# ------------------------------------------------------------

fmt: fmt-move fmt-prettier fmt-markdown

# fmt & lint all directories
fmt-move:
	make fmt-acl
	make fmt-config
	make fmt-large-packages
	make fmt-math
	make fmt-rate
	make fmt-oracle
	make fmt-pool
	make fmt-data
	make fmt-scripts

fmt-prettier:
	pnpm prettier:fix

fmt-markdown:
	pnpm md:fix

# ------------------------------------------------------------
# Validate code
# ------------------------------------------------------------

lint-prettier:
	pnpm prettier:validate

lint-markdown:
	pnpm md:lint

lint-codespell: ensure-codespell
	codespell --skip "*.json"

ensure-codespell:
	@if ! command -v codespell &> /dev/null; then \
		echo "codespell not found. Please install it by running the command `pip install codespell` or refer to the following link for more information: https://github.com/codespell-project/codespell" \
		exit 1; \
    fi

lint:
	make lint-prettier && \
	make lint-markdown && \
	make fmt && \
	make lint-codespell

fix-lint:
	make fmt
