//
//  ContainerOperationInputPath.swift
//  MistKit
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

internal import MistKitOpenAPI

/// Shared shape of the container-scoped `Operations.*.Input.Path` types.
///
/// The APNs token endpoints (`tokens/create`, `tokens/register`) live at
/// `/database/{version}/{container}/{environment}/...` — they are not
/// database-scoped, so their generated `Input.Path` omits the `database`
/// segment. This sibling of ``OperationInputPath`` unlocks the same
/// MistKit-flavored convenience init without that parameter.
internal protocol ContainerOperationInputPath {
  init(
    version: Components.Parameters.version,
    container: Components.Parameters.container,
    environment: Components.Parameters.environment
  )
}

extension ContainerOperationInputPath {
  /// Initialize from MistKit configuration components.
  internal init(
    containerIdentifier: String,
    environment: Environment
  ) {
    self.init(
      version: "1",
      container: containerIdentifier,
      environment: .init(from: environment)
    )
  }
}

extension Operations.createToken.Input.Path: ContainerOperationInputPath {}

extension Operations.registerToken.Input.Path: ContainerOperationInputPath {}
