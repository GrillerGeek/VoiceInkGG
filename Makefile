LOCAL_DERIVED_DATA ?= $(CURDIR)/.review-build/DerivedData
LOCAL_CODESIGN_IDENTITY ?=
.PHONY: all check healthcheck whisper setup build local dev run release clean help test
all: local
check healthcheck:
	@command -v git >/dev/null
	@command -v xcodebuild >/dev/null
	@command -v swift >/dev/null
	@echo "Build prerequisites OK"
whisper setup:
	@./scripts/build-whisper.sh
build local: check whisper
	@ROBEY_VOICE_DERIVED_DATA="$(LOCAL_DERIVED_DATA)" ROBEY_VOICE_SIGNING_IDENTITY="$(LOCAL_CODESIGN_IDENTITY)" ./scripts/build-local.sh
dev: check whisper
	@ROBEY_VOICE_CONFIGURATION=Debug ROBEY_VOICE_DERIVED_DATA="$(LOCAL_DERIVED_DATA)" ROBEY_VOICE_SIGNING_IDENTITY="$(LOCAL_CODESIGN_IDENTITY)" ./scripts/build-local.sh
run:
	@open "$(LOCAL_DERIVED_DATA)/Build/Products/Release/Robey Voice.app"
release: local
	@ROBEY_VOICE_BUILD_RECORD="$(LOCAL_DERIVED_DATA)/robey-build-record.json" ./scripts/release.sh --app "$(LOCAL_DERIVED_DATA)/Build/Products/Release/Robey Voice.app" $(RELEASE_ARGS)
test:
	@python3 -m unittest discover -s Tests/PersonalForkAcceptance -v
clean:
	@echo "Preserved build outputs: .review-build/; sources and caches: .local-dependencies/. Remove explicitly when no build is running."
help:
	@echo "make local: Release in .review-build/ with workspace-local pinned dependencies"
	@echo "make dev: isolated Debug app; make test: focused acceptance checks"
	@echo "make release: local manual-update DMG, matching source and checksums"
	@echo "LOCAL_CODESIGN_IDENTITY=<SHA or -> selects stable or ad-hoc signing"
