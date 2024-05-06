//
//  InventoryViewController.swift
//  WasteTrackr
//
//  Created by Piotr Jandura on 4/30/24.
//

import UIKit
import FirebaseFirestore

class InventoryViewController: UIViewController, UITextFieldDelegate {
    @IBOutlet weak var addItemButton: UIBarButtonItem!
    @IBOutlet weak var editItemButton: UIBarButtonItem!
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var countLabel: UILabel!
    @IBOutlet weak var countTextField: UITextField!
    
    var previousCount: Int?
    var errorTimer: Timer?
    var isEditingEnabled = false
    private var name = "" // Initial value for name
    private var count = 0 // Initial count value
    private let db = Firestore.firestore()
    private let collectionRef = Firestore.firestore().collection("cfa")
    private var countListener: ListenerRegistration?
    private var nameListener: ListenerRegistration?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Load initial count from Firestore
        loadCount()
        startCountListener()
        startNameListener()
        
        //User defaults
        nameTextField.isUserInteractionEnabled = false
        countTextField.isUserInteractionEnabled = false
        
        nameTextField.addTarget(self, action: #selector(nameTextFieldDidChange(_:)), for: .editingChanged)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
        
        countTextField.delegate = self
        countTextField.returnKeyType = .done
        nameTextField.delegate = self
        nameTextField.returnKeyType = .done
        
        overrideUserInterfaceStyle = .light

    }
    
    deinit {
        countListener?.remove()
        nameListener?.remove()
    }
    
    private func startCountListener() {
        countListener = collectionRef.document("FTnn41nFjfyLN2ZdQr90").addSnapshotListener { [weak self] (documentSnapshot, error) in
            guard let self = self else { return }
            guard let document = documentSnapshot, document.exists else {
                print("Count document does not exist")
                return
            }
            if let count = document.data()?["count"] as? Int {
                self.count = count
                self.updateCount()
            } else {
                print("Invalid count value")
            }
        }
    }
    
    private func startNameListener() {
        nameListener = collectionRef.document("FTnn41nFjfyLN2ZdQr90").addSnapshotListener { [weak self] (documentSnapshot, error) in
            guard let self = self else { return }
            guard let document = documentSnapshot, document.exists else {
                print("Document does not exist")
                return
            }
            if let name = document.data()?["name"] as? String {
                self.name = name
                self.updateName()
            } else {
                print("Invalid name value")
            }
        }
    }
    
    // Load count value from Firestore
    private func loadCount() {
        collectionRef.document("FTnn41nFjfyLN2ZdQr90").getDocument { [weak self] (document, error) in
            guard let self = self else { return }
            
            if let error = error {
                print("Error getting count value: \(error.localizedDescription)")
                // Provide a default value for count
                self.count = 0 // You can set it to any default value you prefer
            } else {
                if let document = document, document.exists, let count = document.data()?["count"] as? Int {
                    self.count = count
                    self.updateName()
                } else {
                    print("Count document does not exist or count value is invalid.")
                    // Provide a default value for count
                    self.count = 0 // You can set it to any default value you prefer
                }
            }
            
            self.updateCount()
        }
    }
    
    private func loadName() {
        collectionRef.document("FTnn41nFjfyLN2ZdQr90").getDocument { [weak self] (document, error) in
            guard let self = self else { return }
            
            if let error = error {
                print("Error getting name value: \(error.localizedDescription)")
                // Provide a default value for name
                self.name = "" // You can set it to any default value you prefer
            } else {
                if let document = document, document.exists, let name = document.data()?["name"] as? String {
                    self.name = name
                } else {
                    print("Document does not exist or name value is invalid.")
                    // Provide a default value for name
                    self.name = "" // You can set it to any default value you prefer
                }
            }
            
            self.updateName()
        }
    }
    
    // Update count value in Firestore
    private func updateCountInFirestore() {
        collectionRef.document("FTnn41nFjfyLN2ZdQr90").setData(["name": name, "count": count]) { error in
            if let error = error {
                print("Error updating count value: \(error.localizedDescription)")
            } else {
                print("Count value updated successfully")
            }
        }
    }
    
    // Update label text with current count value
    private func updateCount() {
        countTextField.text = "\(count)"
    }
    
    @IBAction func countTextFieldDidChange(_ textField: UITextField) {
        if let newCountString = textField.text, let newCount = Int(newCountString) {
            count = newCount
            updateCountInFirestore()
        }
    }

