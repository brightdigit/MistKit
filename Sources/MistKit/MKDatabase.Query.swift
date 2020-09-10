extension MKDatabase {
  public func query<RecordType: MKQueryRecord>(
    _ query: FetchRecordQueryRequest<MKQuery<RecordType>>,
    _ callback: @escaping ((MKResult<[RecordType], Error>) -> Void)
  ) {
    perform(request: query) {
      callback($0.tryFlatmap(recordsTo: RecordType.self))
    }
  }
}

extension MKResult {
  func tryFlatmap<RecordType: MKQueryRecord>(recordsTo _: RecordType.Type) -> MKResult<[RecordType], Error> where Success == FetchRecordQueryResponse {
    let records: [RecordType]
    let success: FetchRecordQueryResponse
    switch self {
    case let .success(found): success = found
    case let .failure(error): return .failure(error)
    case let .authenticationRequired(redirect): return .authenticationRequired(redirect)
    }
    do {
      records = try success.records.map(
        RecordType.init(record:)
      )
    } catch {
      return .failure(error)
    }
    return .success(records)
  }
}
