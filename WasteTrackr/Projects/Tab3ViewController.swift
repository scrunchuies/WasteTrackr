//
//  Tab3ViewController.swift
//  WasteTrackr
//
//  Created by Piotr Jandura on 5/8/24.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth

class Tab3ViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, EditableCellDelegate {
    @IBOutlet weak var selectButton: UIBarButtonItem!
    @IBOutlet weak var addButton: UIBarButtonItem!
    @IBOutlet weak var editButton: UIBarButtonItem!
    @IBOutlet weak var deleteButton: UIBarButtonItem!
    @IBOutlet weak var collectionView: UICollectionView!
    
    var collectionSuffix = "BULK"
    var refreshControl = UIRefreshControl()
    var listener: ListenerRegistration?
    
    var isSelectionMode = false
    var selectedItems: Set<IndexPath> = []
    
    var items: [Item] = [] {
        didSet {
            collectionView.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadTheme()
        
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(EditableCollectionViewCell.self, forCellWithReuseIdentifier: "EditableCell")
        
        setupNavigationItems()
        setupRefreshControl()
        observeItems()
        
        sendToken()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        loadTheme()
    }
    
    func loadTheme() {
        guard let user = Auth.auth().currentUser else { return }
        let db = Firestore.firestore()
        let docRef = db.collection("userProfiles").document(user.uid)

        docRef.getDocument { [weak self] (document, error) in
            guard let self = self else { return }
            if let document = document, document.exists {
                let data = document.data()
                let themeIndex = data?["theme"] as? Int ?? 0 // Default to light theme
                self.applyTheme(themeIndex: themeIndex)
            }
        }
    }

    func applyTheme(themeIndex: Int) {
        switch themeIndex {
        case 0:
            self.overrideUserInterfaceStyle = .light
        case 1:
            self.overrideUserInterfaceStyle = .dark
        default:
            self.overrideUserInterfaceStyle = .light
        }
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    func setupRefreshControl() {
        refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        collectionView.refreshControl = refreshControl
    }
    
    @objc func refreshData() {
        observeItems()
    }
    
    private func setupNavigationItems() {
        selectButton.target = self
        selectButton.action = #selector(toggleSelectionMode)
        addButton.target = self
        addButton.action = #selector(addNewItem)
        editButton.target = self
        editButton.action = #selector(toggleEditingMode)
        deleteButton.target = self
        deleteButton.action = #selector(deleteSelectedItems)
        deleteButton.isEnabled = false
    }
    
    @objc func toggleEditingMode() {
        let isEditing = !collectionView.isEditing
        collectionView.isEditing = isEditing
        editButton.title = isEditing ? "Done" : "Edit"
        
        for case let cell as EditableCollectionViewCell in collectionView.visibleCells {
            //cell.setEditable(isEditing)
        }
    }
    
    @objc func toggleSelectionMode() {
        isSelectionMode.toggle()
        collectionView.allowsMultipleSelection = isSelectionMode
        selectButton.title = isSelectionMode ? "Done" : "Select"
        deleteButton.isHidden = !isSelectionMode
        deleteButton.isEnabled = isSelectionMode
        selectedItems.removeAll()
        
        for case let cell as EditableCollectionViewCell in collectionView.visibleCells {
            //cell.setSelectable(isSelectionMode)
            cell.isSelected = false
        }
    }
    
    @objc func deleteSelectedItems() {
        guard !selectedItems.isEmpty else { return }
        
        let itemsToDelete = selectedItems.map { items[$0.row] }
        let db = Firestore.firestore()
        let collectionId = collectionID(forSuffix: collectionSuffix)
        
        let batch = db.batch()
        
        for item in itemsToDelete {
            let docRef = db.collection(collectionId).document(item.id)
            batch.deleteDocument(docRef)
        }
        
        batch.commit { [weak self] error in
            guard let self = self else { return }
            if let error = error {
                print("Error deleting documents: \(error)")
            } else {
                print("Successfully deleted selected documents")
                self.items.removeAll { item in
                    itemsToDelete.contains(where: { $0.id == item.id })
                }
                self.selectedItems.removeAll()
                self.toggleSelectionMode()
            }
        }
    }
    
    @IBAction func logoutClicked(_ sender: Any) {
        do {
            try Auth.auth().signOut()
            
            UserDefaults.standard.removeObject(forKey: "UserStoreID")
            UserDefaults.standard.synchronize()
            
            performSegue(withIdentifier: "returnToLogin", sender: self)
        } catch let signOutError as NSError {
            print("Error signing out: \(signOutError)")
        }
    }
    
    @objc func addNewItem() {
        let db = Firestore.firestore()
        let collectionId = collectionID(forSuffix: collectionSuffix)
        let newItem = Item(
            id: UUID().uuidString,
            name: "New Item",
            count: 1,
            stockCount: 0,  // You can set the initial stock count here
            color: UIColor.random(),
            timestamp: Timestamp(),
            imageName: "default background"
        )
        
        db.collection(collectionId).document(newItem.id).setData(newItem.dictionary) { err in
            if let err = err {
                print("Error adding document: \(err)")
            } else {
                print("Successfully added document: \(newItem.id)")
                self.logChange(for: newItem, changeAmount: 1)
            }
        }
    }
    
    func observeItems() {
        let collectionId = collectionID(forSuffix: collectionSuffix)
        print("Using collection ID: \(collectionId)")
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

            guard let snapshot = querySnapshot else {
                print("No data found in collection: \(collectionId)")
                DispatchQueue.main.async {
                    self.refreshControl.endRefreshing()
                }
                return
            }

            print("Fetched \(snapshot.documents.count) documents")
            
            // Safely parse the documents
            self.items = snapshot.documents.compactMap { doc -> Item? in
                let data = doc.data()

                // Safely unwrap required fields
                guard
                    let name = data["name"] as? String,
                    let count = data["count"] as? Int,
                    let stockCount = data["stockCount"] as? Int // Ensure stockCount exists
                else {
                    print("Missing or invalid fields in document: \(doc.documentID)")
                    return nil // Skip this document if fields are missing
                }

                // Optional fields with defaults
                let id = doc.documentID
                let color = UIColor(hex: data["color"] as? String ?? "#FFFFFF")
                let timestamp = data["timestamp"] as? Timestamp ?? Timestamp(date: Date())
                let imageName = data["imageName"] as? String

                // Return the parsed item
                return Item(id: id, name: name, count: count, stockCount: stockCount, color: color, timestamp: timestamp, imageName: imageName)
            }

            print("Parsed items: \(self.items.map { $0.name })")

            DispatchQueue.main.async {
                self.collectionView.reloadData()
                self.refreshControl.endRefreshing()
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        listener?.remove()
    }
    
    func collectionID(forSuffix suffix: String) -> String {
        if let storeId = UserDefaults.standard.string(forKey: "UserStoreID") {
            return "\(storeId)-\(suffix)"
        } else {
            print("Store ID not set, defaulting to a temporary value")
            return "defaultStoreID-\(suffix)"
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        print("Total items: \(items.count)")
        return items.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "EditableCell", for: indexPath) as? EditableCollectionViewCell else {
            fatalError("Error: Unexpected cell type")
        }
        let item = items[indexPath.row]
        cell.configure(with: item, collectionSuffix: collectionSuffix)
        cell.delegate = self
        cell.indexPath = indexPath
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let cellsPerRow: CGFloat = 3
        let spacing: CGFloat = 10
        let totalSpacing = (cellsPerRow - 1) * spacing
        let width = (collectionView.bounds.width - totalSpacing - 20) / cellsPerRow
        return CGSize(width: width, height: width)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 10
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 10
    }
    
    func collectionView(_ collectionView: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
    }
    
    func updateItem(at indexPath: IndexPath, with newValue: Int, newStockCount: Int) {
        var item = items[indexPath.row]
        let changeAmount = newValue - item.count
        item.count = newValue
        item.stockCount = newStockCount
        items[indexPath.row] = item
        
        let documentID = item.id
        let collectionId = collectionID(forSuffix: collectionSuffix)
        let db = Firestore.firestore()
        
        let updateData: [String: Any] = [
            "count": newValue,
            "stockCount": newStockCount,
            "color": item.color.toHex() // Ensure color updates as well
        ]
        
        db.collection(collectionId).document(documentID).updateData(updateData) { error in
            if let error = error {
                print("Error updating document: \(error)")
            } else {
                print("Successfully updated count and stock count in document \(documentID)")
                self.logChange(for: item, changeAmount: changeAmount)
            }
        }
    }

    
    func didEditStockCount(at indexPath: IndexPath, newStockCount: Int) {
        var item = items[indexPath.row]
        item.stockCount = newStockCount
        items[indexPath.row] = item
        
        let documentID = item.id
        let collectionId = collectionID(forSuffix: collectionSuffix)
        let db = Firestore.firestore()
        
        db.collection(collectionId).document(documentID).updateData(["stockCount": newStockCount]) { error in
            if let error = error {
                print("Error updating stock count: \(error)")
            } else {
                print("Successfully updated stock count to \(newStockCount) in document \(documentID)")
                // Optionally log the change if needed
            }
        }
    }
    
    func collectionID() -> String {
        return collectionID(forSuffix: collectionSuffix)
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
    
    func deleteItem(at indexPath: IndexPath) {
        guard indexPath.row < items.count else { return } // Prevent index out of range
        
        let item = items[indexPath.row]
        let documentID = item.id
        let collectionId = collectionID(forSuffix: collectionSuffix)
        let db = Firestore.firestore()
        
        db.collection(collectionId).document(documentID).delete { [weak self] error in
            guard let self = self else { return }
            if let error = error {
                print("Error deleting document: \(error)")
            } else {
                print("Successfully deleted document \(documentID)")
                
                // Ensure the index is still valid before removing the item
                if indexPath.row < self.items.count {
                    self.items.remove(at: indexPath.row)
                    self.collectionView.deleteItems(at: [indexPath])
                } else {
                    print("Index out of range after document deletion.")
                }
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if isSelectionMode {
            selectedItems.insert(indexPath)
            if let cell = collectionView.cellForItem(at: indexPath) as? EditableCollectionViewCell {
                cell.layer.borderWidth = 2.0
                cell.layer.borderColor = UIColor.red.cgColor
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        if isSelectionMode {
            selectedItems.remove(indexPath)
            if let cell = collectionView.cellForItem(at: indexPath) as? EditableCollectionViewCell {
                cell.layer.borderWidth = 0.0
            }
        }
    }
    
    func presentEditMenu(for cell: EditableCollectionViewCell, at indexPath: IndexPath) {
        let alert = UIAlertController(title: "Edit Item", message: "Choose an action", preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Change Color", style: .default, handler: { _ in
            self.presentColorPicker(for: cell, at: indexPath)
        }))
        
        alert.addAction(UIAlertAction(title: "Change Image", style: .default, handler: { _ in
            self.presentImagePicker(for: cell, at: indexPath)
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        if let popoverController = alert.popoverPresentationController {
            popoverController.sourceView = cell
            popoverController.sourceRect = cell.bounds
        }
        
        present(alert, animated: true, completion: nil)
    }
    
    func presentColorPicker(for cell: EditableCollectionViewCell, at indexPath: IndexPath) {
        // Implement color picker logic here
        let colors: [UIColor] = [.red, .green, .blue, .yellow, .purple, .black, .orange, .brown]
        let alert = UIAlertController(title: "Choose Color", message: nil, preferredStyle: .actionSheet)
        
        for color in colors {
            alert.addAction(UIAlertAction(title: color.accessibilityName.capitalized, style: .default, handler: { _ in
                // Set the background color directly to the contentView of the cell
                cell.contentView.backgroundColor = color.withAlphaComponent(0.9)
                self.updateItemColor(at: indexPath, color: color)
            }))
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        if let popoverController = alert.popoverPresentationController {
            popoverController.sourceView = cell
            popoverController.sourceRect = cell.bounds
        }
        
        present(alert, animated: true, completion: nil)
    }

    
    func presentImagePicker(for cell: EditableCollectionViewCell, at indexPath: IndexPath) {
        // Implement image picker logic here
        // For example:
        let images: [String] = ["filet", "spicy filet", "grilled filet", "nuggets", "grilled nuggets", "strips"]
        let alert = UIAlertController(title: "Choose Image", message: nil, preferredStyle: .actionSheet)
        
        for imageName in images {
            alert.addAction(UIAlertAction(title: imageName.capitalized, style: .default, handler: { _ in
                if let image = UIImage(named: imageName) {
                    cell.backgroundImageView.image = image
                    self.updateItemImage(at: indexPath, imageName: imageName)
                }
            }))
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        if let popoverController = alert.popoverPresentationController {
            popoverController.sourceView = cell
            popoverController.sourceRect = cell.bounds
        }
        
        present(alert, animated: true, completion: nil)
    }
    
    func updateItemColor(at indexPath: IndexPath, color: UIColor) {
        var item = items[indexPath.row]
        item.color = color
        items[indexPath.row] = item
        
        let documentID = item.id
        let collectionId = collectionID(forSuffix: collectionSuffix)
        let db = Firestore.firestore()
        
        // Convert UIColor to hex string
        let colorHexString = color.toHexString()
        
        // Update the Firestore document
        db.collection(collectionId).document(documentID).updateData(["color": colorHexString]) { error in
            if let error = error {
                print("Error updating document: \(error)")
            } else {
                print("Successfully updated color in document \(documentID)")
                self.logChange(for: item, changeAmount: 0) // Log the change with no change in count
            }
        }
    }
    
    func updateItemImage(at indexPath: IndexPath, imageName: String) {
        var item = items[indexPath.row]
        item.imageName = imageName
        items[indexPath.row] = item
        
        let documentID = item.id
        let collectionId = collectionID(forSuffix: collectionSuffix)
        let db = Firestore.firestore()
        
        db.collection(collectionId).document(documentID).updateData(["imageName": imageName]) { error in
            if let error = error {
                print("Error updating document: \(error)")
            } else {
                print("Successfully updated image in document \(documentID)")
                self.logChange(for: item, changeAmount: 0) // Log the change with no change in count
            }
        }
    }
    
    func didEditCell(at indexPath: IndexPath, newValue: Int) {
        let currentStockCount = items[indexPath.row].stockCount
        updateItem(at: indexPath, with: newValue, newStockCount: currentStockCount)
    }


    private func logChange(for item: Item, changeAmount: Int) {
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
}