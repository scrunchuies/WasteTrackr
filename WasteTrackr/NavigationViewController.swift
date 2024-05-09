//
//  NavigationViewController.swift
//  WasteTrackr
//
//  Created by Piotr Jandura on 5/8/24.
//

import UIKit
import FirebaseFirestore

class NavigationViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    @IBOutlet weak var editItem: UIBarButtonItem!
    @IBOutlet weak var addItem: UIBarButtonItem!
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
    
    
    func observeItems() {
        let db = Firestore.firestore()
        db.collection("items").addSnapshotListener { [weak self] querySnapshot, error in
            guard let self = self else { return }
            if let error = error {
                print("Error fetching snapshots: \(error)")
                return
            }
            
            self.items = querySnapshot?.documents.map { doc -> Item in
                let data = doc.data()
                let id = doc.documentID
                let name = data["name"] as? String ?? ""
                let count = data["count"] as? Int ?? 0
                return Item(id: id, name: name, count: count)
            } ?? []
            
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    @objc func addNewItem() {
        let db = Firestore.firestore()
        // Assuming 'name' and 'count' are set by some default or user input before this method
        let newItem = ["name": "New Item", "count": 1] as [String : Any]  // Example default values

        db.collection("items").addDocument(data: newItem) { [weak self] err in
            if let err = err {
                print("Error adding document: \(err)")
            } else {
                // Optionally fetch data again or handle UI update directly
                // For example:
                self?.fetchData()
            }
        }
    }

    // Fetch and refresh the data
    func fetchData() {
        let db = Firestore.firestore()
        db.collection("items").order(by: "name").getDocuments { [weak self] (snapshot, error) in
            guard let snapshot = snapshot else {
                print("Error fetching documents: \(error!)")
                return
            }
            self?.items = snapshot.documents.map { doc in
                Item(id: doc.documentID,
                     name: doc["name"] as? String ?? "",
                     count: doc["count"] as? Int ?? 0)
            }
            self?.tableView.reloadData()
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "EditableCell", for: indexPath) as! EditableTableViewCell
        let item = items[indexPath.row]
        cell.configure(with: item)
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
        db.collection("items").document(documentID).delete { [weak self] err in
            guard let self = self else { return }
            if let err = err {
                print("Error removing document: \(err)")
            } else {
                DispatchQueue.main.async {
                    self.items.remove(at: indexPath.row)
                    self.tableView.deleteRows(at: [indexPath], with: .fade)
                }
            }
        }
    }
}
