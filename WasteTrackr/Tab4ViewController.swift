//
//  Tab4ViewController.swift
//  WasteTrackr
//
//  Created by Piotr Jandura on 6/2/24.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth
import FirebaseFunctions

class Tab4ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, EditableCellDelegate {
    lazy var functions = Functions.functions()
    var notificationAccumulation: [String: (itemName: String, totalTaken: Int, amountLeft: Int)] = [:]
    var notificationTimer: Timer?
    
    func sendPushNotification(itemName: String, amountTaken: Int, amountLeft: Int) {
        guard let userStoreID = getUserStoreID() else {
            print("UserStoreID not available")
            return
        }
        
        let data: [String: Any] = [
            "title": "\(collectionSuffix) Updated",
            "body": "Item: \(itemName) \nAmount Taken: \(amountTaken) \nAmount Left: \(amountLeft) \nPerson: \(currentUserName ?? "No name")",
            "userStoreID": userStoreID
        ]
        
        functions.httpsCallable("sendPushWithDeviceIds").call(data) { result, error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                return
            }
            if let response = result?.data as? [String: Any], let success = response["success"] as? Bool {
                if success {
                    print("Notification sent successfully")
                } else {
                    print("Failed to send notification")
                }
            }
        }
    }
    
    func getUserStoreID() -> String? {
        return UserDefaults.standard.string(forKey: "UserStoreID")
    }
    
    @IBOutlet weak var selectButton: UIBarButtonItem!
    @IBOutlet weak var addButton: UIBarButtonItem!
    @IBOutlet weak var editButton: UIBarButtonItem!
    @IBOutlet weak var deleteButton: UIBarButtonItem!
    @IBOutlet weak var tableView: UITableView!
    
    var collectionSuffix = "STORAGE"
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
        
        sendToken()
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
            print("Store ID not set, defaulting to a temporary value")
            return "defaultStoreID-\(suffix)"
        }
    }
    
    func observeItems() {
        let collectionId = collectionID(forSuffix: collectionSuffix)
        let db = Firestore.firestore()
        
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
        cell.indexPath = indexPath
        cell.setEditable(isEditingMode, keepStepperEnabled: true)
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
        // Check if indexPath.row is within the bounds of the items array
        guard indexPath.row >= 0 && indexPath.row < items.count else {
            print("Index out of range.")
            return
        }
        
        let documentID = items[indexPath.row].id
        let itemName = items[indexPath.row].name // Get the name of the item to be deleted
        let db = Firestore.firestore()
        let collectionId = collectionID(forSuffix: collectionSuffix)
        
        // Remove the item from the items array first
        let removedItem = items.remove(at: indexPath.row)

        // Update the tableView after removing the item from the array
        self.tableView.performBatchUpdates({
            self.tableView.deleteRows(at: [indexPath], with: .automatic)
        }) { [weak self] _ in
            // After removing from the tableView, delete from Firestore
            db.collection(collectionId).document(documentID).delete() { error in
                if let error = error {
                    print("Error removing document: \(error)")
                    
                    // Re-add the item to the array and tableView if there was an error
                    self?.items.insert(removedItem, at: indexPath.row)
                    self?.tableView.insertRows(at: [indexPath], with: .automatic)
                } else {
                    print("Document successfully removed!")
                }
            }
        }
    }
    
    func updateItemName(at indexPath: IndexPath, with newName: String) {
        let documentID = items[indexPath.row].id
        let db = Firestore.firestore()
        let collectionId = collectionID(forSuffix: collectionSuffix)
        
        db.collection(collectionId).document(documentID).updateData(["name": newName]) { error in
            if let error = error {
                print("Error updating document: \(error)")
            } else {
                print("Document successfully updated!")
                self.items[indexPath.row].name = newName
                DispatchQueue.main.async {
                    self.tableView.reloadRows(at: [indexPath], with: .none)
                }
            }
        }
    }
    
    func didEditCell(at indexPath: IndexPath, newValue: Int) {
        let item = items[indexPath.row]
        let oldValue = item.count
        let amountTaken = oldValue - newValue
        let amountLeft = newValue
        let documentID = item.id
        let db = Firestore.firestore()
        let collectionId = collectionID(forSuffix: collectionSuffix)
        
        db.collection(collectionId).document(documentID).updateData(["count": newValue]) { error in
            if let error = error {
                print("Error updating document: \(error)")
            } else {
                print("Document successfully updated!")
                self.items[indexPath.row].count = newValue
                DispatchQueue.main.async {
                    self.tableView.reloadRows(at: [indexPath], with: .none)
                }
                
                // Only send the push notification if the count is decreased
                if amountTaken > 0 {
                    // Accumulate changes
                    if let existing = self.notificationAccumulation[item.id] {
                        self.notificationAccumulation[item.id] = (itemName: existing.itemName, totalTaken: existing.totalTaken + amountTaken, amountLeft: amountLeft)
                    } else {
                        self.notificationAccumulation[item.id] = (itemName: item.name, totalTaken: amountTaken, amountLeft: amountLeft)
                    }
                    
                    // Reset the timer
                    self.notificationTimer?.invalidate()
                    self.notificationTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.sendAccumulatedNotifications), userInfo: nil, repeats: false)
                }
            }
        }
    }
    
    @objc func sendAccumulatedNotifications() {
        for (_, value) in notificationAccumulation {
            sendPushNotification(itemName: value.itemName, amountTaken: value.totalTaken, amountLeft: value.amountLeft)
        }
        // Clear accumulated notifications after sending
        notificationAccumulation.removeAll()
    }
    
    deinit {
        listener?.remove()
    }
    
    func updateData(forDocumentID docID: String, collectionID: String, field: String, newValue: Any) {
        let db = Firestore.firestore()
        db.collection(collectionID).document(docID).updateData([field: newValue]) { error in
            if let error = error {
                print("Error updating document: \(error)")
            } else {
                print("Document successfully updated")
            }
        }
    }
    
    func collectionID() -> String {
        // Return the collection ID used in your Firestore database
        return "yourCollectionID"
    }
    
    func shouldEnableEditing() -> Bool {
        // Return whether editing should be enabled or not
        return true
    }
    
    func updateItem(at indexPath: IndexPath, with newValue: Int) {
        // Update the item at the given indexPath with the new value
        // You might want to update your data source here
    }
    
    func presentEditMenu(for cell: EditableCollectionViewCell, at indexPath: IndexPath) {
        // Present the edit menu for the given cell at the specified indexPath
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
