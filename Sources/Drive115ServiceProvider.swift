//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import CryptoKit
import Foundation

/// Drive115ServiceProvider
/// https://www.yuque.com/115yun/open/gv0l5007pczskivz
public class Drive115ServiceProvider: CloudServiceProvider {

    public var delegate: CloudServiceProviderDelegate?

    public var refreshAccessTokenHandler: CloudRefreshAccessTokenHandler?

    public var name: String { "115" }

    public var credential: URLCredential?

    public var rootItem: CloudItem { CloudItem(id: "0", name: name, path: "/") }

    public var apiURL = URL(string: "https://proapi.115.com")!

    public required init(credential: URLCredential?) {
        self.credential = credential
    }

    public func attributesOfItem(_ item: CloudItem, completion: @escaping (Result<CloudItem, Error>) -> Void) {
        completion(.success(item))
    }

    public func contentsOfDirectory(_ directory: CloudItem, completion: @escaping (Result<[CloudItem], Error>) -> Void) {

        var items: [CloudItem] = []

        func loadList(offset: Int?) {
            var params: [String: Any] = [:]
            params["limit"] = 100
            params["asc"] = "1"
            params["cid"] = directory.id
            params["show_dir"] = 1
            if let offset = offset {
                params["offset"] = offset
            }
            let url = apiURL.appendingPathComponent("/open/ufile/files")
            get(url: url, params: params) { response in
                switch response.result {
                case let .success(result):
                    if let object = result.json as? [String: Any],
                       let list = object["data"] as? [[String: Any]]
                    {
                        let files = list.compactMap { Self.cloudItemFromJSON($0) }
                        files.forEach { $0.fixPath(with: directory) }
                        items.append(contentsOf: files)

                        if let offset = object["offset"] as? Int, offset > 0 {
                            loadList(offset: offset)
                        } else {
                            completion(.success(items))
                        }
                    } else {
                        completion(.failure(CloudServiceError.responseDecodeError(result)))
                    }
                case let .failure(error):
                    completion(.failure(error))
                }
            }
        }

        loadList(offset: nil)
    }

    public func copyItem(_ item: CloudItem, to directory: CloudItem, completion: @escaping CloudCompletionHandler) {
        completion(.init(response: nil, result: .failure(CloudServiceError.unsupported)))
    }

    /// Create a folder at a given directory.
    /// - Parameters:
    ///   - folderName: The folder name to be created.
    ///   - directory: The target directory.
    ///   - completion: Completion block.
    public func createFolder(_ folderName: String, at directory: CloudItem, completion: @escaping CloudCompletionHandler) {
        let url = apiURL.appendingPathComponent("/open/folder/add")
        var data: [String: Any] = [:]
        data["pid"] = directory.id
        data["file_name"] = folderName
        post(url: url, data: data, completion: completion)
    }

