import MistKit
import NIO

public extension MKDatabase {
  func query<RecordType: MKContentRecord, EncodedType>(
    _ query: FetchRecordQueryRequest<MKQuery<RecordType>>,
    on eventLoop: EventLoop
  ) -> EventLoopFuture<MKServerResponse<[EncodedType]>> where RecordType.ContentType == EncodedType {
    let promise = eventLoop.makePromise(of: [RecordType].self)
    self.query(query, promise.completeWith)
    let next = promise.futureResult.mapEach(RecordType.content(fromRecord:))
    return next.flatMapAlways { result in
      eventLoop.future(result: Result(catching: { try MKServerResponse(fromResult: result) }))
    }
  }

  func perform<RecordType: MKContentRecord, EncodedType>(operations: ModifyRecordQueryRequest<RecordType>, on eventLoop: EventLoop) -> EventLoopFuture<MKServerResponse<ModifiedRecordQueryContent<EncodedType>>> where RecordType.ContentType == EncodedType {
    let promise = eventLoop.makePromise(of: ModifiedRecordQueryResult<RecordType>.self)

    perform(operations: operations, promise.completeWith)
    let next = promise.futureResult.map(ModifiedRecordQueryContent.init(from:))
    return next.flatMapAlways { (result) -> EventLoopFuture<MKServerResponse<ModifiedRecordQueryContent<EncodedType>>> in
      eventLoop.future(result: Result(catching: { try MKServerResponse(fromResult: result) }))
    }
  }
}
