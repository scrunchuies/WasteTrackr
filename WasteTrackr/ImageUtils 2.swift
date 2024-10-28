//
//  ImageUtils 2.swift
//  WasteTrackr
//
//  Created by Piotr Jandura on 10/27/24.
//


import UIKit

class ImageUtils {
    
    static func saveImageToDocumentsDirectory(image: UIImage, forImageName imageName: String) {
        if let data = image.jpegData(compressionQuality: 1.0) {
            let filePath = getDocumentsDirectory().appendingPathComponent(imageName)
            do {
                try data.write(to: filePath)
                print("Image saved locally at: \(filePath)")
            } catch {
                print("Error saving image: \(error)")
            }
        }
    }
    
    static func loadImageFromDocumentsDirectory(named imageName: String) -> UIImage? {
        let filePath = getDocumentsDirectory().appendingPathComponent(imageName)
        if FileManager.default.fileExists(atPath: filePath.path) {
            return UIImage(contentsOfFile: filePath.path)
        }
        return nil
    }
    
    private static func getDocumentsDirectory() -> URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}
