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

GO_BUILD_FLAGS = -ldflags="-s -w" -trimpath

release-server: 
	@echo "--- Releasing Optimized Server (Multi-Platform Binaries) ---"
	mkdir -p release/server
	# Linux 64-bit
	cd $(SERVER_DIR) && GOOS=linux GOARCH=amd64 go build $(GO_BUILD_FLAGS) -o ../release/server/$(SERVER_BINARY)-linux-amd64 .
	# Linux ARM64
	cd $(SERVER_DIR) && GOOS=linux GOARCH=arm64 go build $(GO_BUILD_FLAGS) -o ../release/server/$(SERVER_BINARY)-linux-arm64 .
	# Windows 64-bit
	cd $(SERVER_DIR) && GOOS=windows GOARCH=amd64 go build $(GO_BUILD_FLAGS) -o ../release/server/$(SERVER_BINARY)-windows-amd64.exe .
	# macOS 64-bit (Intel)
	cd $(SERVER_DIR) && GOOS=darwin GOARCH=amd64 go build $(GO_BUILD_FLAGS) -o ../release/server/$(SERVER_BINARY)-darwin-amd64 .
	# macOS ARM64 (Apple Silicon)
	cd $(SERVER_DIR) && GOOS=darwin GOARCH=arm64 go build $(GO_BUILD_FLAGS) -o ../release/server/$(SERVER_BINARY)-darwin-arm64 .
	@echo "Optimized server binaries ready in release/server/"

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
