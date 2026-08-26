import Combine
import Foundation

/// Owns both Open Food Facts endpoints. Presentation binds to Combine publishers only.
final class BLGCatalogClient: Sendable {
    static let userAgent = "BiteLedger/1.0 (iOS; +https://biteledger.pro)"
    static let searchFields = "code,product_name,generic_name,brands,nutriments,image_small_url,image_url,image_front_small_url"

    private let session: URLSession

    init(session: URLSession? = nil) {
        if let session {
            self.session = session
            return
        }
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 15
        configuration.timeoutIntervalForResource = 15
        configuration.httpAdditionalHeaders = ["User-Agent": Self.userAgent]
        self.session = URLSession(configuration: configuration)
    }

    func searchPublisher(terms: String) -> AnyPublisher<[BLGProduct], Error> {
        guard var parts = URLComponents(string: "https://world.openfoodfacts.org/api/v2/search") else {
            return Fail(error: BLGCatalogError.malformed).eraseToAnyPublisher()
        }
        parts.queryItems = [
            URLQueryItem(name: "search_terms", value: terms),
            URLQueryItem(name: "fields", value: Self.searchFields),
            URLQueryItem(name: "page_size", value: "16")
        ]
        guard let url = parts.url else {
            return Fail(error: BLGCatalogError.malformed).eraseToAnyPublisher()
        }
        return dataPublisher(url: url)
            .decode(type: BLGSearchDTO.self, decoder: JSONDecoder())
            .map { dto in
                (dto.products ?? []).compactMap { $0.mapped() }
            }
            .mapError { error in Self.mapped(error) }
            .eraseToAnyPublisher()
    }

    func productPublisher(code: String) -> AnyPublisher<BLGProduct, Error> {
        guard let url = URL(string: "https://world.openfoodfacts.org/api/v2/product/\(code).json") else {
            return Fail(error: BLGCatalogError.malformed).eraseToAnyPublisher()
        }
        return dataPublisher(url: url)
            .tryMap { data in
                let dto: BLGProductResponseDTO
                do {
                    dto = try JSONDecoder().decode(BLGProductResponseDTO.self, from: data)
                } catch {
                    throw BLGCatalogError.malformed
                }
                if dto.status == 0 {
                    throw BLGCatalogError.notFound
                }
                guard let product = dto.product?.mapped(fallbackCode: code) else {
                    throw BLGCatalogError.notFound
                }
                return product
            }
            .mapError { error in Self.mapped(error) }
            .eraseToAnyPublisher()
    }

    private func dataPublisher(url: URL) -> AnyPublisher<Data, Error> {
        var request = URLRequest(url: url)
        request.setValue(Self.userAgent, forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 15
        let first = session.dataTaskPublisher(for: request)
            .tryMap { output -> Data in
                if let http = output.response as? HTTPURLResponse {
                    if http.statusCode == 404 {
                        throw BLGCatalogError.notFound
                    }
                    if http.statusCode >= 500 {
                        throw BLGCatalogError.transport
                    }
                }
                return output.data
            }
            .eraseToAnyPublisher()
        return first
            .catch { error -> AnyPublisher<Data, Error> in
                if Self.isTransient(error) {
                    return self.session.dataTaskPublisher(for: request)
                        .map(\.data)
                        .mapError { _ in BLGCatalogError.transport }
                        .eraseToAnyPublisher()
                }
                return Fail(error: Self.mapped(error)).eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    private static func isTransient(_ error: Error) -> Bool {
        if let catalog = error as? BLGCatalogError {
            return catalog == .transport
        }
        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain {
            switch nsError.code {
            case NSURLErrorTimedOut, NSURLErrorNetworkConnectionLost, NSURLErrorNotConnectedToInternet:
                return true
            default:
                return false
            }
        }
        return false
    }

    private static func mapped(_ error: Error) -> Error {
        if let catalog = error as? BLGCatalogError {
            return catalog
        }
        if error is DecodingError {
            return BLGCatalogError.malformed
        }
        return BLGCatalogError.transport
    }
}
