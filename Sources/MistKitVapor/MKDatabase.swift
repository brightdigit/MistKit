import MistKit
import NIO

public extension MKDatabase {
  func query<RecordType: MKContentRecord, EncodedType>(
    _ query: FetchRecordQueryRequest<MKQuery<RecordType>>,
    on eventLoop: EventLoop
  ) -> EventLoopFuture<[RecordType]> where RecordType.ContentType == EncodedType {
    let promise = eventLoop.makePromise(of: [RecordType].self)
    self.query(query, promise.completeWith)
    return promise.futureResult
  }

  func perform<RecordType: MKContentRecord, EncodedType>(operations: ModifyRecordQueryRequest<RecordType>, on eventLoop: EventLoop) -> EventLoopFuture<ModifiedRecordQueryResult<RecordType>> where RecordType.ContentType == EncodedType {
    let promise = eventLoop.makePromise(of: ModifiedRecordQueryResult<RecordType>.self)
    perform(operations: operations, promise.completeWith)
    return promise.futureResult
  }

  func lookup<RecordType: MKContentRecord, EncodedType>(
    _ lookup: LookupRecordQueryRequest<RecordType>,
    on eventLoop: EventLoop
  ) -> EventLoopFuture<[RecordType]> where RecordType.ContentType == EncodedType {
    let promise = eventLoop.makePromise(of: [RecordType].self)
    self.lookup(lookup, promise.completeWith)
    return promise.futureResult
  }

  func perform<RequestType: MKRequest, ResponseType>(
    request: RequestType,
    returnFailedAuthentication: Bool = false,
    on eventLoop: EventLoop
  ) -> EventLoopFuture<ResponseType> where RequestType.Response == ResponseType {
    let promise = eventLoop.makePromise(of: ResponseType.self)
    perform(request: request, returnFailedAuthentication: returnFailedAuthentication, promise.completeWith)
    return promise.futureResult
  }
}

public extension EventLoopFuture {
  func content<RecordType: MKContentRecord, ContentType>() -> EventLoopFuture<MKServerResponse<[ContentType]>> where Value == [RecordType], RecordType.ContentType == ContentType {
    return mapEach(RecordType.content(fromRecord:)).mistKitResponse()
  }

  func content<RecordType: MKContentRecord, ContentType>() -> EventLoopFuture<MKServerResponse<ModifiedRecordQueryContent<ContentType>>> where Value == ModifiedRecordQueryResult<RecordType>, RecordType.ContentType == ContentType {
    return map(ModifiedRecordQueryContent.init).mistKitResponse()
  }
}

public extension EventLoopFuture where Value: Codable {
  func mistKitResponse() -> EventLoopFuture<MKServerResponse<Value>> {
    map(MKServerResponse.success).flatMapErrorThrowing(MKServerResponse.init(attemptRecoveryFrom:))
  }
}
