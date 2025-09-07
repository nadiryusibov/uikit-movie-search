import UIKit

final class ImageLoader {
    static let shared = ImageLoader()
    private init(){}
    private let cache = NSCache<NSURL,UIImage>()
    
    // sekil getirek
    func image(from url: URL) async throws -> UIImage {
        let nsURL = url as NSURL
        if let cached = cache.object(forKey: nsURL) {
            return cached
        }
        
        
        let (data, _) = try await URLSession.shared.data(from: url)
        guard let image = UIImage(data: data) else {
            throw URLError(.cannotDecodeContentData)
        }
        
        cache.setObject(image, forKey: nsURL)
        return image
    }
    
    
    
}
