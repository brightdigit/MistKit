//
//  ArrayChunkedTests.swift
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

import Foundation
@testable import MistKit
import Testing

@Suite("Array Chunked Tests")
struct ArrayChunkedTests {
  @Test("chunked splits array into correct chunks")
  func chunkedSplitsCorrectly() {
    let array = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
    let chunks = array.chunked(into: 3)

    #expect(chunks.count == 4)
    #expect(chunks[0] == [1, 2, 3])
    #expect(chunks[1] == [4, 5, 6])
    #expect(chunks[2] == [7, 8, 9])
    #expect(chunks[3] == [10])
  }

  @Test("chunked handles exact multiple of chunk size")
  func chunkedExactMultiple() {
    let array = [1, 2, 3, 4, 5, 6]
    let chunks = array.chunked(into: 2)

    #expect(chunks.count == 3)
    #expect(chunks[0] == [1, 2])
    #expect(chunks[1] == [3, 4])
    #expect(chunks[2] == [5, 6])
  }

  @Test("chunked handles remainder elements")
  func chunkedWithRemainder() {
    let array = [1, 2, 3, 4, 5]
    let chunks = array.chunked(into: 2)

    #expect(chunks.count == 3)
    #expect(chunks[0] == [1, 2])
    #expect(chunks[1] == [3, 4])
    #expect(chunks[2] == [5])
  }

  @Test("chunked handles empty array")
  func chunkedEmptyArray() {
    let array: [Int] = []
    let chunks = array.chunked(into: 5)

    #expect(chunks.isEmpty)
  }

  @Test("chunked handles single element")
  func chunkedSingleElement() {
    let array = [42]
    let chunks = array.chunked(into: 5)

    #expect(chunks.count == 1)
    #expect(chunks[0] == [42])
  }

  @Test("chunked handles chunk size larger than array")
  func chunkedLargerChunkSize() {
    let array = [1, 2, 3]
    let chunks = array.chunked(into: 10)

    #expect(chunks.count == 1)
    #expect(chunks[0] == [1, 2, 3])
  }

  @Test("chunked respects CloudKit 200-item limit", arguments: [200, 199, 201, 400, 600])
  func chunkedCloudKitLimit(totalItems: Int) {
    let array = Array(1...totalItems)
    let chunks = array.chunked(into: 200)

    // Verify all chunks except last are exactly 200
    for (index, chunk) in chunks.enumerated() {
      if index < chunks.count - 1 {
        #expect(chunk.count == 200)
      } else {
        // Last chunk can be <= 200
        #expect(chunk.count <= 200)
      }
    }

    // Verify we didn't lose any elements
    let totalElements = chunks.flatMap { $0 }.count
    #expect(totalElements == totalItems)
  }

  @Test("chunked with chunk size 1")
  func chunkedSizeOne() {
    let array = [1, 2, 3, 4, 5]
    let chunks = array.chunked(into: 1)

    #expect(chunks.count == 5)
    for (index, chunk) in chunks.enumerated() {
      #expect(chunk == [index + 1])
    }
  }

  @Test("chunked preserves element order")
  func chunkedPreservesOrder() {
    let array = ["a", "b", "c", "d", "e", "f", "g"]
    let chunks = array.chunked(into: 3)

    let flattened = chunks.flatMap { $0 }
    #expect(flattened == array)
  }

  @Test("chunked with different element types")
  func chunkedDifferentTypes() {
    struct TestItem: Equatable {
      let id: Int
      let name: String
    }

    let items = [
      TestItem(id: 1, name: "a"),
      TestItem(id: 2, name: "b"),
      TestItem(id: 3, name: "c"),
      TestItem(id: 4, name: "d")
    ]

    let chunks = items.chunked(into: 2)

    #expect(chunks.count == 2)
    #expect(chunks[0].count == 2)
    #expect(chunks[1].count == 2)
    #expect(chunks[0][0].id == 1)
    #expect(chunks[1][0].id == 3)
  }

  @Test("chunked large array performance")
  func chunkedLargeArray() {
    let array = Array(1...10_000)
    let chunks = array.chunked(into: 200)

    #expect(chunks.count == 50)
    #expect(chunks.allSatisfy { $0.count <= 200 })

    let totalElements = chunks.flatMap { $0 }.count
    #expect(totalElements == 10_000)
  }

  @Test("chunked with various CloudKit batch sizes", arguments: [50, 100, 150, 200, 250])
  func chunkedVariousBatchSizes(batchSize: Int) {
    let array = Array(1...1_000)
    let chunks = array.chunked(into: batchSize)

    // Verify no chunk exceeds batch size
    #expect(chunks.allSatisfy { $0.count <= batchSize })

    // Verify we didn't lose any elements
    let totalElements = chunks.flatMap { $0 }.count
    #expect(totalElements == 1_000)

    // Verify all chunks except last are full
    for (index, chunk) in chunks.enumerated() {
      if index < chunks.count - 1 {
        #expect(chunk.count == batchSize)
      }
    }
  }
}
