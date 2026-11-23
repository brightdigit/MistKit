//
//  SchemaRecordType+Grants.swift
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

internal import Foundation

extension SchemaRecordType: Identifiable {
  /// The record type's name, unique within its schema.
  public var id: String { name }

  /// One grant per role: every permission the record type's ``grants`` give
  /// that role.
  ///
  /// Roles are in the order they first appear; permissions are in
  /// ``SchemaPermission`` case order (`READ`, `CREATE`, `WRITE`).
  public var mergedGrants: [SchemaGrant] {
    var roles: [String] = []
    var permissions: [String: Set<SchemaPermission>] = [:]
    for grant in grants {
      if permissions[grant.role] == nil {
        roles.append(grant.role)
      }
      permissions[grant.role, default: []].formUnion(grant.permissions)
    }
    return roles.map { role in
      SchemaGrant(
        permissions: SchemaPermission.allCases.filter {
          permissions[role]?.contains($0) == true
        },
        role: role
      )
    }
  }

  /// Every permission the record type's ``grants`` give `role`.
  public func permissions(for role: String) -> Set<SchemaPermission> {
    Set(grants.filter { $0.role == role }.flatMap(\.permissions))
  }

  /// The field with this exact name, counting the implicit system fields the
  /// schema doesn't list (``fieldsIncludingImplicit``).
  public func fieldIncludingImplicit(named name: String) -> SchemaField? {
    field(named: name) ?? SchemaField.implicitSystemFields.first { $0.name == name }
  }
}
