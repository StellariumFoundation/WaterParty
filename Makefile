# WaterParty Makefile
# Centralized build and release tool for Human Connection OS

SERVER_DIR = server
SERVER_BINARY = partyserver
VERSION = $(shell grep '^version:' pubspec.yaml | sed 's/version: //' | tr -d ' ')

.PHONY: all build build-server build-app release release-server release-app install-deps clean

all: build

# --- Dependencies ---
install-deps:
	@echo "--- Installing Dependencies ---"
	flutter pub get
	cd $(SERVER_DIR) && go mod download

# --- Build ---
build: install-deps build-server build-app

build-server:
	@echo "--- Building Go Server (Partyserver) ---"
	cd $(SERVER_DIR) && go build -o $(SERVER_BINARY) .

build-app: build-android build-linux build-web

build-android:
	@echo "--- Building Android APK ---"
	flutter build apk --release --split-per-abi --obfuscate --split-debug-info=./debug-info

build-linux:
	@echo "--- Building Linux Bundle ---"
	flutter config --enable-linux-desktop
	flutter build linux --release --obfuscate --split-debug-info=./debug-info
	find build/linux/x64/release/bundle/ -maxdepth 1 -type f -executable -exec strip {} +

build-web:
	@echo "--- Building Web Artifacts ---"
	flutter build web --release

# --- Release ---
release: release-server release-app

release-server: build-server
	@echo "--- Releasing Server (Binary + Docker) ---"
	# Prepare the release binary
	mkdir -p release/server
	cp $(SERVER_DIR)/$(SERVER_BINARY) release/server/
	@echo "Server binary ready in release/server/$(SERVER_BINARY)"
	# Optional: docker build -t waterparty/server:v$(VERSION) $(SERVER_DIR)

release-app: build-app
	@echo "--- Packaging App for Release v$(VERSION) ---"
	mkdir -p release/app
	# Android
	cp build/app/outputs/flutter-apk/app-release.apk release/app/WaterParty-Universal.apk || true
	cp build/app/outputs/flutter-apk/app-arm64-v8a-release.apk release/app/WaterParty-Android-arm64.apk || true
	# Linux
	tar -czvf release/app/WaterParty-Linux-v$(VERSION).tar.gz -C build/linux/x64/release/bundle .
	# Web
	cd build/web && zip -r ../../release/app/WaterParty-Web-v$(VERSION).zip .
	@echo "App artifacts ready in release/app/"

clean:
	@echo "--- Cleaning Build Artifacts ---"
	flutter clean
	rm -rf build/
	rm -rf release/
	rm -f $(SERVER_DIR)/$(SERVER_BINARY)
