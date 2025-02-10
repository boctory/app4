import UIKit

enum ImagenError: LocalizedError {
    case invalidResponse
    case apiError(String)
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from server"
        case .apiError(let message):
            return message
        case .networkError(let error):
            return error.localizedDescription
        }
    }
}

class ImagenService {
    private let baseURL = "https://api.unsplash.com/photos/random"
    // Replace your actual Unsplash API key here
    private let apiKey = "YOUR_UNSPLASH_API_KEY"
    
    func generateImage(from prompt: String, completion: @escaping (Result<UIImage, ImagenError>) -> Void) {
        var urlComponents = URLComponents(string: baseURL)!
        urlComponents.queryItems = [
            URLQueryItem(name: "query", value: prompt),
            URLQueryItem(name: "orientation", value: "squarish"),
            URLQueryItem(name: "client_id", value: apiKey)  // Add client_id as query parameter
        ]
        
        var request = URLRequest(url: urlComponents.url!)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("v1", forHTTPHeaderField: "Accept-Version")
        request.timeoutInterval = 30
        
        print("Request URL: \(urlComponents.url?.absoluteString ?? "")")
        print("Request Headers: \(request.allHTTPHeaderFields ?? [:])")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Network Error: \(error)")
                completion(.failure(.networkError(error)))
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("Response Status Code: \(httpResponse.statusCode)")
                print("Response Headers: \(httpResponse.allHeaderFields)")
            }
            
            guard let data = data else {
                print("No Data Received")
                completion(.failure(.invalidResponse))
                return
            }
            
            print("Response Data: \(String(data: data, encoding: .utf8) ?? "")")
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    if let error = json["errors"] as? [String] {
                        print("API Error: \(error.joined(separator: ", "))")
                        completion(.failure(.apiError(error.joined(separator: ", "))))
                        return
                    }
                    
                    if let urls = json["urls"] as? [String: Any],
                       let regularUrl = urls["regular"] as? String,
                       let imageUrl = URL(string: regularUrl) {
                        // Download the actual image
                        URLSession.shared.dataTask(with: imageUrl) { imageData, _, _ in
                            if let imageData = imageData,
                               let image = UIImage(data: imageData) {
                                print("Successfully downloaded image")
                                completion(.success(image))
                            } else {
                                print("Failed to create image from data")
                                completion(.failure(.invalidResponse))
                            }
                        }.resume()
                    } else {
                        print("No image URL found in response")
                        completion(.failure(.invalidResponse))
                    }
                } else {
                    print("Invalid JSON response format")
                    completion(.failure(.invalidResponse))
                }
            } catch {
                print("JSON Parsing Error: \(error)")
                completion(.failure(.networkError(error)))
            }
        }.resume()
    }
} 