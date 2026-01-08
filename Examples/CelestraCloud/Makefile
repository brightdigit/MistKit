.PHONY: help build test lint format run setup-cloudkit clean install

# Default target
help:
	@echo "Available targets:"
	@echo "  install         - Install development dependencies via Mint"
	@echo "  build          - Build the project"
	@echo "  test           - Run unit tests"
	@echo "  lint           - Run linters (SwiftLint, SwiftFormat)"
	@echo "  format         - Auto-format code (SwiftFormat)"
	@echo "  run            - Run CLI (requires .env sourced)"
	@echo "  setup-cloudkit - Deploy CloudKit schema"
	@echo "  clean          - Clean build artifacts"
	@echo "  help           - Show this help message"

# Install dev dependencies
install:
	@echo "📦 Installing development tools via Mint..."
	@mint bootstrap

# Build the project
build:
	@echo "🔨 Building CelestraCloud..."
	@swift build

# Run unit tests
test:
	@echo "🧪 Running tests..."
	@swift test

# Run linters
lint:
	@echo "🔍 Running linters..."
	@./Scripts/lint.sh

# Auto-format code
format:
	@echo "✨ Formatting code..."
	@FORMAT_ONLY=1 ./Scripts/lint.sh

# Run CLI (assumes environment sourced)
run:
	@echo "🚀 Running celestra-cloud..."
	@swift run celestra-cloud

# Deploy CloudKit schema
setup-cloudkit:
	@echo "☁️  Deploying CloudKit schema..."
	@./Scripts/setup-cloudkit-schema.sh

# Clean build artifacts
clean:
	@echo "🧹 Cleaning build artifacts..."
	@swift package clean
	@rm -rf .build
