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
    
    var showHidePasswordButton: UIButton!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupInitialUI()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupInitialUI()
        setupTextFieldStyles()
        setupGestureRecognizers()
        setupShowHidePasswordButton()
        
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
    
    func setupInitialUI() {
        overrideUserInterfaceStyle = .light
        let rememberMe = UserDefaults.standard.bool(forKey: "RememberMe")
        rememberMeCheckbox.isOn = rememberMe
        if rememberMe {
            emailTextField.text = UserDefaults.standard.string(forKey: "SavedEmail")
            passTextField.text = UserDefaults.standard.string(forKey: "SavedPassword")
        } else {
            emailTextField.text = ""
            passTextField.text = ""
        }
    }

    func setupTextFieldStyles() {
        let fields = [emailTextField, passTextField]
        let placeholderAttributes = [NSAttributedString.Key.foregroundColor: UIColor.lightGray]
        for field in fields {
            field?.delegate = self
            field?.layer.borderWidth = 1
            field?.layer.cornerRadius = 8
            let placeholderText = field == emailTextField ? "Email" : "Password"
            field?.attributedPlaceholder = NSAttributedString(string: placeholderText, attributes: placeholderAttributes)
        }
    }

    func setupGestureRecognizers() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
    }
    
    func setupShowHidePasswordButton() {
        showHidePasswordButton = UIButton(type: .custom)
        showHidePasswordButton.tintColor = .black
        showHidePasswordButton.setImage(UIImage(systemName: "eye"), for: .normal)
        showHidePasswordButton.setImage(UIImage(systemName: "eye.slash"), for: .selected)
        showHidePasswordButton.addTarget(self, action: #selector(togglePasswordVisibility), for: .touchUpInside)
        
        view.addSubview(showHidePasswordButton)
        
        showHidePasswordButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            showHidePasswordButton.centerYAnchor.constraint(equalTo: passTextField.centerYAnchor),
            showHidePasswordButton.trailingAnchor.constraint(equalTo: passTextField.trailingAnchor, constant: -10),
            showHidePasswordButton.widthAnchor.constraint(equalToConstant: 30),
            showHidePasswordButton.heightAnchor.constraint(equalToConstant: 30)
        ])
    }

    @objc func togglePasswordVisibility() {
        passTextField.isSecureTextEntry.toggle()
        showHidePasswordButton.isSelected.toggle()
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
        print(Array(UserDefaults.standard.dictionaryRepresentation()))
        // Ensure the email field is not empty
        guard let email = emailTextField.text, !email.isEmpty else {
            print("Email is empty")
            return
        }
        
        // Ensure the password field is not empty
        guard let pass = passTextField.text, !pass.isEmpty else {
            print("Password is empty")
            return
        }
        
        // Sign in with the provided email and password
        Auth.auth().signIn(withEmail: email, password: pass) { [weak self] (authResult, error) in
            guard let self = self else { return }
            
            // Handle potential errors during sign-in
            if let error = error {
                print("Error signing in:", error.localizedDescription)
                // Optionally update the UI to inform the user of the error
                DispatchQueue.main.async {
                    // You might want to show an alert or a label to the user here
                    self.showError("Failed to log in: \(error.localizedDescription)")
                }
                return
            }
            
            // Authentication was successful, now ensure the user profile exists
            self.ensureUserProfile { [weak self] in
                // Assuming the method fetchAndStoreUserStoreId also uses completion handlers
                self?.fetchAndStoreUserStoreId {
                    // Navigate to the main part of the app on successful fetch
                    DispatchQueue.main.async {
                        self?.performSegue(withIdentifier: "loginToHome", sender: self)
                    }
                }
            }
        }
    }

    // Utility method to show error messages to the user, enhancing UX
    func showError(_ message: String) {
        // Implementation depends on how you wish to show error messages
        // E.g., using a UIAlertController to display alerts
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        self.present(alert, animated: true)
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
