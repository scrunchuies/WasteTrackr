//
//  Item.swift
//  WasteTrackr
//
//  Created by Piotr Jandura on 5/8/24.
//

import UIKit
import FirebaseFirestore

struct Item {
    var id: String
    var name: String
    var count: Int
    var color: UIColor
    var timestamp: Timestamp
    var imageName: String? // Add imageName field
    
    init(id: String, name: String, count: Int, color: UIColor, timestamp: Timestamp, imageName: String?) {
        self.id = id
        self.name = name
        self.count = count
        self.color = color
        self.timestamp = timestamp
        self.imageName = imageName
    }
    
    init?(document: DocumentSnapshot) {
        let data = document.data()
        print("Document data: \(String(describing: data))")  // Debug: Print document data
        
        guard let name = data?["name"] as? String else {
            print("Error: Missing 'name' field in document: \(document.documentID)")
            return nil
        }
        
        guard let count = data?["count"] as? Int else {
            print("Error: Missing or invalid 'count' field in document: \(document.documentID)")
            return nil
        }
        
        guard let colorHex = data?["color"] as? String else {
            print("Error: Missing 'color' field in document: \(document.documentID)")
            return nil
        }
        
        guard let timestamp = data?["timestamp"] as? Timestamp else {
            print("Error: Missing 'timestamp' field in document: \(document.documentID)")
            return nil
        }
        
        let imageName = data?["imageName"] as? String
        
        self.id = document.documentID
        self.name = name
        self.count = count
        self.color = UIColor(hex: colorHex)
        self.timestamp = timestamp
        self.imageName = imageName
    }
    
    var dictionary: [String: Any] {
        return [
            "name": name,
            "count": count,
            "color": color.toHex(),
            "timestamp": timestamp,
            "imageName": imageName ?? ""
        ]
    }
}
