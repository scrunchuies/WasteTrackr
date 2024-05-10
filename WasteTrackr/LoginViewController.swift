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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
                completion()
            } else {
                print("Error fetching store ID: \(String(describing: error))")
                completion()
            }
        }
    }
    
    func ensureUserProfile(completion: @escaping () -> Void) {
        guard let user = Auth.auth().currentUser else {
            print("No logged in user available.")
            return
        }
        
        let db = Firestore.firestore()
        let userProfileRef = db.collection("userProfiles").document(user.uid)
        
        userProfileRef.getDocument { (document, error) in
            if let document = document, document.exists {
                print("Document exists, no need to create a new one.")
                userProfileRef.setData(["loginDate": FieldValue.serverTimestamp()], merge: true)
                completion()
            } else {
                print("Document does not exist, creating a new one.")
                userProfileRef.setData([
                    "userID": user.uid,
                    "email": user.email ?? "",
                    "creationDate": FieldValue.serverTimestamp(),
                    "loginDate": FieldValue.serverTimestamp()
                ]) { err in
                    if let err = err {
                        print("Error writing document: \(err)")
                    } else {
                        print("Document successfully written!")
                    }
                    completion()
                }
            }
        }
    }
}

