# Environment Variables

PRODUCT_NAME := AppleSwiftFormatPluginExample
SCHEME_NAME := $(PRODUCT_NAME)

SUPPORT_XCODE_VERSION := 15.0.1
CURRENT_XCODE_VERSION := $(shell xcodebuild -version | grep Xcode | awk '{print $$2}')

MAKEFILE_DIR := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
XCODEPROJ_PATH := $(MAKEFILE_DIR)/App/$(PRODUCT_NAME).xcodeproj

ARTIFACT_BUNDLE_PATH := $(MAKEFILE_DIR)/artifactbundle
SWIFT_FORMAT_ARTIFACT_BUNDLE_PATH := $(ARTIFACT_BUNDLE_PATH)/swift-format.artifactbundle

SWIFT_BUILD := swift build --package-path $(MAKEFILE_DIR)
SWIFT_RUN := swift run --package-path $(MAKEFILE_DIR)
SWIFT_PACKAGE := swift package --package-path $(MAKEFILE_DIR)
SWIFT_PLUGIN := $(SWIFT_PACKAGE) plugin

export MAKEFLAGS = --silent

# Public commands

default: app

.PHONY: help
help:
	@## "The command name and the comment line immediately before it will be output.
	@## @see https://stackoverflow.com/a/35730928
	@{ \
      max_len=$$(awk '/^#/{c=substr($$0,4);next}/^\.PHONY/{p=1;next}p&&/^[[:alpha:]][[:alnum:]_-]+:/&&c{print length(substr($$1,1,index($$1,":")-1));p=0;c=""}1{c=""}' $(MAKEFILE_LIST) | sort -nr | head -1); \
      header_len=$$(echo "Command" | wc -c | tr -d ' '); \
      if [ $$max_len -lt $$header_len ]; then max_len=$$header_len; fi; \
      printf "%-$$max_len""s  %s\n" "Command" "Description"; \
      printf "%-$$max_len""s  %s\n" "-------" "-----------"; \
      awk -v max_len=$$max_len '/^#/{c=substr($$0,4);next}/^\.PHONY/{p=1;next}p&&/^[[:alpha:]][[:alnum:]_-]+:/&&c{printf "%s%*s%s\n", substr($$1,1,index($$1,":")-1), (max_len - length(substr($$1,1,index($$1,":")-1)) + 2), "", c; p=0;c=""}1{c=""}' $(MAKEFILE_LIST); \
    }

## Set up the environment and open the Xcode project.
.PHONY: app
app: \
  check_xcode_version \
  swift_format_artifactbundle \
  swiftpm \
  open

## Delete the artifacts of the environment setup and the app's cache.
.PHONY: clean
clean: \
  clean_app \
  clean_app_caches \
  clean_articalbundle

## Delete the artifacts of the environment setup, the app's cache, and the cache of the dependent libraries.
.PHONY: clean_all
clean_all: \
  clean \
  _clean_swiftpm_caches

# Internal commands

## Xcode

.PHONY: check_xcode_version
check_xcode_version:
ifeq ($(CURRENT_XCODE_VERSION),$(SUPPORT_XCODE_VERSION))
	@echo "✅ Xcode $(SUPPORT_XCODE_VERSION)"
else
	$(error The currently selected Xcode is $(CURRENT_XCODE_VERSION), and this project supports $(SUPPORT_XCODE_VERSION), so the project cannot be opened. Please refer to the README and install and switch to Xcode $(SUPPORT_XCODE_VERSION).)
endif

.PHONY: swiftpm
swiftpm:
	xcodebuild \
		-project $(XCODEPROJ_PATH) \
		-scheme $(SCHEME_NAME) \
		-resolvePackageDependencies
	@echo "✅ $@"

.PHONY: open
open:
	xed $(XCODEPROJ_PATH)
	@echo "✅ $@"

## Xcode Plugins