    public func createFolder(_ folderName: String, at directory: CloudItem) async throws {
        try await withCheckedThrowingContinuation { continuation in
            createFolder(folderName, at: directory) { response in
                switch response.result {
                case .success:
                    continuation.resume(returning: ())
                case let .failure(error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /// Get the space usage information for the current user's account.
    /// - Parameter completion: Completion block.
    public func getCloudSpaceInformation(completion: @escaping (Result<CloudSpaceInformation, Error>) -> Void) {
        let url = apiURL.appendingPathComponent("/open/user/info")
        get(url: url) { response in
            switch response.result {
            case let .success(result):
                let json = result.json as? [String: Any]
                if let json = json,
                   let data = json["data"] as? [String: Any],
                   let info = data["rt_space_info"] as? [String: Any],
                   let totalSizeObject = info["all_total"] as? [String: Any],
                   let totalSize = totalSizeObject["size"] as? Int64,
                   let usedSizeObject = info["all_use"] as? [String: Any],
                   let usedSize = usedSizeObject["size"] as? Int64
                {
                    let cloudInfo = CloudSpaceInformation(totalSpace: totalSize, availableSpace: totalSize - usedSize, json: json)
                    completion(.success(cloudInfo))
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
        let url = apiURL.appendingPathComponent("/open/user/info")
        get(url: url) { response in
            switch response.result {
            case let .success(result):
                let json = result.json as? [String: Any]
                if let json = json, let data = json["data"] as? [String: Any],
                   let username = data["user_name"] as? String
                {
                    let user = CloudUser(username: username, json: data)
                    completion(.success(user))
                } else {
                    completion(.failure(CloudServiceError.responseDecodeError(result)))
                }
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func downloadRequest(item: CloudItem) async throws -> URLRequest {
        try await withCheckedThrowingContinuation { continuation in
            getDownloadUrl(of: item) { result in
                switch result {
                case let .success(url):
                    var request = URLRequest(url: url)
                    request.setValue("BoxPlayerIOS", forHTTPHeaderField: "User-Agent")
                    continuation.resume(returning: request)
                case let .failure(error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    public func mediaRequest(item: CloudItem) async throws -> URLRequest {
        try await withCheckedThrowingContinuation { continuation in
            getDownloadUrl(of: item, parameters: [:]) { result in
                switch result {
                case let .success(url):
                    var request = URLRequest(url: url)
                    request.setValue("BoxPlayerIOS", forHTTPHeaderField: "User-Agent")
                    continuation.resume(returning: request)
                case let .failure(error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /// Move file to directory.
    /// - Parameters:
    ///   - item: The item to be moved.
    ///   - directory: The target directory.
    ///   - completion: Completion block.
    public func moveItem(_ item: CloudItem, to directory: CloudItem, completion: @escaping CloudCompletionHandler) {
        let url = apiURL.appendingPathComponent("/open/ufile/move")
        var data = [String: Any]()
        data["file_ids"] = item.id
        data["to_cid"] = directory.id
        post(url: url, data: data, completion: completion)
    }

    /// Remove file/folder.
    /// - Parameters:
    ///   - item: The item to be removed.
    ///   - completion: Completion block.
    public func removeItem(_ item: CloudItem, completion: @escaping CloudCompletionHandler) {
        let url = apiURL.appendingPathComponent("/open/ufile/delete")
        var data = [String: Any]()
        data["file_ids"] = item.id
        post(url: url, data: data, completion: completion)
    }

    public func trashItem(_ item: CloudItem, completion: @escaping CloudCompletionHandler) {
        let url = apiURL.appendingPathComponent("/api/v1/file/trash")
        var data = [String: Any]()
        data["fileIDs"] = [item.id]
        post(url: url, data: data, completion: completion)
    }

    /// Rename file/folder item.
    /// - Parameters:
    ///   - item: The item to be renamed.
    ///   - newName: The new name.
    ///   - completion: Completion block.
    public func renameItem(_ item: CloudItem, newName: String, completion: @escaping CloudCompletionHandler) {
        let url = apiURL.appendingPathComponent("/open/ufile/update")
        var data: [String: Any] = [:]
        data["file_id"] = item.id
        data["file_name"] = newName
        post(url: url, data: data, completion: completion)
    }

    /// Search files by keyword.
    /// - Parameters:
    ///   - keyword: The keyword.
    ///   - completion: Completion block.
    public func searchFiles(keyword: String, completion: @escaping (Result<[CloudItem], Error>) -> Void) {
        let url = apiURL.appendingPathComponent("/open/ufile/search")
        var params: [String: Any] = [:]
        params["limit"] = 100
        params["offset"] = 0
        params["search_value"] = keyword
        params["pick_code"] = "0"

        get(url: url, params: params) { response in
            switch response.result {
            case let .success(result):
                if let object = result.json as? [String: Any], let list = object["items"] as? [[String: Any]] {
                    let items = list.compactMap { Self.cloudItemFromJSON($0) }
                    completion(.success(items))
                } else {
                    completion(.failure(CloudServiceError.responseDecodeError(result)))
                }
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func thumbnailRequest(item: CloudItem) async throws -> URLRequest {
        if let thumb = item.json["thumb"] as? String, let url = URL(string: thumb) {
            var request = URLRequest(url: url)
            return request
        } else {
            throw CloudServiceError.unsupported
        }
    }

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

    public func getDownloadUrlAsync(of item: CloudItem, parameters: [String: Any] = [:]) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            getDownloadUrl(of: item, parameters: parameters) { result in
                switch result {
                case let .success(url):
                    continuation.resume(returning: url.absoluteString)
                case let .failure(error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    public func getDownloadUrl(of item: CloudItem, parameters: [String: Any] = [:], completion: @escaping (Result<URL, Error>) -> Void) {
        let url = apiURL.appendingPathComponent("/open/ufile/downurl")
        var data: [String: Any] = [:]

        if let pickCode = item.json["pc"] as? String {
            data["pick_code"] = pickCode
        }

        if !parameters.isEmpty {
            for (key, value) in parameters {
                data[key] = value
            }
        }
        post(url: url, data: data, headers: ["User-Agent": "BoxPlayerIOS"]) { response in
            switch response.result {
            case let .success(result):
                if let json = result.json as? [String: Any],
                   let dataObject = json["data"] as? [String: Any],
                   let object = dataObject[item.id] as? [String: Any],
                   let urlObject = object["url"] as? [String: Any],
                   let urlString = urlObject["url"] as? String, let url = URL(string: urlString)
                {
                    // request download url must contains User-Agent: CloudServiceKit
                    completion(.success(url))
                } else {
                    completion(.failure(CloudServiceError.responseDecodeError(result)))
                }
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }
}

public extension Drive115ServiceProvider {
    static func cloudItemFromJSON(_ json: [String: Any]) -> CloudItem? {
        guard let fileId = json["fid"] as? String, let filename = json["fn"] as? String else {
            return nil
        }
        let isFolder = (json["fc"] as? String) == "0"
        let item = CloudItem(id: fileId, name: filename, path: filename, isDirectory: isFolder, json: json)
        item.size = json["fs"] as? Int64 ?? -1
        item.fileHash = json["sha1"] as? String
        return item
    }

    func getCurrentUserAsync() async throws -> CloudUser? {
        try await withCheckedThrowingContinuation { continuation in
            getCurrentUserInfo { userResult in
                switch userResult {
                case let .success(user):
                    continuation.resume(returning: user)
                case let .failure(error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
