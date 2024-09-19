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
    var stockCount: Int
    var color: UIColor
    var timestamp: Timestamp
    var imageName: String?
    var changeLog: [[String: Any]]
    var location: String
    let category: String // Ensure category is part of the struct

    // Default initializer
    init(id: String, name: String, count: Int, stockCount: Int, color: UIColor, timestamp: Timestamp, imageName: String?, changeLog: [[String: Any]] = [], location: String, category: String) {
        self.id = id
        self.name = name
        self.count = count
        self.stockCount = stockCount
        self.color = color
        self.timestamp = timestamp
        self.imageName = imageName
        self.changeLog = changeLog
        self.location = location
        self.category = category // Initialize category
    }
    
    // Initialize from Firestore document snapshot
    init?(document: DocumentSnapshot) {
        let data = document.data()
        print("Document data: \(String(describing: data))")  // Debug: Print document data
        
        // Guard clauses to ensure required fields are present
        guard let name = data?["name"] as? String else {
            print("Error: Missing 'name' field in document: \(document.documentID)")
            return nil
        }
        
        guard let count = data?["count"] as? Int else {
            print("Error: Missing or invalid 'count' field in document: \(document.documentID)")
            return nil
        }
        
        guard let stockCount = data?["stockCount"] as? Int else {
            print("Error: Missing or invalid 'stockCount' field in document: \(document.documentID)")
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
        
        guard let category = data?["category"] as? String else {
            print("Error: Missing 'category' field in document: \(document.documentID)")
            return nil
        }
        
        let imageName = data?["imageName"] as? String
        let changeLog = data?["changeLog"] as? [[String: Any]] ?? []
        let location = data?["location"] as? String ?? ""
        
        // Assign values to the struct's properties
        self.id = document.documentID
        self.name = name
        self.count = count
        self.stockCount = stockCount
        self.color = UIColor(hex: colorHex)
        self.timestamp = timestamp
        self.imageName = imageName
        self.changeLog = changeLog
        self.location = location
        self.category = category // Ensure category is initialized
    }
    
    // Convert the struct to a Firestore dictionary
    var dictionary: [String: Any] {
        return [
            "name": name,
            "count": count,
            "stockCount": stockCount,
            "color": color.toHex(),
            "timestamp": timestamp,
            "imageName": imageName ?? "",
            "changeLog": changeLog,
            "location": location,
            "category": category // Include category in Firestore data
        ]
    }
}

// UIColor extension to handle hex conversions
public extension UIColor {
    func toHex() -> String {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        
        self.getRed(&r, green: &g, blue: &b, alpha: &a)
        
        return String(format: "#%02lX%02lX%02lX", lroundf(Float(r * 255)), lroundf(Float(g * 255)), lroundf(Float(b * 255)))
    }
    
    convenience init(hex: String) {
        var hexString = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        if hexString.hasPrefix("#") {
            hexString.remove(at: hexString.startIndex)
        }
        
        var rgbValue: UInt64 = 0
        Scanner(string: hexString).scanHexInt64(&rgbValue)
        
        let r = CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0
        let g = CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0
        let b = CGFloat(rgbValue & 0x0000FF) / 255.0
        
        self.init(red: r, green: g, blue: b, alpha: 1.0)
    }
}
