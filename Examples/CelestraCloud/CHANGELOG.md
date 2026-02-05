# Changelog

All notable changes to CelestraCloud will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-12-11

### Added
- Initial production release of CelestraCloud
- RSS feed management with CloudKit public database sync
- MistKit integration for CloudKit Web Services operations
- Query filtering and sorting demonstrations using MistKit's QueryFilter API
- Batch operations for efficient article uploads with chunking (10 records per batch)
- Duplicate detection via GUID-based queries with content hash comparison
- Comprehensive web etiquette features (using services from CelestraKit):
  - Per-domain rate limiting (RateLimiter actor from CelestraKit)
  - Robots.txt compliance checking (RobotsTxtService from CelestraKit)
  - Conditional HTTP requests (If-Modified-Since, ETag support)
  - Failure tracking and exponential backoff
  - Respect for feed TTL and update intervals
- Server-to-Server authentication for CloudKit access
- CelestraKit dependency for shared models (Feed, Article) and web etiquette services (RateLimiter, RobotsTxtService)
- Comprehensive test suite with 22 local tests across 3 suites (additional 19 tests in CelestraKit)
- CI/CD pipeline with GitHub Actions (Ubuntu + macOS builds, linting)
- Linting and code formatting (SwiftLint, SwiftFormat)
- Makefile for common development tasks
- MIT License

### Features
- **Commands**:
  - `add-feed` - Parse and validate RSS feeds, store in CloudKit
  - `update` - Fetch and update feeds with filtering options
  - `clear` - Delete all records from CloudKit
- **CloudKit Field Mapping**:
  - Direct field mapping pattern (Feed+MistKit, Article+MistKit extensions)
  - Boolean storage as INT64 (0/1) for CloudKit compatibility
  - Automatic field type conversion with FieldValue enum
- **Local Services**:
  - CloudKitService extensions for CelestraCloud operations
  - RSSFetcherService wrapping SyndiKit for RSS parsing
  - CelestraLogger with structured logging categories
  - CelestraError for error handling
- **Services from CelestraKit**:
  - RobotsTxtService actor for respectful web crawling
  - RateLimiter actor for thread-safe delay management
  - Feed and Article models for shared data structures

### Infrastructure
- Package renamed from "Celestra" to "CelestraCloud"
- Executable renamed from "celestra" to "celestra-cloud"
- CelestraKit external dependency added (branch v0.0.1) for shared models and services:
  - Enables code reuse across Celestra ecosystem (CLI, future mobile apps, etc.)
  - Provides Feed and Article models
  - Provides RateLimiter and RobotsTxtService for web etiquette
- SyndiKit dependency migrated from local path to GitHub (v0.6.1)
- Migrated comprehensive development infrastructure from MistKit:
  - GitHub Actions workflows (build, test, lint)
  - SwiftLint configuration with 90+ rules
  - SwiftFormat configuration
  - Mintfile for tool management (SwiftFormat, SwiftLint, Periphery)
  - Xcodegen project configuration
  - Development scripts (lint.sh, header.sh, setup-cloudkit-schema.sh)
- Documentation reorganized:
  - User-facing: README.md, LICENSE, CHANGELOG.md
  - AI context: CLAUDE.md
  - Development context: .claude/ directory (PRD, implementation notes, schema workflow)

### Technical Details
- **Platform**: macOS 26+ (Swift 6.2)
- **Concurrency**: Full Swift 6 concurrency support with strict checking
- **Dependencies**: MistKit 1.0.0-alpha.3, SyndiKit 0.6.1, ArgumentParser, swift-log
- **CloudKit**: Public database with Feed and Article record types
- **Schema**: Text-based .ckdb schema with cktool deployment

### Documentation
- Comprehensive CLAUDE.md for AI agent guidance
- README with setup instructions, usage examples, and feature overview
- Example .env file for CloudKit configuration
- CloudKit schema deployment automation

## [Unreleased]

### Planned for Future Releases
- iOS/macOS GUI client
- Private database support
- Multi-user authentication
- Feed recommendation system
- Advanced search beyond CloudKit queries
- Automatic feed discovery
- DocC published documentation
- Code coverage reporting integration

---

**Note**: This is the first production release. CelestraCloud demonstrates MistKit's CloudKit integration capabilities through a fully functional command-line RSS reader with comprehensive web etiquette best practices.
