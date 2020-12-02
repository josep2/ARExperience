//
//  NetworkManager.swift
//  ARExperience
//
//  Created by Jowanza Joseph on 11/22/20.
//

import Foundation
import ARGear

let API_HOST = "https://apis.argear.io/api/v3/"
let API_KEY = "4a894f46c7bb9240b4dc5208"
let API_SECRET_KEY = "7b436c6ba24d52ffb541af36291f9f999fad44daee5f051a79e954aa41f85f6e"
let API_AUTH_KEY = "U2FsdGVkX19NiJtiqZTSqNXrgz/Ut2y2FzSY9YsnJmvLPbrMudaF2NrDL9fojwgC"

enum APIError: Error {
    case network
    case data
    case serializeJSON
}

enum DownloadError: Error {
    case network
    case auth
    case content
}

class NetworkManager {

    static let shared = NetworkManager()
    
    var argSession: ARGSession?
    
    init() {
    }
    
    func connectAPI(completion: @escaping (Result<[String: Any], APIError>) -> Void) {
        
        let urlString = API_HOST + API_KEY
        let url = URL(string: urlString)!
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let _ = error {
                return completion(.failure(.network))
            } else {
                guard let data = data else {
                    return completion(.failure(.data))
                }
                
                guard let json: [String : Any] = try? JSONSerialization.jsonObject(with: data, options: []) as? [String : Any] else {
                    return completion(.failure(.serializeJSON))
                }
                
                completion(.success(json))
            }
        }
        task.resume()
    }
    
    func downloadItem(_ item: Item, completion: @escaping (Result<URL, DownloadError>) -> Void) {
        guard let session = self.argSession, let auth = session.auth
            else {
                completion(.failure(.auth))
                return
        }
        
        guard let zipUrl = item.zip_file
            else {
                completion(.failure(.content))
                return
        }

        let authCallback : ARGAuthCallback = {(url: String?, code: ARGStatusCode) in
            if (code.rawValue == ARGStatusCode.SUCCESS.rawValue) {
                guard let url = url
                    else {
                        completion(.failure(.auth))
                        return
                }
                
                // download task
                let authUrl = URL(string: url)!
                let task = URLSession.shared.downloadTask(with: authUrl) { (downloadUrl, response, error) in
                   if error != nil {
                       completion(.failure(.network))
                       return
                   }

                   guard
                       let httpResponse = response as? HTTPURLResponse,
                       let response = response,
                       let downloadUrl = downloadUrl
                       else {
                           completion(.failure(.network))
                           return
                   }

                   if httpResponse.statusCode == 200 {
                       guard
                           var cachesDirectory = FileManager.default.urls(for: .cachesDirectory, in: .allDomainsMask).first,
                           let suggestedFilename = response.suggestedFilename
                           else {
                               completion(.failure(.content))
                               return
                       }
                       cachesDirectory.appendPathComponent(suggestedFilename)

                       let fileManager = FileManager.default
                       // remove
                       do {
                           try fileManager.removeItem(at: cachesDirectory)
                       } catch {
                       }
                       // copy
                       do {
                           try fileManager.copyItem(at: downloadUrl, to: cachesDirectory)
                       } catch {
                           completion(.failure(.content))
                           return
                       }

                       completion(.success(cachesDirectory))
                       return
                   }
                   completion(.failure(.network))
                }
                task.resume()
            } else {
                if code.rawValue > ARGStatusCode.VALID_AUTH.rawValue {
                    completion(.failure(.auth))
                } else {
                    completion(.failure(.network))
                }
            }
        }

        auth.requestSignedUrl(withUrl: zipUrl, itemTitle: item.title ?? "", itemType: item.type ?? "", completion: authCallback)
    }
}
