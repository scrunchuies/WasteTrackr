//
//  LoginViewController.swift
//  WasteTrackr
//
//  Created by Piotr Jandura on 4/26/24.
//

import UIKit
import Firebase

class LoginViewController: UIViewController, UITextFieldDelegate {
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passTextField: UITextField!
    @IBOutlet weak var rememberMeCheckbox: UISwitch!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Check if "Remember Me" is selected
        let rememberMe = UserDefaults.standard.bool(forKey: "RememberMe")
        rememberMeCheckbox.isOn = rememberMe
        
        if rememberMe {
            // Populate the text fields
            emailTextField.text = UserDefaults.standard.string(forKey: "SavedEmail") ?? ""
            passTextField.text = UserDefaults.standard.string(forKey: "SavedPassword") ?? ""
        } else {
            // Clear the text fields
            emailTextField.text = ""
            passTextField.text = ""
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .light
        
        NotificationCenter.default.addObserver(self, selector: #selector(resetLoginUI), name: NSNotification.Name("UserDidLogout"), object: nil)
        
        emailTextField.delegate = self
        passTextField.delegate = self
        emailTextField.layer.borderWidth = 1
        emailTextField.layer.cornerRadius = 8
        passTextField.layer.borderWidth = 1
        passTextField.layer.cornerRadius = 8
        
        let emailPlaceholder = NSAttributedString(string: "Email", attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        emailTextField.attributedPlaceholder = emailPlaceholder
        let passPlaceholder = NSAttributedString(string: "Password", attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        passTextField.attributedPlaceholder = passPlaceholder
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
        
        // Check if "Remember Me" is selected
        let rememberMe = UserDefaults.standard.bool(forKey: "RememberMe")
        rememberMeCheckbox.isOn = rememberMe
        
        // If "Remember Me" is selected, populate email and password fields with saved values
        if rememberMe {
            emailTextField.text = UserDefaults.standard.string(forKey: "SavedEmail")
            passTextField.text = UserDefaults.standard.string(forKey: "SavedPassword")
        }
    }
    
    // Only allow portrait mode
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    // Make sure the view controller is presented in portrait mode initially
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return .portrait
    }
    
    // If the device is rotated, this will help in keeping the UI in portrait
    override var shouldAutorotate: Bool {
        return true
    }
    
    @objc func resetLoginUI() {
        emailTextField.text = ""
        passTextField.text = ""
        rememberMeCheckbox.isOn = false
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == passTextField {
            textField.resignFirstResponder() // Dismiss the keyboard
            loginClicked(()) // Trigger the login action without any arguments
        } else {
            passTextField.becomeFirstResponder() // Move to the next text field
        }
        return true
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @IBAction func rememberMeCheckboxToggled(_ sender: UISwitch) {
        UserDefaults.standard.set(sender.isOn, forKey: "RememberMe")
        
        if sender.isOn {
            // If "Remember Me" is selected, save the email and password
            UserDefaults.standard.set(emailTextField.text, forKey: "SavedEmail")
            UserDefaults.standard.set(passTextField.text, forKey: "SavedPassword")
        } else {
            // If "Remember Me" is deselected, clear saved email and password
            UserDefaults.standard.removeObject(forKey: "SavedEmail")
            UserDefaults.standard.removeObject(forKey: "SavedPassword")
        }
    }
    
    @IBAction func loginClicked(_ sender: Any) {
        guard let email = emailTextField.text, !email.isEmpty else {
            print("Email is empty")
            return
        }
        guard let pass = passTextField.text, !pass.isEmpty else {
            print("Password is empty")
            return
        }
        
        Auth.auth().signIn(withEmail: email, password: pass) { [weak self] (authResult, error) in
            guard let self = self else { return }
            if let error = error {
                print("Error signing in:", error.localizedDescription)
                return
            }
            
            // Authentication successful, check and ensure user profile
            self.ensureUserProfile { [weak self] in
                // Fetch storeId and continue to the main part of the app
                self?.fetchAndStoreUserStoreId {
                    self?.performSegue(withIdentifier: "loginToHome", sender: self)
                }
            }
        }
    }
    
    func fetchAndStoreUserStoreId(completion: @escaping () -> Void) {
        guard let user = Auth.auth().currentUser else {
            print("No user is currently logged in.")
            return
        }
        
        let db = Firestore.firestore()
        let userProfileRef = db.collection("userProfiles").document(user.uid)
        
        userProfileRef.getDocument { (document, error) in
            if let document = document, document.exists, let storeId = document.data()?["storeId"] as? String {
                UserDefaults.standard.set(storeId, forKey: "UserStoreID")
                print("Store ID fetched and stored: \(storeId)")
            } else {
                // Set default store ID if it doesn't exist
                UserDefaults.standard.set("00000", forKey: "UserStoreID")
                userProfileRef.updateData(["storeId": "00000"])
                print("Default Store ID set and stored: 00000")
            }
            completion()
        }
    }
    
    func ensureUserProfile(completion: @escaping () -> Void) {
        guard let user = Auth.auth().currentUser, let userEmail = user.email else {
            print("No logged-in user available or email is missing.")
            return
        }

        let db = Firestore.firestore()
        let userProfileRef = db.collection("userProfiles").document(user.uid)

        // Fetch device details
        let deviceName = UIDevice.current.name
        let systemVersion = UIDevice.current.systemVersion
        let uniqueID = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString

        userProfileRef.getDocument { (document, error) in
            // Check for an existing document
            if let document = document, document.exists {
                self.updateUserProfile(with: userProfileRef, user: user, userEmail: userEmail, deviceName: deviceName, systemVersion: systemVersion, uniqueID: uniqueID, completion: completion)
            } else {
                self.createUserProfile(with: userProfileRef, user: user, userEmail: userEmail, deviceName: deviceName, systemVersion: systemVersion, uniqueID: uniqueID, completion: completion)
            }
        }
    }

    func updateUserProfile(with ref: DocumentReference, user: User, userEmail: String, deviceName: String, systemVersion: String, uniqueID: String, completion: @escaping () -> Void) {
        // Attempt to fetch the FCM token
        let fcmToken = UserDefaults.standard.string(forKey: "FCMToken") ?? "defaultToken" // Consider handling the default token more appropriately

        let updateData: [String: Any] = [
            "email": FieldValue.arrayUnion([userEmail]),
            "latestFCMToken": fcmToken,
            "allFCMTokens": FieldValue.arrayUnion([fcmToken]),
            "loginDate": FieldValue.serverTimestamp(),
            "devices": FieldValue.arrayUnion([deviceName]),
            "iOSVersions": FieldValue.arrayUnion([systemVersion]),
            "userIdentifiers": FieldValue.arrayUnion([uniqueID])
        ]

        ref.updateData(updateData) { error in
            if let error = error {
                print("Error updating user profile: \(error)")
            } else {
                print("User profile updated with FCM token details.")
            }
            completion()
        }
    }

    func createUserProfile(with ref: DocumentReference, user: User, userEmail: String, deviceName: String, systemVersion: String, uniqueID: String, completion: @escaping () -> Void) {
        // Attempt to fetch the FCM token
        let fcmToken = UserDefaults.standard.string(forKey: "FCMToken") ?? "defaultToken" // Consider handling the default token more appropriately

        let newData: [String: Any] = [
            "userID": user.uid,
            "email": [userEmail],
            "latestFCMToken": fcmToken,
            "allFCMTokens": [fcmToken],
            "creationDate": FieldValue.serverTimestamp(),
            "loginDate": FieldValue.serverTimestamp(),
            "storeId": "00000", // Default Store ID
            "devices": [deviceName],
            "iOSVersions": [systemVersion],
            "userIdentifiers": [uniqueID]
        ]

        ref.setData(newData) { error in
            if let error = error {
                print("Error creating user profile: \(error)")
            } else {
                print("New user profile created with FCM token details.")
            }
            completion()
        }
    }
}
