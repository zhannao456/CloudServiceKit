//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import CryptoKit
import Foundation

public class PremiumizeServiceProvider: CloudServiceProvider {
    public var refreshAccessTokenHandler: CloudRefreshAccessTokenHandler?

    public var delegate: (any CloudServiceProviderDelegate)?

    public func copyItem(_ item: CloudItem, to directory: CloudItem, completion: @escaping CloudCompletionHandler) {}

    public func createFolder(_ folderName: String, at directory: CloudItem, completion: @escaping CloudCompletionHandler) {}

    public func moveItem(_ item: CloudItem, to directory: CloudItem, completion: @escaping CloudCompletionHandler) {}

    public func searchFiles(keyword: String, completion: @escaping (Result<[CloudItem], any Error>) -> Void) {}

    public func uploadData(
        _ data: Data,
        filename: String,
        to directory: CloudItem,
        progressHandler: @escaping ((Progress) -> Void),
        completion: @escaping CloudCompletionHandler
    ) {}

    public func uploadFile(
        _ fileURL: URL,
        to directory: CloudItem,
        progressHandler: @escaping ((Progress) -> Void),
        completion: @escaping CloudCompletionHandler
    ) {}

    public var name: String { "Premiumize" }

    public var credential: URLCredential?

    public var rootItem: CloudItem { CloudItem(id: "root", name: name, path: "/") }

    /// Upload chunsize which is 10M.
    public let chunkSize: Int64 = 10 * 1024 * 1024

    public var apiURL = URL(string: "https://www.premiumize.me/api")!

    public required init(credential: URLCredential?) {
        self.credential = credential
    }

    public func attributesOfItem(_ item: CloudItem, completion: @escaping (Result<CloudItem, Error>) -> Void) {
        let url = apiURL.appendingPathComponent("/item/details")
        var json = [String: Any]()
        json["id"] = item.id
        post(url: url, params: json) { response in
            switch response.result {
            case let .success(result):
                if let object = result.json as? [String: Any], let file = Self.cloudItemFromJSON(object) {
                    completion(.success(file))
                } else {
                    completion(.failure(CloudServiceError.responseDecodeError(result)))
                }
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func contentsOfDirectory(
        _ directory: CloudItem,
        nextMark: String? = nil,
        completion: @escaping (Result<(String, [CloudItem]), Error>) -> Void
    ) {
        var items: [CloudItem] = []

        var json: [String: Any] = [:]
        if directory.id != "root" {
            json["id"] = directory.id
        }
        json["includebreadcrumbs"] = true

        let url = apiURL.appendingPathComponent("/folder/list")
        post(url: url, params: json) { response in
            switch response.result {
            case let .success(result):
                if let object = result.json as? [String: Any],
                   let list = object["content"] as? [[String: Any]]
                {
                    let files = list.compactMap { Self.cloudItemFromJSON($0) }
                    files.forEach { $0.fixPath(with: directory) }
                    items.append(contentsOf: files)

                    completion(.success(("none", items)))
                } else {
                    completion(.failure(CloudServiceError.responseDecodeError(result)))
                }
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    /// Get information about the current user's account.
    /// - Parameter completion: Completion block.
    public func getCurrentUserInfo(completion: @escaping (Result<CloudUser, Error>) -> Void) {
        let url = apiURL.appendingPathComponent("/account/info")
        get(url: url) { response in
            switch response.result {
            case let .success(result):
                if let json = result.json as? [String: Any], let username = json["customer_id"] as? String {
                    let user = CloudUser(username: username, json: json)
                    completion(.success(user))
                } else {
                    completion(.failure(CloudServiceError.responseDecodeError(result)))
                }
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    /// Get the space usage information for the current user's account.
    /// - Parameter completion: Completion block.
    public func getCloudSpaceInformation(completion: @escaping (Result<CloudSpaceInformation, Error>) -> Void) {
        let url = apiURL.appendingPathComponent("/account/info")
        post(url: url) { response in
            switch response.result {
            case let .success(result):
                if let json = result.json as? [String: Any],
                   let usedSize = json["space_used"] as? Int64
                {
                    let cloudInfo = CloudSpaceInformation(totalSpace: 0, availableSpace: 0, json: json)
                    completion(.success(cloudInfo))
                } else {
                    completion(.failure(CloudServiceError.responseDecodeError(result)))
                }
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    /// Remove file/folder.
    /// - Parameters:
    ///   - item: The item to be removed.
    ///   - completion: Completion block.
    public func removeItem(_ item: CloudItem, completion: @escaping CloudCompletionHandler) {
        if item.isDirectory {
            let url = apiURL.appendingPathComponent("/folder/delete")
            var json = [String: Any]()
            json["id"] = item.id
            post(url: url, params: json, completion: completion)
        } else {
            let url = apiURL.appendingPathComponent("/item/delete")
            var json = [String: Any]()
            json["id"] = item.id
            post(url: url, params: json, completion: completion)
        }
    }

    /// Rename file/folder item.
    /// - Parameters:
    ///   - item: The item to be renamed.
    ///   - newName: The new name.
    ///   - completion: Completion block.
    public func renameItem(_ item: CloudItem, newName: String, completion: @escaping CloudCompletionHandler) {
        if item.isDirectory {
            let url = apiURL.appendingPathComponent("/folder/rename")
            var json = [String: Any]()
            json["id"] = item.id
            json["name"] = newName
            post(url: url, params: json, completion: completion)
        } else {
            let url = apiURL.appendingPathComponent("/item/rename")
            var json = [String: Any]()
            json["id"] = item.id
            json["name"] = newName
            post(url: url, params: json, completion: completion)
        }
    }
}

public extension PremiumizeServiceProvider {

    static func cloudItemFromJSON(_ json: [String: Any]) -> CloudItem? {
        guard let id = json["id"] as? String, let name = json["name"] as? String else {
            return nil
        }
        let isFolder = (json["type"] as? String) == "folder"
        let item = CloudItem(id: id, name: name, path: name, isDirectory: isFolder, json: json)

        if let ctime = json["created_at"] as? Int64 {
            item.creationDate = Date(timeIntervalSince1970: TimeInterval(ctime))
        }

        item.size = (json["size"] as? Int64) ?? -1
        return item
    }

    func shouldProcessResponse(_ response: HTTPResult, completion: @escaping CloudCompletionHandler) -> Bool {
        guard let json = response.json as? [String: Any] else { return false }
        if response.statusCode == 409 { return false }
        if let _ = json["code"] as? String, let msg = json["message"] as? String {
            completion(CloudResponse(response: response, result: .failure(CloudServiceError.serviceError(-1, msg))))
            return true
        }
        return false
    }
}
