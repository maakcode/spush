//  Copyright © 2019 Makeeyaf. All rights reserved

import Foundation

enum PushbulletError: Error {
    case RuntimeError(String)
    case NetworkError(String)
    case AuthError(String)
}

struct Pushbullet {
    // MARK: - Private Properties

    private enum PBurl: String {
        case Devices = "https://api.pushbullet.com/v2/devices"
        case Chats = "https://api.pushbullet.com/v2/chats"
        case Channels = "https://api.pushbullet.com/v2/channels"
        case Me = "https://api.pushbullet.com/v2/users/me"
        case Push = "https://api.pushbullet.com/v2/pushes"
        case UploadRequest = "https://api.pushbullet.com/v2/upload-request"
        case Ephemerals = "https://api.pushbullet.com/v2/ephemerals"

        var url: URL {
            return URL(string: rawValue)!
        }
    }
    
    private let apikey: String

    // MARK: - Private JSON Struct
    private struct Message: Codable {
        var type: String
        var title: String
        var body: String

        init(title: String, body: String, type: String = "note") {
            self.title = title
            self.body = body
            self.type = type
        }
    }


    // MARK: - Initializer

    init(apikey: String) {
        self.apikey = apikey
    }


    // MARK: - Public Functions

    func update() {
        fetch(url: PBurl.Me.url) { (result) in
            switch result {
            case .success(let message):
                print("success", message)
            case .failure(let error):
                print("error", error)
            }
        }
    }

    func push(title: String, body: String, compeletionHandler: @escaping (Result<String, Error>) -> Void) {
        let semaphore = DispatchSemaphore(value: 0)
        let message = Message(title: title, body: body)

        guard let data = try? JSONEncoder().encode(message) else {
            return compeletionHandler(.failure(PushbulletError.RuntimeError("JSON Encode Error")))
        }

        var request = URLRequest(url: PBurl.Push.url)
        request.timeoutInterval = TimeInterval(10)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(self.apikey, forHTTPHeaderField: "Access-Token")
        request.httpBody = data

        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            defer {
                semaphore.signal()
            }

            if let error = error {
                return compeletionHandler(.failure(error))
            }

            guard let data = data, let response = response as? HTTPURLResponse else {
                return compeletionHandler(.failure(PushbulletError.NetworkError("Empty responese")))
            }

            switch response.statusCode {
            case 200..<300:
                return compeletionHandler(.success(String(data: data, encoding: .utf8)!))
            case 401, 403:
                return compeletionHandler(.failure(PushbulletError.AuthError("Invalid Api Key. Code \(response.statusCode)")))
            case 429:
                return compeletionHandler(.failure(PushbulletError.AuthError("Too many Request")))
            default:
                return compeletionHandler(.failure(PushbulletError.NetworkError("Network Error. Code \(response.statusCode)")))
            }

        }

        task.resume()
        semaphore.wait()
    }

    // MARK: - Private Functions

    private func fetch(url: URL, compeletionHandler: @escaping (Result<String, Error>) -> Void) {
        let semaphore = DispatchSemaphore(value: 0)
        var request = URLRequest(url: url)
        request.timeoutInterval = TimeInterval(10)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(self.apikey, forHTTPHeaderField: "Access-Token")


        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            defer {
                semaphore.signal()
            }

            if let error = error {
                return compeletionHandler(.failure(error))
            }

            guard let data = data, let response = response as? HTTPURLResponse else {
                return compeletionHandler(.failure(PushbulletError.NetworkError("Empty responese")))
            }

            switch response.statusCode {
            case 200..<300:
                return compeletionHandler(.success(String(data: data, encoding: .utf8)!))
            case 401, 403:
                return compeletionHandler(.failure(PushbulletError.AuthError("Invalid Api Key")))
            case 429:
                return compeletionHandler(.failure(PushbulletError.AuthError("Too many Request")))
            default:
                return compeletionHandler(.failure(PushbulletError.NetworkError("Network Error code \(response.statusCode)")))
            }
        }

        task.resume()
        semaphore.wait()
    }



}
