//
//  FirebaseUserData.swift
//  WasteTrackr
//
//  Created by Piotr Jandura on 8/7/24.
//

import Foundation
import FirebaseAuth
import Firebase
import FirebaseFirestore

func sendToken() {
    let db = Firestore.firestore()
    let userStoreID = UserDefaults.standard.string(forKey: "UserStoreID") ?? "00000"
    let docID = "\(userStoreID)-userTokens"
    let docRef = db.collection("userTokens").document(docID)

    guard let fcmToken = UserDefaults.standard.string(forKey: "FCMToken") else {
        print("No FCM token found in UserDefaults.")
        return
    }

    docRef.getDocument { (document, error) in
        if let document = document, document.exists {
            docRef.updateData([
                "tokens": FieldValue.arrayUnion([fcmToken])
            ]) { err in
                if let err = err {
                    print("Error updating document: \(err)")
                } else {
                    print("Document successfully updated with FCM token.")
                }
            }
        } else {
            docRef.setData([
                "tokens": [fcmToken]
            ]) { err in
                if let err = err {
                    print("Error creating document: \(err)")
                } else {
                    print("Document successfully created with FCM token.")
                }
            }
        }
    }
}
