//
//  IntegrationPhase.swift
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

import Foundation
import MistKit

/// A single step in an integration test.
///
/// Phases are typed in their inputs and outputs; the runner adapts heterogeneous
/// phases into a single `[any IntegrationPhase]` array via `runErased`, which
/// pulls each phase's input out of `PhaseState`, runs it, and writes the
/// output back.
protocol IntegrationPhase<Input, Output> {
  associatedtype Input
  associatedtype Output

  var title: String { get }
  var emoji: String { get }
  var apiName: String { get }

  func extractInput(from state: PhaseState) throws -> Input
  func apply(output: Output, to state: inout PhaseState)
  func run(input: Input, context: PhaseContext) async throws -> Output

  /// Type-erased entry point used by the runner to drive a `[any IntegrationPhase]`.
  func runErased(context: PhaseContext, state: inout PhaseState) async throws
}

extension IntegrationPhase {
  func runErased(context: PhaseContext, state: inout PhaseState) async throws {
    let input = try extractInput(from: state)
    let output = try await run(input: input, context: context)
    apply(output: output, to: &state)
  }
}

extension IntegrationPhase where Input == Void {
  func extractInput(from state: PhaseState) throws -> Void { () }
}

extension IntegrationPhase where Output == Void {
  func apply(output: Void, to state: inout PhaseState) {}
}

/// Marker protocol identifying the cleanup phase so the runner can skip it
/// when `--skip-cleanup` is set and re-run it on failure.
protocol CleanupPhaseMarker {}
