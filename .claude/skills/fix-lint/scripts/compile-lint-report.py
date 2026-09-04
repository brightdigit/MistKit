#!/usr/bin/env python3
"""Compile lint tool outputs into a unified MistKit lint report."""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path
from typing import Any

SWIFT_FORMAT_RE = re.compile(
    r"^(?P<file>[^:]+):(?P<line>\d+):(?P<column>\d+): "
    r"(?P<severity>warning|error): \[(?P<rule>[^\]]+)\] (?P<message>.*)$"
)

SWIFT_BUILD_RE = re.compile(
    r"^(?P<file>[^:]+):(?P<line>\d+):(?P<column>\d+): "
    r"(?P<severity>warning|error): (?P<message>.*)$"
)


def read_text(path: Path | None) -> str:
    if path is None or not path.is_file():
        return ""
    return path.read_text(encoding="utf-8", errors="replace")


def read_json(path: Path | None) -> Any:
    if path is None or not path.is_file():
        return None
    text = path.read_text(encoding="utf-8", errors="replace").strip()
    if not text:
        return None
    return json.loads(text)


def parse_swift_format(text: str) -> list[dict[str, Any]]:
    findings: list[dict[str, Any]] = []
    for line in text.splitlines():
        match = SWIFT_FORMAT_RE.match(line.strip())
        if not match:
            continue
        findings.append(
            {
                "file": match.group("file"),
                "line": int(match.group("line")),
                "column": int(match.group("column")),
                "severity": match.group("severity"),
                "rule": match.group("rule"),
                "message": match.group("message"),
            }
        )
    return findings


def parse_swift_build(text: str) -> list[dict[str, Any]]:
    findings: list[dict[str, Any]] = []
    for line in text.splitlines():
        stripped = line.strip()
        if stripped.startswith("[") or ": warning:" not in stripped and ": error:" not in stripped:
            continue
        match = SWIFT_BUILD_RE.match(stripped)
        if not match:
            continue
        findings.append(
            {
                "file": match.group("file"),
                "line": int(match.group("line")),
                "column": int(match.group("column")),
                "severity": match.group("severity"),
                "rule": "compiler",
                "message": match.group("message"),
            }
        )
    return findings


def normalize_swiftlint(raw: list[dict[str, Any]] | None) -> tuple[list[dict[str, Any]], int]:
    if not raw:
        return [], 0
    findings: list[dict[str, Any]] = []
    for violation in raw:
        severity = str(violation.get("severity", "")).lower()
        findings.append(
            {
                "file": violation.get("file", ""),
                "line": violation.get("line"),
                "column": violation.get("character"),
                "severity": severity,
                "rule": violation.get("rule_id", ""),
                "message": violation.get("reason", ""),
                "type": violation.get("type"),
            }
        )
    serious_count = sum(1 for finding in findings if finding["severity"] == "error")
    return findings, serious_count


def normalize_periphery(raw: list[dict[str, Any]] | None) -> list[dict[str, Any]]:
    if not raw:
        return []
    findings: list[dict[str, Any]] = []
    for item in raw:
        location = item.get("location", "")
        file_path = location
        line: int | None = None
        column: int | None = None
        if location.count(":") >= 2:
            file_path, line_text, column_text = location.rsplit(":", 2)
            line = int(line_text)
            column = int(column_text)
        hints = item.get("hints", [])
        rule = hints[0] if hints else "unused"
        kind = item.get("kind", "symbol")
        name = item.get("name", "")
        findings.append(
            {
                "file": file_path,
                "line": line,
                "column": column,
                "severity": "warning",
                "rule": rule,
                "message": f"Unused {kind} '{name}'",
            }
        )
    return findings


def tool_section(
    *,
    skipped: bool,
    skip_reason: str | None,
    exit_code: int | None,
    findings: list[dict[str, Any]],
    extra: dict[str, Any] | None = None,
) -> dict[str, Any]:
    section: dict[str, Any] = {
        "skipped": skipped,
        "exitCode": exit_code,
        "findingCount": len(findings),
        "findings": findings,
    }
    if skip_reason:
        section["skipReason"] = skip_reason
    if extra:
        section.update(extra)
    return section


