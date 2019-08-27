import Foundation

public enum AuthenticationError: Error {
    case unauthorised
    case serverError
    case dataError
    case badResponse
}

public final class Authentication: NSObject {
    
    private var tokenURL: String { return "http://playground.tesonet.lt/v1/tokens" }
    
    public func getAuthenticationToken(with username: String, password: String, completion: @escaping (_ error: Error?, _ data: Data?)->Void) {
        
        guard let request = request(with: ["username":username, "password":password])
        else { return }
        
        dataTask(with: request, completion: completion)
    }
    
    private func request(with payload: [String:String]) -> URLRequest? {
        guard let url = URL(string: tokenURL) else { return nil }

        do {
            let requestData = try JSONSerialization.data(withJSONObject: payload, options: .prettyPrinted)
            var request = URLRequest(url: url, cachePolicy: .reloadIgnoringCacheData, timeoutInterval: 120)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = requestData
            return request
        } catch {
            print(error)
            return nil
        }
    }
    
    private func dataTask(with request: URLRequest, completion: @escaping (_ error: Error?, _ data: Data?)->Void) {
        
        let session = URLSession(configuration: .default)
        let task = session.dataTask(with: request) { data, response, error in
            guard let response = response as? HTTPURLResponse else {
                completion(AuthenticationError.badResponse, nil)
                return
            }
            switch response.statusCode {
            case 200...299: completion(nil, data)
            case 401: completion(AuthenticationError.unauthorised, nil)
            case 500: completion(AuthenticationError.serverError, nil)
            default: completion(AuthenticationError.dataError, nil)
            }
        }
        task.resume()
    }
}
