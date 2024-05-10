//
//  Tab2ViewController.swift
//  WasteTrackr
//
//  Created by Piotr Jandura on 5/9/24.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth

class Tab2ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    @IBOutlet weak var editItem: UIBarButtonItem!
    @IBOutlet weak var addItem: UIBarButtonItem!
    @IBOutlet weak var logoutItem: UIBarButtonItem!
    @IBOutlet weak var tableView: UITableView!
    
    var items: [Item] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(EditableTableViewCell.self, forCellReuseIdentifier: "EditableCell")
        
        setupNavigationItems()
        observeItems()
    }
    
    private func setupNavigationItems() {
        addItem.target = self
        addItem.action = #selector(addNewItem)
        editItem.target = self
        editItem.action = #selector(toggleEditingMode)
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
        guard let storeId = UserDefaults.standard.string(forKey: "UserStoreID") else {
            fatalError("Store ID not set")
        }
        return "\(storeId)-\(suffix)"
    }

    func observeItems() {
        let collectionId = collectionID(forSuffix: "BOH")  // Modify based on active user store ID
        let db = Firestore.firestore()
        db.collection(collectionId).order(by: "timestamp", descending: false).addSnapshotListener { [weak self] querySnapshot, error in
            guard let self = self else { return }
            if let error = error {
                print("Error fetching snapshots: \(error)")
                return
            }

            guard let snapshot = querySnapshot, !snapshot.documents.isEmpty else {
                print("No data found in collection: \(collectionId)")
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
            }
        }
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
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "EditableCell", for: indexPath) as? EditableTableViewCell else {
            fatalError("Error: Unexpected cell type")
        }
        let item = items[indexPath.row]
        cell.configure(with: item)
        cell.delegate = self
        cell.setEditable(tableView.isEditing)
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
