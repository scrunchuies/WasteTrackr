//
//  ViewController.swift
//  WasteTrackr
//
//  Created by Piotr Jandura on 4/28/24.
//

import UIKit
import FirebaseFirestore

class TrackingViewController: UIViewController {
    @IBOutlet weak var countLabel: UILabel!
    @IBOutlet weak var nameTextField: UITextField!
    
    private var name = "" // Initial value for name
    private var count = 0 // Initial count value
    private let db = Firestore.firestore()
    private let collectionRef = Firestore.firestore().collection("cfa") // Replace "your_collection_name" with your actual collection name
    private var countListener: ListenerRegistration?
    private var nameListener: ListenerRegistration?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Load initial count from Firestore
        loadCount()
        startCountListener()
        startNameListener()
        
        nameTextField.addTarget(self, action: #selector(nameTextFieldDidChange(_:)), for: .editingChanged)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
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
                self.updateCountLabel()
                self.updateNameTextField()
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
                self.updateNameTextField()
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
                    self.updateNameTextField()
                } else {
                    print("Count document does not exist or count value is invalid.")
                    // Provide a default value for count
                    self.count = 0 // You can set it to any default value you prefer
                }
            }
            
            self.updateCountLabel()
            self.updateNameTextField()
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
            
            self.updateNameTextField()
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
    private func updateCountLabel() {
        countLabel.text = "\(count)"
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
    private func updateNameTextField() {
        nameTextField.text = name
    }
    
    
    @objc private func nameTextFieldDidChange(_ textField: UITextField) {
        // Update name value in Firestore whenever the text field changes
        if let newName = textField.text {
            name = newName
            updateNameInFirestore()
        }
    }
    
    
    
    
    // ---------------------------------------------------------
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
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
                    self.updateCountLabel()
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
                    self.updateCountLabel()
                } else {
                    print("Invalid count value received from transaction")
                }
            }
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
