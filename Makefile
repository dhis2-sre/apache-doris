JDK_VERSION = $(shell yq -r '.jdkVersion' versions.yaml)
JDBC_VERSION = $(shell yq -r '.jdbcVersion' versions.yaml)
JDBC_SHA256 = $(shell yq -r '.jdbcSha256' versions.yaml)

all: build-all push-all

# Both tiers of every version, tagged <tier>-<version>-postgres so a tag says which Doris it derives
# from and what was added to it.
build-all:
	@yq -r '.versions[]' versions.yaml | while read -r version; do \
		echo "==> build $$version"; \
		dorisVersion=$$version jdkVersion=$(JDK_VERSION) jdbcVersion=$(JDBC_VERSION) jdbcSha256=$(JDBC_SHA256) \
		docker compose build || exit 1; \
	done

push-all:
	@yq -r '.versions[]' versions.yaml | while read -r version; do \
		echo "==> push $$version"; \
		dorisVersion=$$version jdbcVersion=$(JDBC_VERSION) jdbcSha256=$(JDBC_SHA256) \
		docker compose push || exit 1; \
	done

remove-all:
	@yq -r '.versions[]' versions.yaml | while read -r version; do \
		dorisVersion=$$version docker compose down --rmi all || true; \
	done

.PHONY: all build-all push-all remove-all