.PHONY: swift_format_artifactbundle
swift_format_artifactbundle:
	@echo "🛠️ $@"
	@## Workaround:
	@## Generate a dummy swift-format.artifactbundle to run swift build before creating the swift-format.artifactbundle referenced by SwiftFormatBinary.
	$(MAKE) _swift_format_artifactbundle_configuration LIBRARY=swift-format VERSION=0.0.1
	touch $(SWIFT_FORMAT_ARTIFACT_BUNDLE_PATH)/swift-format-0.0.1-macos/bin/swift-format
	
	@## Generate the correct swift-format.artifactbundle.
	@SWIFT_FORMAT_VERSION=$$($(SWIFT_RUN) swift-format -v); \
	$(MAKE) _swift_format_artifactbundle_configuration LIBRARY=swift-format VERSION=$$SWIFT_FORMAT_VERSION; \
	cp $(shell $(SWIFT_BUILD) --show-bin-path)/swift-format \
	  $(SWIFT_FORMAT_ARTIFACT_BUNDLE_PATH)/swift-format-$$SWIFT_FORMAT_VERSION-macos/bin/swift-format
	@echo "✅ $@"

.PHONY: _swift_format_artifactbundle_configuration
_swift_format_artifactbundle_configuration:
ifndef LIBRARY
	$(error "The argument 'LIBRARY' is missing. e.g. `make _swift_format_artifactbundle_dir LIBRARY=swift-format`")
endif
ifndef VERSION
	$(error "The argument 'VERSION' is missing. e.g. `make _swift_format_artifactbundle_dir VERSION=0.0.1`")
endif
	mkdir -p $(SWIFT_FORMAT_ARTIFACT_BUNDLE_PATH)/$(LIBRARY)-$(VERSION)-macos/bin
	sed -e 's/__VERSION__/$(VERSION)/g' \
	  -e 's/__LIBRARY__/$(LIBRARY)/g' \
	  $(ARTIFACT_BUNDLE_PATH)/info.json.template > $(SWIFT_FORMAT_ARTIFACT_BUNDLE_PATH)/info.json

.PHONY: plugin_list
plugin_list:
	@echo "🛠️ $@"
	$(SWIFT_PLUGIN) --list
	@echo "✅ $@"

.PHONY: lint
lint:
	@echo "🛠️ $@"
	$(SWIFT_PLUGIN) lint-source-code
	@echo "✅ $@"

.PHONY: format
format:
	@echo "🛠️ $@"
	$(SWIFT_PLUGIN) --allow-writing-to-package-directory format-source-code
	@echo "✅ $@"

.PHONY: swift_format_dump_configuration
swift_format_dump_configuration:
	@echo "🛠️ $@"
	@## Generate the executable for swift-format.
	@$(SWIFT_RUN) swift-format -v
	$(shell $(SWIFT_BUILD) --show-bin-path)/swift-format dump-configuration
	@echo "✅ $@"

## Clean

.PHONY: clean_app
clean_app:
	rm -rf $(MAKEFILE_DIR)/.swiftpm
	rm -rf $(MAKEFILE_DIR)/.build
	rm -rf $(MAKEFILE_DIR)/App/.swiftpm
	@echo "✅ $@"

.PHONY: clean_app_caches
clean_app_caches:
	find $(HOME)/Library/Developer/Xcode/DerivedData/ \
		-name $(PRODUCT_NAME)"*" \
		-maxdepth 1 \
		-print \
		-type d \
		-exec rm -rf {} +
	@echo "✅ $@"

.PHONY: clean_articalbundle
clean_articalbundle:
	find $(ARTIFACT_BUNDLE_PATH) \
		-name '*.artifactbundle' \
		-maxdepth 1 \
		-print \
		-type d \
		-exec rm -rf {} +
	@echo "✅ $@"

.PHONY: _clean_swiftpm_caches
_clean_swiftpm_caches:
	rm -rf ~/Library/Caches/org.swift.swiftpm
	@echo "✅ $@"
