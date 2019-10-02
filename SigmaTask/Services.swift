//
//  Services.swift
//  SigmaTask
//
//  Created by Vinh Nguyen on 2019/10/02.
//  Copyright © 2019 GCS. All rights reserved.
//

import Foundation

enum HTTPMethodType: String {
    case post = "POST"
    case put = "PUT"
    case get = "GET"
    case delete = "DELETE"
}

class Network {
    typealias T = Any
    typealias completionHandler = ((_ success: Bool, _ result: T?) -> Void)
    
    var token: String? {
        return ""
    }
    
    private let endPoint: String
    
    public init(_ endPoint: String) {
        self.endPoint = endPoint
    }
    
    func getItems(_ path: String, completion: @escaping (completionHandler)) {
        let absolutePath = "\(endPoint)/\(path)"
        get(request: clientURLRequest(path: absolutePath, params: nil)) { (success, data) -> () in
            print("Get Items \(absolutePath):  success: \(success) data: \(String(describing: data))")
            if success {
                completion(true, data)
            } else {
                completion(false, nil)
            }
        }
    }
    
    func getItem(_ path: String, itemId: String, completion: @escaping (completionHandler)) {
        let absolutePath = "\(endPoint)/\(path)/\(itemId)"
        get(request: clientURLRequest(path: absolutePath, params: nil)) { (success, data) -> () in
            print("Get Item \(absolutePath): success: \(success) data: \(String(describing: data))")
            if success {
                completion(true, data)
            } else {
                completion(false, nil)
            }
        }
    }
    
    func postItem(_ path: String, parameters: [String: Any], completion: @escaping (completionHandler)) {
        let absolutePath = "\(endPoint)/\(path)"
        print("Post Item \(absolutePath): \(parameters)")
        post(request: clientURLRequest(path: absolutePath, params: parameters)) { (success, data) -> () in
            if success {
                completion(true, data)
            } else {
                completion(false, nil)
            }
        }
    }
    
    func updateItem(_ path: String, itemId: String, parameters: [String: Any], completion: @escaping (completionHandler)) {
        let absolutePath = "\(endPoint)/\(path)/\(itemId)"
        print("Update Item \(absolutePath): \(parameters)")
        put(request: clientURLRequest(path: absolutePath, params: parameters)) { (success, data) -> () in
            if success {
                completion(true, data)
            } else {
                completion(false, nil)
            }
        }
    }
    
    func deleteItem(_ path: String, itemId: String, completion: @escaping (completionHandler)) {
        let absolutePath = "\(endPoint)/\(path)/\(itemId)"
        delete(request: clientURLRequest(path: absolutePath, params: nil)) { (success, data) -> () in
            if success {
                completion(true, data)
            } else {
                completion(false, nil)
            }
        }
    }
}

// MARK: - Helper
extension Network {
    fileprivate func get(request: NSMutableURLRequest, completion: @escaping (_ success: Bool, _ object: Any?) -> ()) {
        self.dataTask(request: request, method: HTTPMethodType.get.rawValue, completion: completion)
    }
    
    fileprivate func post(request: NSMutableURLRequest, completion: @escaping (_ success: Bool, _ object: Any?) -> ()) {
        self.dataTask(request: request, method: HTTPMethodType.post.rawValue, completion: completion)
    }
    
    fileprivate func put(request: NSMutableURLRequest, completion: @escaping (_ success: Bool, _ object: Any?) -> ()) {
        self.dataTask(request: request, method: HTTPMethodType.put.rawValue, completion: completion)
    }
    
    fileprivate func delete(request: NSMutableURLRequest, completion: @escaping (_ success: Bool, _ object: Any?) -> ()) {
        self.dataTask(request: request, method: HTTPMethodType.delete.rawValue, completion: completion)
    }
    
    fileprivate func clientURLRequest(path: String, params: [String: Any]? = nil) -> NSMutableURLRequest {
        let request = NSMutableURLRequest(url: URL(string: path)!)
        if let params = params {
            do {
                request.httpBody = try? JSONSerialization.data(withJSONObject: params, options: .prettyPrinted)
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            }
        }
        
        if let token = token {
            request.addValue("Bearer " + token, forHTTPHeaderField: "Authorization")
        }
        
        return request
    }
    
    private func dataTask(request: NSMutableURLRequest, method: String, completion: @escaping (_ success: Bool, _ object: Any?) -> ()) {
        request.httpMethod = method
        
        URLSession.shared.dataTask(with: request as URLRequest) { (data, response, error) in
            if let data = data {
                let json = try? JSONSerialization.jsonObject(with: data, options: [])
                if let response = response as? HTTPURLResponse, 200...299 ~= response.statusCode {
                    completion(true, json)
                } else {
                    completion(false, json)
                }
            }
        }.resume()
    }
}
