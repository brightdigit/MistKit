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

/// A type that can be initialized from `PhaseState`.
///
/// Modeled after `Decodable`: each phase's `Input` type owns its own
/// rules for reading the slice of `PhaseState` it needs.
protocol PhaseStateDecodable: Sendable {
  init(from state: PhaseState) throws
}

/// A type that can write itself into `PhaseState`.
///
/// Modeled after `Encodable`: each phase's `Output` type owns its own
/// rules for writing back into `PhaseState`.
protocol PhaseStateEncodable: Sendable {
  func encode(to state: inout PhaseState)
}

/// A single step in an integration test.
///
/// `Input` and `Output` describe the slices of `PhaseState` the phase reads
/// and writes; the phase itself only carries metadata and run logic. The
/// runner adapts heterogeneous phases via `runErased`, which decodes the
/// input from state, runs the phase, and encodes the output back.
protocol IntegrationPhase<Input, Output> {
  associatedtype Input: PhaseStateDecodable
  associatedtype Output: PhaseStateEncodable

  static var title: String { get }
  static var emoji: String { get }
  static var apiName: String { get }

  func run(input: Input, context: PhaseContext) async throws -> Output

  /// Type-erased entry point used by the runner to drive a `[any IntegrationPhase]`.
  func runErased(context: PhaseContext, state: inout PhaseState) async throws
}

extension IntegrationPhase {
  func runErased(context: PhaseContext, state: inout PhaseState) async throws {
    let input = try Input(from: state)
    let output = try await run(input: input, context: context)
    output.encode(to: &state)
  }
}

/// Marker protocol identifying the cleanup phase so the runner can skip it
/// when `--skip-cleanup` is set and re-run it on failure.
protocol CleanupPhaseMarker {}
