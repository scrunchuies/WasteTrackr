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
    var imageName: String?
    var changeLog: [[String: Any]] // Added changeLog field

    init(id: String, name: String, count: Int, color: UIColor, timestamp: Timestamp, imageName: String?, changeLog: [[String: Any]] = [], minimumThreshold: Int = 0) {
        self.id = id
        self.name = name
        self.count = count
        self.color = color
        self.timestamp = timestamp
        self.imageName = imageName
        self.changeLog = changeLog
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
        let changeLog = data?["changeLog"] as? [[String: Any]] ?? []
        let minimumThreshold = data?["minimumThreshold"] as? Int ?? 0

        self.id = document.documentID
        self.name = name
        self.count = count
        self.color = UIColor(hex: colorHex)
        self.timestamp = timestamp
        self.imageName = imageName
        self.changeLog = changeLog
    }

    var dictionary: [String: Any] {
        return [
            "name": name,
            "count": count,
            "color": color.toHex(),
            "timestamp": timestamp,
            "imageName": imageName ?? "",
            "changeLog": changeLog
        ]
    }
}

private extension UIColor {
    func toHex() -> String {
        guard let components = cgColor.components, components.count >= 3 else {
            return "#000000"
        }

        let r = components[0]
        let g = components[1]
        let b = components[2]

        return String(format: "#%02lX%02lX%02lX",
                      lroundf(Float(r * 255)),
                      lroundf(Float(g * 255)),
                      lroundf(Float(b * 255)))
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
