.PHONY: help build test lint clean

help:
	@echo "Available targets:"
	@echo "  build  - Build the package"
	@echo "  test   - Run the test suite"
	@echo "  lint   - Run swift-format + swiftlint + periphery via Scripts/lint.sh"
	@echo "  clean  - Clean build artifacts"
	@echo "  help   - Show this help message"

build:
	swift build

test:
	swift test

lint:
	@./Scripts/lint.sh

clean:
	swift package clean
	rm -rf .build
