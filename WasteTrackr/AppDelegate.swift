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
        
        // Request notification permissions
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            print("Permission granted: \(granted)")
        }
        
        application.registerForRemoteNotifications()
        
        Messaging.messaging().delegate = self
        
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
