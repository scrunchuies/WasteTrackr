//
//  Tab4ViewController.swift
//  WasteTrackr
//
//  Created by Piotr Jandura on 6/2/24.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth

class Tab4ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, EditableCellDelegate {
    
    @IBOutlet weak var selectButton: UIBarButtonItem!
    @IBOutlet weak var addButton: UIBarButtonItem!
    @IBOutlet weak var editButton: UIBarButtonItem!
    @IBOutlet weak var deleteButton: UIBarButtonItem!
    @IBOutlet weak var tableView: UITableView!
    
    var collectionSuffix = "ROM"
    var refreshControl = UIRefreshControl()
    var listener: ListenerRegistration?
    var items: [Item] = []
    var currentUserName: String?
    var isEditingMode = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(EditableTableViewCell.self, forCellReuseIdentifier: "EditableCell")
        
        setupNavigationItems()
        setupRefreshControl()
        observeItems()
        fetchCurrentUserName()
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
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
        addButton.target = self
        addButton.action = #selector(addNewItem)
        editButton.target = self
        editButton.action = #selector(toggleEditingMode)
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
        isEditingMode.toggle()
        tableView.setEditing(isEditingMode, animated: true)
        editButton.title = isEditingMode ? "Done" : "Edit"
        
        // Update all visible cells for editability
        for case let cell as EditableTableViewCell in tableView.visibleCells {
            cell.setEditable(isEditingMode, keepStepperEnabled: true)
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
        let collectionId = collectionID(forSuffix: collectionSuffix)
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
            
            self.items = snapshot.documents.compactMap { doc -> Item? in
                let data = doc.data()
                let id = doc.documentID
                let name = data["name"] as? String ?? "No name"
                let count = data["count"] as? Int ?? 0
                let color = UIColor(hexString: data["color"] as? String ?? "#FFFFFF")
                let timestamp = data["timestamp"] as? Timestamp ?? Timestamp(date: Date())
                let imageName = data["imageName"] as? String
                
                return Item(id: id, name: name, count: count, color: color, timestamp: timestamp, imageName: imageName)
            }
            
            DispatchQueue.main.async {
                self.tableView.reloadData()
                self.refreshControl.endRefreshing()
            }
        }
    }
    
    func fetchCurrentUserName() {
        guard let user = Auth.auth().currentUser else { return }
        let db = Firestore.firestore()
        let docRef = db.collection("userProfiles").document(user.uid)
        
        docRef.getDocument { [weak self] (document, error) in
            if let document = document, document.exists {
                let data = document.data()
                self?.currentUserName = data?["name"] as? String
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
        let collectionId = collectionID(forSuffix: collectionSuffix)
        let newItem = Item(
            id: UUID().uuidString,
            name: "New Item",
            count: 1,
            color: .white,
            timestamp: Timestamp(),
            imageName: "default background"
        )
        
        db.collection(collectionId).document(newItem.id).setData(newItem.dictionary) { err in
            if let err = err {
                print("Error adding document: \(err)")
            } else {
                print("Successfully added document: \(newItem.id)")
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
        cell.configure(with: item, collectionSuffix: collectionSuffix) { [weak self] newName, indexPath in
            self?.updateItemName(at: indexPath, with: newName)
        }
        cell.delegate = self
        cell.indexPath = indexPath  // This helps track which cell is being edited
        cell.setEditable(isEditingMode, keepStepperEnabled: true)  // Set the editability of the cell
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
        let collectionId = collectionID(forSuffix: collectionSuffix)
        db.collection(collectionId).document(documentID).delete { [weak self] err in
            guard let self = self else { return }
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
            }
        }
    }
    
    func updateItem(at indexPath: IndexPath, with newValue: Int) {
        var item = items[indexPath.row]
        let changeAmount = newValue - item.count
        item.count = newValue  // Update the local model
        
        // Update Firestore
        let documentID = item.id
        let collectionId = collectionID(forSuffix: collectionSuffix)
        let db = Firestore.firestore()
        
        db.collection(collectionId).document(documentID).updateData([
            "count": newValue,
            "name": item.name,  // Ensure name is updated as well
            "color": item.color.toHexString(),  // Ensure color is updated as well
            "timestamp": item.timestamp,
            "imageName": item.imageName ?? ""
        ]) { error in
            if let error = error {
                print("Error updating document: \(error)")
            } else {
                print("Successfully updated count to \(newValue) in document \(documentID)")
                self.logChange(for: item, changeAmount: changeAmount)
            }
        }
        
        // Reload the specific row
        tableView.reloadRows(at: [indexPath], with: .none)
    }
    
    func updateItemName(at indexPath: IndexPath, with newName: String) {
        var item = items[indexPath.row]
        item.name = newName // Update the local model
        
        // Update Firestore
        let documentID = item.id
        let collectionId = collectionID(forSuffix: collectionSuffix)
        let db = Firestore.firestore()
        
        db.collection(collectionId).document(documentID).updateData([
            "name": newName,
            "count": item.count,  // Ensure count is updated as well
            "color": item.color.toHexString(),  // Ensure color is updated as well
            "timestamp": item.timestamp,
            "imageName": item.imageName ?? ""
        ]) { error in
            if let error = error {
                print("Error updating document: \(error)")
            } else {
                print("Successfully updated name to \(newName) in document \(documentID)")
            }
        }
        
        // Reload the specific row
        tableView.reloadRows(at: [indexPath], with: .none)
    }
    
    func logChange(for item: Item, changeAmount: Int) {
        let db = Firestore.firestore()
        let collectionId = collectionID(forSuffix: collectionSuffix)
        let documentID = item.id
        
        // Create a new log entry
        let logEntry: [String: Any] = [
            "timestamp": Timestamp(),
            "changeAmount": changeAmount,
            "newCount": item.count
        ]
        
        // Append the log entry to the changeLog array
        db.collection(collectionId).document(documentID).updateData([
            "changeLog": FieldValue.arrayUnion([logEntry])
        ]) { error in
            if let error = error {
                print("Error logging change: \(error)")
            } else {
                print("Successfully logged change in document \(documentID)")
            }
        }
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
        return isEditingMode
    }
    
    func collectionID() -> String {
        return collectionID(forSuffix: collectionSuffix)
    }
    
    func presentEditMenu(for cell: EditableCollectionViewCell, at indexPath: IndexPath) {
        // Implementation for presenting an edit menu (if needed)
    }
    
    func didEditCell(at indexPath: IndexPath, newValue: Int) {
        guard let userName = currentUserName else {
            print("User name not found")
            return
        }
        print("User \(userName) edited cell at index \(indexPath.row)")
        updateItem(at: indexPath, with: newValue)
    }
}

private extension UIColor {
    func toHexString() -> String {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        
        self.getRed(&r, green: &g, blue: &b, alpha: &a)
        
        let rgb: Int = (Int)(r * 255) << 16 | (Int)(g * 255) << 8 | (Int)(b * 255) << 0
        
        return String(format: "#%06x", rgb)
    }

    static func random() -> UIColor {
        return UIColor(
            red: .random(in: 0...1),
            green: .random(in: 0...1),
            blue: .random(in: 0...1),
            alpha: 1.0
        )
    }

    convenience init(hexString: String) {
        var hexString = hexString.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        if hexString.hasPrefix("#") {
            hexString.remove(at: hexString.startIndex)
        }

        var rgbValue: UInt64 = 0
        Scanner(string: hexString).scanHexInt64(&rgbValue)

        let r = CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0
        let g = CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0
        let b = CGFloat(rgbValue & 0x0000FF) / 255.0

        self.init(red: r, green: g, blue: b, alpha: 1.0)
    }
}
