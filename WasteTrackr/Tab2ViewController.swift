//
//  NavigationViewController.swift
//  WasteTrackr
//
//  Created by Piotr Jandura on 5/8/24.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth

class Tab2ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    @IBOutlet weak var editItem: UIBarButtonItem!
    @IBOutlet weak var addItem: UIBarButtonItem!
    @IBOutlet weak var logoutItem: UIBarButtonItem!
    @IBOutlet weak var tableView: UITableView!
    
    var collectionSuffix = "BOH"
    var refreshControl = UIRefreshControl()
    var listener: ListenerRegistration?
    var items: [Item] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(EditableTableViewCell.self, forCellReuseIdentifier: "EditableCell")
        
        
        setupNavigationItems()
        setupRefreshControl()
        observeItems()
    }
    
    func setupRefreshControl() {
        refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        tableView.refreshControl = refreshControl
    }
    
    @objc func refreshData() {
        observeItems()
    }
    
    private func setupNavigationItems() {
        addItem.target = self
        addItem.action = #selector(addNewItem)
        editItem.target = self
        editItem.action = #selector(toggleEditingMode)
    }
    
    @IBAction func logoutClicked(_ sender: Any) {
        do {
            try Auth.auth().signOut()
            
            // Clear user-specific data
            UserDefaults.standard.removeObject(forKey: "UserStoreID")
            UserDefaults.standard.synchronize()
            
            // Navigate back to Login View or update UI to reflect logged out state
            performSegue(withIdentifier: "returnToLogin", sender: self)
        } catch let signOutError as NSError {
            print("Error signing out: %@", signOutError)
        }
        
    }
    
    @objc func toggleEditingMode() {
        let isEditing = !tableView.isEditing
        tableView.setEditing(isEditing, animated: true)
        editItem.title = isEditing ? "Done" : "Edit"
        
        // Update all visible cells for editability
        for case let cell as EditableTableViewCell in tableView.visibleCells {
            cell.setEditable(isEditing)
        }
    }
    
    func collectionID(forSuffix suffix: String) -> String {
        if let storeId = UserDefaults.standard.string(forKey: "UserStoreID") {
            return "\(storeId)-\(suffix)"
        } else {
            // Handle the case where store ID is not yet set
            print("Store ID not set, defaulting to a temporary value")
            return "defaultStoreID-\(suffix)"  // Temporary value, adjust according to your app's needs
        }
    }
    
    func observeItems() {
        let collectionId = collectionID(forSuffix: "BOH")  // Adjust as needed for dynamic collection names
        let db = Firestore.firestore()
        
        // Remove any existing listener before creating a new one
        listener?.remove()
        
        listener = db.collection(collectionId).order(by: "timestamp", descending: false).addSnapshotListener { [weak self] querySnapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Error fetching snapshots: \(error)")
                DispatchQueue.main.async {
                    self.refreshControl.endRefreshing()
                }
                return
            }
            
            guard let snapshot = querySnapshot, !snapshot.documents.isEmpty else {
                print("No data found in collection: \(collectionId)")
                DispatchQueue.main.async {
                    self.refreshControl.endRefreshing()
                }
                return
            }
            
            self.items = snapshot.documents.map { doc -> Item in
                let data = doc.data()
                let id = doc.documentID
                let name = data["name"] as? String ?? "No name"
                let count = data["count"] as? Int ?? 0
                return Item(id: id, name: name, count: count)
            }
            
            DispatchQueue.main.async {
                self.tableView.reloadData()
                self.refreshControl.endRefreshing()
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Detach the listener when the view disappears
        listener?.remove()
    }
    
    @objc func addNewItem() {
        let db = Firestore.firestore()
        let collectionId = collectionID(forSuffix: "BOH")  // Use the dynamically determined collection ID
        let newItem = [
            "name": "New Item",
            "count": 1,
            "timestamp": FieldValue.serverTimestamp()
        ] as [String : Any]
        
        db.collection(collectionId).addDocument(data: newItem) { err in
            if let err = err {
                print("Error adding document: \(err)")
            }
        }
    }
    
    func fetchData() {
        let db = Firestore.firestore()
        let collectionId = collectionID(forSuffix: "BOH")  // Use the dynamically determined collection ID
        db.collection(collectionId).order(by: "timestamp", descending: false).getDocuments { [weak self] (snapshot, error) in
            guard let self = self, let snapshot = snapshot else {
                print("Error fetching documents: \(String(describing: error))")
                return
            }
            self.items = snapshot.documents.map { doc in
                Item(id: doc.documentID,
                     name: doc["name"] as? String ?? "",
                     count: doc["count"] as? Int ?? 0)
            }
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print("Total items: \(items.count)")
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "EditableCell", for: indexPath) as? EditableTableViewCell else {
            fatalError("Error: Unexpected cell type")
        }
        let item = items[indexPath.row]
        cell.configure(with: item, collectionSuffix: collectionSuffix)
        cell.delegate = self
        cell.indexPath = indexPath  // This helps track which cell is being edited
        return cell
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            deleteItem(at: indexPath)
        }
    }
    
    func deleteItem(at indexPath: IndexPath) {
        guard indexPath.row < items.count else {
            print("Index out of range.")
            return
        }
        
        let documentID = items[indexPath.row].id
        let db = Firestore.firestore()
        let collectionId = collectionID(forSuffix: "BOH")  // Use the dynamically determined collection ID
        db.collection(collectionId).document(documentID).delete { [weak self] err in
            guard let self = self else { return }
            self.fetchData()  // Ensure to fetch data after deletion
            if let err = err {
                print("Error removing document: \(err)")
            } else {
                DispatchQueue.main.async {
                    // Additional safety check before removing the item
                    if indexPath.row < self.items.count {
                        self.items.remove(at: indexPath.row)
                        self.tableView.deleteRows(at: [indexPath], with: .fade)
                    } else {
                        print("Index out of range after document deletion.")
                    }
                }
                self.fetchData()
            }
        }
    }
}

extension Tab2ViewController: EditableCellDelegate {
    func updateItem(at indexPath: IndexPath, with newValue: Int) {
        var item = items[indexPath.row]
        item.count = newValue  // Update the local model
        tableView.reloadRows(at: [indexPath], with: .none)  // Refresh the row
        
        // Update Firestore
        let documentID = item.id
        updateData(forDocumentID: documentID, collectionID: collectionID(forSuffix: "BOH"), field: "count", newValue: newValue)
    }
    
    func collectionID() -> String {
        return collectionID(forSuffix: "BOH")
    }
    
    func updateData(forDocumentID docID: String, collectionID: String, field: String, newValue: Any) {
        let db = Firestore.firestore()
        db.collection(collectionID).document(docID).updateData([field: newValue]) { error in
            if let error = error {
                print("Error updating document: \(error)")
            } else {
                print("Successfully updated \(field) to \(newValue) in document \(docID)")
            }
        }
    }
    
    func shouldEnableEditing() -> Bool {
        return true
    }
}
