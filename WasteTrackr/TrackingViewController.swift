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
    private var count = 0 // Initial count value
    private let db = Firestore.firestore()
    private let collectionRef = Firestore.firestore().collection("cfa") // Replace "your_collection_name" with your actual collection name
    private var countListener: ListenerRegistration?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Load initial count from Firestore
        loadCount()
        startCountListener()
    }
    
    deinit {
            countListener?.remove()
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
                } else {
                    print("Invalid count value")
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
                } else {
                    print("Count document does not exist or count value is invalid.")
                    // Provide a default value for count
                    self.count = 0 // You can set it to any default value you prefer
                }
            }
            
            self.updateCountLabel()
        }
    }
    
    // Update count value in Firestore
    private func updateCountInFirestore() {
        collectionRef.document("FTnn41nFjfyLN2ZdQr90").setData(["count": count]) { error in
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


    
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */
    
}