    // Update name value in Firestore
    private func updateNameInFirestore() {
        collectionRef.document("FTnn41nFjfyLN2ZdQr90").setData(["name": name, "count": count]) { error in
                if let error = error {
                    print("Error updating values: \(error.localizedDescription)")
                } else {
                    print("Values updated successfully")
                }
            }
    }
    
    
    // Update text field with current name value
    private func updateName() {
        nameTextField.text = name
    }
    
    
    @objc private func nameTextFieldDidChange(_ textField: UITextField) {
        // Update name value in Firestore whenever the text field changes
        if let newName = textField.text {
            name = newName
            updateNameInFirestore()
        }
    }
    
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        // Check if the textField is the countTextField
        if textField == countTextField {
            // Allow deleting characters
            guard !string.isEmpty else { return true }
            
            // Check if the replacement string contains only numeric characters
            let allowedCharacters = CharacterSet.decimalDigits
            let characterSet = CharacterSet(charactersIn: string)
            if !allowedCharacters.isSuperset(of: characterSet) {
                // If not, show error and revert to previous count
                showError(message: "Only numbers are allowed")
                return false
            }
        }
        
        // Otherwise, allow input for other text fields
        return true
    }

        
        // Show error message
        func showError(message: String) {
            // Set error message and show error label
            errorLabel.text = message
            errorLabel.isHidden = false
            
            // Invalidate previous timer if exists
            errorTimer?.invalidate()
            
            // Hide error label after 5 seconds
            errorTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: false) { [weak self] _ in
                self?.hideErrorLabel()
            }
        }
        
        // Hide error label
        func hideErrorLabel() {
            errorLabel.isHidden = true
        }
    
    // ---------------------------------------------------------
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        dismissKeyboard()
        return true
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @IBAction func editItemButtonTapped(_ sender: UIBarButtonItem) {
        // Toggle editing mode
        isEditingEnabled.toggle()
        
        // Enable or disable text fields based on editing mode
        nameTextField.isUserInteractionEnabled = isEditingEnabled
        countTextField.isUserInteractionEnabled = isEditingEnabled
        
        // Update button title
        let title = isEditingEnabled ? "Done" : "Edit"
        editItemButton.title = title
        
        // If editing is disabled, dismiss keyboard
        if !isEditingEnabled {
            view.endEditing(true)
        }
    }

    
    // Action method for button tap
    @IBAction private func incrementButtonTapped(_ sender: UIButton) {
        // Increment count using a transaction
        db.runTransaction({ (transaction, errorPointer) -> Any? in
            // Get the latest count value
            let countDocumentRef = self.collectionRef.document("FTnn41nFjfyLN2ZdQr90")
            let countDocumentSnapshot: DocumentSnapshot
            do {
                try countDocumentSnapshot = transaction.getDocument(countDocumentRef)
            } catch let fetchError as NSError {
                errorPointer?.pointee = fetchError
                return nil
            }
            
            guard let countData = countDocumentSnapshot.data(),
                  var currentCount = countData["count"] as? Int else {
                let error = NSError(domain: "AppErrorDomain", code: -1, userInfo: [
                    NSLocalizedDescriptionKey: "Count value is missing or invalid"
                ])
                errorPointer?.pointee = error
                return nil
            }
            
            // Increment the count
            currentCount += 1
            
            // Update the count in Firestore
            transaction.updateData(["count": currentCount], forDocument: countDocumentRef)
            
            return currentCount
        }) { [weak self] (count, error) in
            guard let self = self else { return }
            if let error = error {
                print("Transaction failed: \(error.localizedDescription)")
            } else {
                if let newCount = count as? Int {
                    // Update local count and label
                    self.count = newCount
                    self.updateCount()
                } else {
                    print("Invalid count value received from transaction")
                }
            }
        }
    }
    
    // Add this IBAction method for the decrement button tap
    @IBAction private func decrementButtonTapped(_ sender: UIButton) {
        // Decrement count using a transaction
        db.runTransaction({ (transaction, errorPointer) -> Any? in
            // Get the latest count value
            let countDocumentRef = self.collectionRef.document("FTnn41nFjfyLN2ZdQr90")
            let countDocumentSnapshot: DocumentSnapshot
            do {
                try countDocumentSnapshot = transaction.getDocument(countDocumentRef)
            } catch let fetchError as NSError {
                errorPointer?.pointee = fetchError
                return nil
            }
            
            guard let countData = countDocumentSnapshot.data(),
                  var currentCount = countData["count"] as? Int else {
                let error = NSError(domain: "AppErrorDomain", code: -1, userInfo: [
                    NSLocalizedDescriptionKey: "Count value is missing or invalid"
                ])
                errorPointer?.pointee = error
                return nil
            }
            
            // Decrement the count
            currentCount -= 1
            
            // Update the count in Firestore
            transaction.updateData(["count": currentCount], forDocument: countDocumentRef)
            
            return currentCount
        }) { [weak self] (count, error) in
            guard let self = self else { return }
            if let error = error {
                print("Transaction failed: \(error.localizedDescription)")
            } else {
                if let newCount = count as? Int {
                    // Update local count and label
                    self.count = newCount
                    self.updateCount()
                } else {
                    print("Invalid count value received from transaction")
                }
            }
        }
    }
}
