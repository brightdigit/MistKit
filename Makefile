.PHONY: help example-server clean build test lint \
	release-preflight release-check release-notes-draft

# Default target
help:
	@echo "Available targets:"
	@echo "  example-server      - Run the MistKit example server"
	@echo "  build               - Build the MistDemo example"
	@echo "  test                - Run the test suite"
	@echo "  lint                - Run swift-format + swiftlint + periphery via Scripts/lint.sh"
	@echo "  clean               - Clean build artifacts"
	@echo "  help                - Show this help message"
	@echo ""
	@echo "Release (BRANCH defaults to the current branch, e.g. v1.0.0-beta.5):"
	@echo "  release-preflight   - Gate a release branch: CI, pins, build/test/lint"
	@echo "  release-notes-draft - Write the ReleaseNotes.md section for the release"
	@echo "  release-check       - Validate notes, README and pins before the release PR"
	@echo "  See .claude/skills/release/SKILL.md for the full runbook."
	@echo ""
	@echo "Lint tooling is pinned in mise.toml. Run 'mise install' once so"
	@echo "Scripts/lint.sh can find swift-format, swiftlint, and periphery locally."

# Run the example server
example-server: build
	@echo "🚀 Starting MistKit example server..."
	@cd Examples && swift run MistDemo

# Build the MistDemo example
build:
	@echo "🔨 Building MistDemo example..."
	@cd Examples && swift build

test:
	swift test

lint:
	@mise exec -- ./Scripts/lint.sh

release-preflight:
	@./Scripts/release.sh preflight $(BRANCH)

release-notes-draft:
	@./Scripts/release.sh notes-draft $(BRANCH)

release-check:
	@./Scripts/release.sh check $(BRANCH)

# Clean build artifacts
clean:
	@echo "🧹 Cleaning build artifacts..."
	@cd Examples && swift package clean
	@rm -rf Examples/.build
