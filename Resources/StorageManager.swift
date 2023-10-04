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
    
    /// Upload image that will be sent in a conversation message
    public func uploadMessagePhoto(with data: Data, fileName: String, completion: @escaping UploadPicturCompletion) {
        
        storage.child("message_images/\(fileName)").putData(data, metadata: nil) { [weak self] metadata, error in
            
            guard error == nil else {
                //failed
                print("Failed to upload data to firebase for storage")
                completion(.failure(StorageErrors.FailedToUpload))
                return
            }
                           
            self?.storage.child("message_images/\(fileName)").downloadURL { url, error in
                
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
    
    /// Upload video that will be sent in a conversation message
    public func uploadMessageVideo(with fileUrl: URL, fileName: String, completion: @escaping UploadPicturCompletion) {
        
        storage.child("message_videos/\(fileName)").putFile(from: fileUrl, metadata: nil) { [weak self] metadata, error in
            
            guard error == nil else {
                //failed
                print("Failed to upload video file to firebase for storage")
                completion(.failure(StorageErrors.FailedToUpload))
                return
            }
                           
            self?.storage.child("message_videos/\(fileName)").downloadURL { url, error in
                
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
    
    /// Upload audio that will be sent in a conversation message
    public func uploadMessageAudio(with data: Data, fileName: String, completion: @escaping UploadPicturCompletion) {
        
        storage.child("message_audios/\(fileName)").putData(data, metadata: nil) { [weak self] metadata, error in
            
            guard error == nil else {
                //failed
                print("Failed to upload audio file to firebase for storage: ",error?.localizedDescription)
                completion(.failure(StorageErrors.FailedToUpload))
                return
            }
                           
            self?.storage.child("message_audios/\(fileName)").downloadURL { url, error in
                
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
    
    public func downloadUrl(for path: String, completion: @escaping (Result<URL, Error>) -> Void) {
        
        let reference = storage.child(path)
        
        reference.downloadURL { url, error in
            guard let url = url, error == nil else {
                completion(.failure(StorageErrors.FailedToGetDownloadUrl))
                return
            }
            
            completion(.success(url))
        }
        
    }
}

func fileInDocumentsDirectory(fileName: String) -> String {
    return getDocumentsURL().appendingPathComponent(fileName).path
}

func getDocumentsURL() -> URL {
    return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last!
}


func fileExistsAtPath(path: String)  -> Bool {
    print(path)
    return FileManager.default.fileExists(atPath: fileInDocumentsDirectory(fileName: path))
}

func fileNameFrom(fileURL : String) -> String {
    let fileName = ((fileURL.components(separatedBy: "_").last!).components(separatedBy: "?").first!).components(separatedBy: ".").first!
    print(fileName)
    return fileName
}
