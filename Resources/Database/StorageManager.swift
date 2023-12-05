//
//  StorageManager.swift
//  FlowTalk
//
//  Created by Hakan Körhasan on 11.09.2023.
//

import UIKit
import FirebaseStorage


/// Allows you to get , fetch, and upload files to firebase storage
class StorageManager {
    
    static let shared = StorageManager()
    
    private let storage = Storage.storage().reference()
    
    /*
     /images/hakan-gmail-com_profile_picture.png
     */
    
    public typealias UploadPicturCompletion = (Result<String, Error>) -> Void
    
    /// Uploads picture to firebase storage and returns completion with url string to download
    public func uploadProfilePicture(with data: Data, fileName: String, completion: @escaping UploadPicturCompletion) {
        
        storage.child("images/\(fileName)").putData(data, metadata: nil) { [weak self] metadata, error in
            
            guard let strongSelf = self else {
                return
            }
            
            guard error == nil else {
                //failed
                print("Failed to upload data to firebase for storage")
                completion(.failure(StorageErrors.FailedToUpload))
                return
            }
                           
            strongSelf.storage.child("images/\(fileName)").downloadURL { url, error in
                
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
    
    public func deleteProfilePicture(fileName: String, completion: @escaping (Bool) -> Void) {
        
        storage.child("images/\(fileName)").delete { error in
            if let error = error {
                print("profile picture delete error: \(error)")
                completion(false)
            } else {
                print("Dosya silindi yenisini yükleyin")
                completion(true)
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
    public func uploadAudio(_ audioFileName: String, directory: String, completion: @escaping (_ audioLink: String?) -> Void) {
           
        let storageRef = storage.child("message_audios/\(audioFileName)")
        
            if let audioData = NSData(contentsOfFile: fileInDocumentsDirectory(fileName: audioFileName)) {
                
               storageRef.putData(audioData as Data, metadata: nil) { metadata, error in
                   
                   if error != nil {
                        print("error uploading audio \(error!.localizedDescription)")
                        return
                   }
                                       
                
                   storageRef.downloadURL { url, error in
                       guard let downloadUrl = url  else {
                            completion(nil)
                            return
                        }
                       print("download url: ",downloadUrl.absoluteString)
                        completion(downloadUrl.absoluteString)
                   }
                   
                }
            }
    }

    public enum StorageErrors: Error {
        case FailedToUpload
        case FailedToGetDownloadUrl
        case FailedToDeletePicture
    }
    
    let cache = NSCache<AnyObject, AnyObject>()
    
    public func downloadUrl(for path: String, completion: @escaping (Result<URL, Error>) -> Void) {
        
        if let cachedUrl = cache.object(forKey: path as AnyObject) as? URL {
            // Eğer önbellekte varsa, direkt olarak önbellekten döndür
            completion(.success(cachedUrl))
            return
        }
        
        let reference = storage.child(path)
    
        reference.downloadURL { url, error in
            guard let url = url, error == nil else {
                completion(.failure(StorageErrors.FailedToGetDownloadUrl))
                return
            }
            
            self.cache.setObject(url as AnyObject, forKey: path as AnyObject)

            completion(.success(url))
        }
        
    }
}

func fileInDocumentsDirectory(fileName: String) -> String {
    print("file in documenst directory: ",getDocumentsURL().appendingPathComponent(fileName).path)
    return getDocumentsURL().appendingPathComponent(fileName).path
}

func getDocumentsURL() -> URL {
    return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last!
}


func fileExistsAtPath(path: String)  -> Bool {
    print("file exits path: ", path)
    return FileManager.default.fileExists(atPath: fileInDocumentsDirectory(fileName: path))
}

func fileNameFrom(fileURL : String) -> String {
    let fileName = ((fileURL.components(separatedBy: "_").last!).components(separatedBy: "?").first!).components(separatedBy: ".").first!
    print(fileName)
    return fileName
}
