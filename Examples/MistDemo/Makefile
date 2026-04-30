.PHONY: generate clean help

# Source .env (if present) so XcodeGen can substitute ${CLOUDKIT_API_TOKEN}
# and any other variables in project.yml. Falls back to the calling shell's
# environment when .env is absent (CI, ad-hoc `export`, etc.).
generate:
	@if [ -f .env ]; then \
		echo "Sourcing .env"; \
		set -a && . ./.env && set +a; \
	fi; \
	xcodegen generate

clean:
	rm -rf MistDemoApp.xcodeproj

help:
	@echo "Targets:"
	@echo "  generate  Source .env (if present) and run xcodegen generate"
	@echo "  clean     Remove the generated MistDemoApp.xcodeproj"
