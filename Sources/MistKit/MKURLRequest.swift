import Foundation

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

public struct MKURLRequest: MKHttpRequest {
  public let urlRequest: URLRequest
  public let urlSession: URLSession
  public func execute(_ callback: @escaping ((Result<MKHttpResponse, Error>) -> Void)) {
    urlSession.dataTask(with: urlRequest) { data, response, error in
      let result: Result<MKHttpResponse, Error>
      if let error = error {
        result = .failure(error)
      } else if let response = response as? HTTPURLResponse {
        result = .success(MKURLResponse(body: data, response: response))
      } else if let response = response {
        result = .failure(MKError.invalidReponse(response))
      } else {
        result = .failure(MKError.empty)
      }
      callback(result)
    }.resume()
  }
}
