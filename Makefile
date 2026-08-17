IMAGE ?= dhis2/apache-doris
JDBC_VERSION = $(shell yq '.jdbcVersion' versions.yaml)
JDBC_SHA256 = $(shell yq '.jdbcSha256' versions.yaml)
VERSIONS = $(shell yq '.versions[]' versions.yaml)
TIERS = $(shell yq '.tiers[]' versions.yaml)

# Every tier of every version, tagged <tier>-<version>-postgres so the tag says which Doris it
# derives from and what was added to it.
.PHONY: all
all:
	@for version in $(VERSIONS); do \
		for tier in $(TIERS); do \
			$(MAKE) build push tier=$$tier version=$$version || exit 1; \
		done \
	done

.PHONY: build
build:
	docker build \
		--build-arg tier=$(tier) \
		--build-arg dorisVersion=$(version) \
		--build-arg jdbcVersion=$(JDBC_VERSION) \
		--build-arg jdbcSha256=$(JDBC_SHA256) \
		--tag $(IMAGE):$(tier)-$(version)-postgres \
		.

.PHONY: push
push:
	docker push $(IMAGE):$(tier)-$(version)-postgres
