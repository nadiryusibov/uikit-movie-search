import Foundation

enum APIError: Error {
    case invalidURL
    case server(String)
    case decoding
    case unknown
}

private struct OmdbSearchResponse: Decodable {
    let Search: [OmdbItem]?
    let totalResults: String?
    let Response : String
    let Error : String?
}

private struct OmdbItem: Decodable {
    let Title: String
    let Year: String
    let imdbID: String
    let `Type`: String?
    let Poster: String
}

private struct OmdbDetail: Decodable {
    let Title: String
    let Year: String
    let Plot: String
    let Poster: String
    let Response: String
    let Error: String?
}


final class APIClient {
    static let shared = APIClient()
    private init() {}
    
    private let base = "https://www.omdbapi.com/"
    
    private func get<T: Decodable>(_ queryItems:[URLQueryItem], as type: T.Type) async throws -> T {
        var comps = URLComponents(string: base)
        comps?.queryItems = ([URLQueryItem (name: "apikey", value: APIKeys.apiKey)] + queryItems)
        guard let url = comps?.url else {
            throw APIError.invalidURL
        }
        let (data, _) = try await URLSession.shared.data(from: url)
        do{
            return try JSONDecoder().decode(type, from: data)
        }catch {
            throw APIError.decoding
        }
        
    }
    
    // axtaris edilecek serverden
    
    func searchMovies(query: String) async throws -> [Movie] {
        let res: OmdbSearchResponse = try await get(
            [URLQueryItem(name: "s", value: query),
             URLQueryItem(name: "type", value: "movie")],
            as: OmdbSearchResponse.self
            
        )
  

        guard res.Response.lowercased() == "true", let items = res.Search,!items.isEmpty else {
            throw APIError.server(res.Error ?? "No results")
        }
        
//        print(" OMDb search '\(query)' → \(items.count) item")
//        let na = items.filter { $0.Poster.uppercased() == "N/A" }.count
//        print(" posters: \(na) N/A, \(items.count - na) URL")
//
//        for i in items.prefix(3) {
//            print("  sample:", i.Title, "| Poster:", i.Poster)
//        }

        
        return items.map{
            Movie(
                id: $0.imdbID,
                title: $0.Title,
                year: $0.Year,
                posterURL: URL(string: $0.Poster)
            )
        }
    }
    
    func fetchPlot(imdbID: String) async throws -> String {
        let detail: OmdbDetail = try await get(
            [URLQueryItem(name: "i", value: imdbID),
             URLQueryItem(name: "plot", value: "full")],
            as: OmdbDetail.self
        )
        guard detail.Response.lowercased() == "true" else {
            throw APIError.server(detail.Error ?? "Detail not found")
        }
        return detail.Plot
    }
    
    
    func fetchPosterURL(imdbID: String) async throws -> URL? {
        struct D: Decodable { let Poster: String; let Response: String; let Error: String? }
        let d: D = try await get(
            [URLQueryItem(name: "i", value: imdbID)],
            as: D.self
        )
        guard d.Response.lowercased() == "true", d.Poster.uppercased() != "N/A" else { return nil }
        return URL(string: d.Poster)
    }


}