def human_summary(report: dict[str, Any]) -> str:
    lines = ["=== MistKit lint report ==="]
    for tool_name, tool in report["tools"].items():
        label = tool_name.replace("-", " ")
        if tool["skipped"]:
            reason = tool.get("skipReason", "skipped")
            lines.append(f"{label}: skipped ({reason})")
            continue
        count = tool["findingCount"]
        suffix = ""
        if tool_name == "swiftlint" and "seriousCount" in tool:
            suffix = f" ({tool['seriousCount']} serious)"
        elif tool_name == "swift-build":
            errors = sum(1 for f in tool["findings"] if f["severity"] == "error")
            warnings = sum(1 for f in tool["findings"] if f["severity"] == "warning")
            if errors or warnings:
                suffix = f" ({errors} errors, {warnings} warnings)"
        noun = "finding" if count == 1 else "findings"
        lines.append(f"{label}: {count} {noun}{suffix}")
    lines.append("---")
    lines.append(f"total: {report['summary']['totalFindings']} findings")
    failed_steps = report["summary"]["failedSteps"]
    if failed_steps:
        lines.append(f"failed steps: {', '.join(failed_steps)}")
    else:
        lines.append("failed steps: none")
    return "\n".join(lines)


def main() -> int:
    if len(sys.argv) != 2:
        print("usage: compile-lint-report.py <manifest.json>", file=sys.stderr)
        return 2

    manifest = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
    report_dir = Path(manifest["reportDir"])

    swift_format_findings = parse_swift_format(
        read_text(report_dir / "swift-format.log")
    )
    swiftlint_raw = read_json(report_dir / "swiftlint.json")
    swiftlint_findings, serious_count = normalize_swiftlint(swiftlint_raw)
    swift_build_findings = parse_swift_build(read_text(report_dir / "swift-build.log"))
    periphery_findings = normalize_periphery(read_json(report_dir / "periphery.json"))

    tools: dict[str, Any] = {
        "swift-format": tool_section(
            skipped=False,
            skip_reason=None,
            exit_code=manifest["steps"].get("swift-format", {}).get("exitCode"),
            findings=swift_format_findings,
        ),
        "swiftlint": tool_section(
            skipped=manifest["steps"].get("swiftlint", {}).get("skipped", False),
            skip_reason=manifest["steps"].get("swiftlint", {}).get("skipReason"),
            exit_code=manifest["steps"].get("swiftlint", {}).get("exitCode"),
            findings=swiftlint_findings,
            extra={"seriousCount": serious_count},
        ),
        "swift-build": tool_section(
            skipped=manifest["steps"].get("swift-build", {}).get("skipped", False),
            skip_reason=manifest["steps"].get("swift-build", {}).get("skipReason"),
            exit_code=manifest["steps"].get("swift-build", {}).get("exitCode"),
            findings=swift_build_findings,
        ),
        "periphery": tool_section(
            skipped=manifest["steps"].get("periphery", {}).get("skipped", False),
            skip_reason=manifest["steps"].get("periphery", {}).get("skipReason"),
            exit_code=manifest["steps"].get("periphery", {}).get("exitCode"),
            findings=periphery_findings,
        ),
    }

    total_findings = sum(tool["findingCount"] for tool in tools.values())
    failed_steps = manifest.get("failedSteps", [])

    report = {
        "summary": {
            "totalFindings": total_findings,
            "failedSteps": failed_steps,
            "failedStepCount": len(failed_steps),
        },
        "tools": tools,
    }

    output_format = manifest.get("outputFormat", "json")
    json_text = json.dumps(report, indent=2)

    if output_format in {"both", "summary"}:
        print(human_summary(report), file=sys.stderr)

    print("### MISTKIT_LINT_REPORT_BEGIN ###")
    print(json_text)
    print("### MISTKIT_LINT_REPORT_END ###")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
