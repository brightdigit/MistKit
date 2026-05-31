//
//  WithKnownIssueWhen.swift
//  MistDemo
//
//  Created by Leo Dion.
//  Copyright © 2026 BrightDigit.
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the "Software"), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.
//

internal import Testing

/// `withKnownIssue` that only wraps `body` when `when` is true; otherwise runs
/// `body` strictly (any throw is recorded as a real `Issue`). Lets call sites
/// say "expected to flake on these platforms / environments, must succeed
/// everywhere else" without duplicating the body across an if/else.
///
/// See `TestPlatform.isFlakyTimeoutSimulator` for the canonical caller — gates
/// the `withTimeout` polling-race flake on CI simulator runs (#334) while
/// keeping the assertions strict on every other platform/environment.
internal func withKnownIssue(
  _ comment: Comment? = nil,
  isIntermittent: Bool = false,
  when condition: Bool,
  sourceLocation: SourceLocation = #_sourceLocation,
  _ body: () async throws -> Void
) async {
  if condition {
    await withKnownIssue(
      comment,
      isIntermittent: isIntermittent,
      sourceLocation: sourceLocation,
      body
    )
  } else {
    do {
      try await body()
    } catch {
      Issue.record(error, sourceLocation: sourceLocation)
    }
  }
}
