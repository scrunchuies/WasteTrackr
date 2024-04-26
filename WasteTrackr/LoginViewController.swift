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
            if let error = error {
                print("Error signing in:", error.localizedDescription)
                return
            }
            
            // Authentication successful, perform segue
            self?.performSegue(withIdentifier: "loginToHome", sender: self)
        }
    }

    
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
