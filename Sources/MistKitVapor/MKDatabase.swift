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
//    let next = promise.futureResult.mapEach(RecordType.content(fromRecord:))
//    return next.flatMapAlways { result in
//      eventLoop.future(result: Result(catching: { try MKServerResponse(fromResult: result) }))
//    }
  }

  func perform<RecordType: MKContentRecord, EncodedType>(operations: ModifyRecordQueryRequest<RecordType>, on eventLoop: EventLoop) -> EventLoopFuture<ModifiedRecordQueryResult<RecordType>> where RecordType.ContentType == EncodedType {
    let promise = eventLoop.makePromise(of: ModifiedRecordQueryResult<RecordType>.self)
    perform(operations: operations, promise.completeWith)
    return promise.futureResult
//    let next = promise.futureResult.map(ModifiedRecordQueryContent.init(from:))
//    return next.flatMapAlways { (result) -> EventLoopFuture<MKServerResponse<ModifiedRecordQueryContent<EncodedType>>> in
//      eventLoop.future(result: Result(catching: { try MKServerResponse(fromResult: result) }))
//    }
  }

  func lookup<RecordType: MKContentRecord, EncodedType>(
    _ lookup: LookupRecordQueryRequest<RecordType>,
    on eventLoop: EventLoop
  ) -> EventLoopFuture<[RecordType]> where RecordType.ContentType == EncodedType {
    let promise = eventLoop.makePromise(of: [RecordType].self)
    self.lookup(lookup, promise.completeWith)
    return promise.futureResult
//    let next = promise.futureResult.mapEach(RecordType.content(fromRecord:))
//    return next.flatMapAlways { result in
//      eventLoop.future(result: Result(catching: { try MKServerResponse(fromResult: result) }))
//    }
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
