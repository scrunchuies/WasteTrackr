//
//  LaunchScreenViewController.swift
//  WasteTrackr
//
//  Created by Piotr Jandura on 11/5/24.
//

import UIKit
import FirebaseAuth

class LaunchScreenViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Check if "Remember Me" was enabled
        let rememberMe = UserDefaults.standard.bool(forKey: "RememberMe")
        if rememberMe {
            // Retrieve saved email and password
            if let email = UserDefaults.standard.string(forKey: "SavedEmail"),
               let password = UserDefaults.standard.string(forKey: "SavedPassword") {
                // Attempt to login with FirebaseAuth
                FirebaseAuth.Auth.auth().signIn(withEmail: email, password: password) { [weak self] authResult, error in
                    if let error = error {
                        // Handle login error
                        print("Error signing in: \(error.localizedDescription)")
                        // Redirect to login screen if needed
                        self?.showLoginScreen()
                    } else {
                        // Login successful, proceed to main screen
                        self?.showMainScreen()
                    }
                }
            } else {
                // No saved credentials found, show login screen
                showLoginScreen()
            }
        } else {
            // "Remember Me" was not enabled, show login screen
            showLoginScreen()
        }
    }
    
    // Function to show the main screen
    func showMainScreen() {
        // Code to transition to the main screen
        let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
        if let mainVC = mainStoryboard.instantiateViewController(withIdentifier: "Tab1ViewController") as? Tab1ViewController {
            mainVC.modalPresentationStyle = .fullScreen
            self.present(mainVC, animated: true, completion: nil)
        }
    }
    
    // Function to show the login screen
    func showLoginScreen() {
        // Code to transition to the login screen
        let loginStoryboard = UIStoryboard(name: "Login", bundle: nil)
        if let loginVC = loginStoryboard.instantiateViewController(withIdentifier: "LoginViewController") as? LoginViewController {
            loginVC.modalPresentationStyle = .fullScreen
            self.present(loginVC, animated: true, completion: nil)
        }
    }
}
