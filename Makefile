.PHONY: help example-server clean build

# Default target
help:
	@echo "Available targets:"
	@echo "  example-server  - Run the MistKit example server"
	@echo "  build          - Build the MistDemo example"
	@echo "  clean          - Clean build artifacts"
	@echo "  help           - Show this help message"

# Run the example server
example-server: build
	@echo "🚀 Starting MistKit example server..."
	@cd Examples && swift run MistDemo

# Build the MistDemo example
build:
	@echo "🔨 Building MistDemo example..."
	@cd Examples && swift build

# Clean build artifacts
clean:
	@echo "🧹 Cleaning build artifacts..."
	@cd Examples && swift package clean
	@rm -rf Examples/.build
