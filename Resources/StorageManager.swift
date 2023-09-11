//
//  StorageManager.swift
//  FlowTalk
//
//  Created by Hakan Körhasan on 11.09.2023.
//

import UIKit
import FirebaseStorage

class StorageManager {
    
    static let shared = StorageManager()
    
    private let storage = Storage.storage().reference()
    
    /*
     /images/hakan-gmail-com_profile_picture.png
     */
    
    public typealias UploadPicturCompletion = (Result<String, Error>) -> Void
    
    /// Uploads picture to firebase storage and returns completion with url string to download
    public func uploadProfilePicture(with data: Data, fileName: String, completion: @escaping UploadPicturCompletion) {
        
        storage.child("images/\(fileName)").putData(data, metadata: nil) { metadata, error in
            
            guard error == nil else {
                //failed
                print("Failed to upload data to firebase for storage")
                completion(.failure(StorageErrors.FailedToUpload))
                return
            }
                           
            self.storage.child("images/\(fileName)").downloadURL { url, error in
                
                guard error == nil else {
                    print("Failed to get download url")
                    completion(.failure(StorageErrors.FailedToGetDownloadUrl))
                    return
                }
                
                let urlString = url?.absoluteString
                print("Download url returned: \(urlString)")
                completion(.success(urlString ?? ""))
            }
        }
    }
                
                
    public enum StorageErrors: Error {
        case FailedToUpload
        case FailedToGetDownloadUrl
    }
}
