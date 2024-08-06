//
//  AppDelegate.swift
//  WasteTrackr
//
//  Created by Piotr Jandura on 4/26/24.
//

import UIKit
import FirebaseCore
import FirebaseMessaging
import FirebaseAuth
import FirebaseFirestore
import UserNotifications
import Firebase

@main
class AppDelegate: UIResponder, UIApplicationDelegate, MessagingDelegate, UNUserNotificationCenterDelegate {
    var window: UIWindow?
    let gcmMessageIDKey = "gcm.message_id"
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        
        // Set up notifications
        Messaging.messaging().delegate = self
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { success, _ in
            guard success else {
                return
            }
            print("Success registering APNS")
        }
        
        application.registerForRemoteNotifications()
        
        return true
    }
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        messaging.token { token, _ in
            guard let token = token else {
                return
            }
            print("Token: \(token)")
        }
        guard let token = fcmToken else {
            print("FCM token is nil.")
            return
        }
        print("Received FCM token: \(token)")
        UserDefaults.standard.set(token, forKey: "FCMToken")
        let db = Firestore.firestore()
        
        if let userID = Auth.auth().currentUser?.uid {
            // Update the userTokens collection
            db.collection("userTokens").document(userID).setData(["token": token])
            // Update the userProfiles collection
            updateFirestoreWithToken(token, userId: userID)
        }
    }
    
    private func updateFirestoreWithToken(_ token: String, userId: String) {
        let db = Firestore.firestore()
        let userRef = db.collection("userProfiles").document(userId)
        let data = ["latestFCMToken": token, "allFCMTokens": FieldValue.arrayUnion([token])] as [String : Any]
        
        // Using setData with merge
        userRef.setData(data, merge: true) { error in
            if let error = error {
                print("Unable to save FCM token to Firestore: \(error.localizedDescription)")
            } else {
                print("FCM token successfully saved to Firestore.")
            }
        }
    }
}
