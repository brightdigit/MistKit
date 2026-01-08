.PHONY: build test lint format clean install docker-build docker-run docker-test xcode help

# Default target
.DEFAULT_GOAL := help

# Variables
EXECUTABLE_NAME = bushel-cloud
INSTALL_PATH = /usr/local/bin
BUILD_PATH = .build/release/$(EXECUTABLE_NAME)
DOCKER_IMAGE = swift:6.2-noble

## build: Build the project in release mode
build:
	@echo "Building BushelCloud..."
	swift build -c release

## test: Run unit tests
test:
	@echo "Running tests..."
	swift test

## lint: Run linting checks (SwiftLint, swift-format, periphery)
lint:
	@echo "Running linting..."
	./Scripts/lint.sh

## format: Format code with swift-format
format:
	@echo "Formatting code..."
	mint run swift-format format --recursive --parallel --in-place Sources Tests

## clean: Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	swift package clean
	rm -rf .build

## install: Install executable to /usr/local/bin
install: build
	@echo "Installing $(EXECUTABLE_NAME) to $(INSTALL_PATH)..."
	@install -m 755 $(BUILD_PATH) $(INSTALL_PATH)/$(EXECUTABLE_NAME)
	@echo "Installed successfully!"

## docker-build: Build project in Docker container
docker-build:
	@echo "Building in Docker ($(DOCKER_IMAGE))..."
	docker run --rm -v $(PWD):/workspace -w /workspace $(DOCKER_IMAGE) swift build

## docker-test: Run tests in Docker container
docker-test:
	@echo "Running tests in Docker ($(DOCKER_IMAGE))..."
	docker run --rm -v $(PWD):/workspace -w /workspace $(DOCKER_IMAGE) swift test

## docker-run: Run interactive shell in Docker container
docker-run:
	@echo "Starting Docker shell ($(DOCKER_IMAGE))..."
	docker run -it --rm -v $(PWD):/workspace -w /workspace $(DOCKER_IMAGE) bash

## xcode: Generate Xcode project using XcodeGen
xcode:
	@echo "Generating Xcode project..."
	@mint run xcodegen generate
	@echo "Xcode project generated! Open BushelCloud.xcodeproj"

## help: Show this help message
help:
	@echo "BushelCloud Makefile targets:"
	@echo ""
	@sed -n 's/^##//p' $(MAKEFILE_LIST) | column -t -s ':' | sed -e 's/^/ /'
