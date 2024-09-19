//
//  Tab2ViewController.swift
//  WasteTrackr
//
//  Created by Piotr Jandura on 5/8/24.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage

class Tab2ViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, EditableCellDelegate {
    @IBOutlet weak var selectButton: UIBarButtonItem!
    @IBOutlet weak var addButton: UIBarButtonItem!
    @IBOutlet weak var editButton: UIBarButtonItem!
    @IBOutlet weak var areaButton: UIBarButtonItem!
    @IBOutlet weak var deleteButton: UIBarButtonItem!
    @IBOutlet weak var titleBar: UINavigationItem!
    @IBOutlet weak var collectionView: UICollectionView!
    
    var collectionSuffix = "BOH-PM"
    var refreshControl = UIRefreshControl()
    var listener: ListenerRegistration?
    var cellsPerRow: CGFloat = 3
    
    var isSelectionMode = false
    var selectedItems: Set<IndexPath> = []
    var imageNames: [String] = []
    
    var items: [Item] = [] {
        didSet {
            collectionView.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 10
        layout.minimumInteritemSpacing = 10
        collectionView.collectionViewLayout = layout
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(EditableCollectionViewCell.self, forCellWithReuseIdentifier: "EditableCell")
        
        setupNavigationItems()
        setupRefreshControl()
        observeItems()
        sendToken()
        
        fetchImagesFromFirebase { imageUrls in
            print("Fetched images: \(imageUrls)")
            self.imageNames = imageUrls
            self.collectionView.reloadData()
        }
        
        // Add long press gesture recognizer
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        collectionView.addGestureRecognizer(longPressGesture)
        
        // Long press gesture recognizer for resetAll function
        let titleLongPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleTitleLongPress))
        if let titleView = titleBar.titleView {
            titleView.addGestureRecognizer(titleLongPressGesture)
            titleView.isUserInteractionEnabled = true  // Enable user interaction
        } else {
            let titleLabel = UILabel()
            titleLabel.text = titleBar.title
            titleLabel.isUserInteractionEnabled = true
            titleLabel.addGestureRecognizer(titleLongPressGesture)
            titleBar.titleView = titleLabel
        }
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
    
    @objc func handleLongPress(gesture: UILongPressGestureRecognizer) {
        let location = gesture.location(in: collectionView)
        
        if gesture.state == .began {
            // Find the indexPath for the cell at the pressed location
            if let indexPath = collectionView.indexPathForItem(at: location),
               let cell = collectionView.cellForItem(at: indexPath) as? EditableCollectionViewCell {
                
                // Present the edit menu for the selected cell
                presentEditMenu(for: cell, at: indexPath)
            }
        }
    }
    
    @objc func handleTitleLongPress(gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began {
            // Show confirmation alert to reset all values
            let alert = UIAlertController(title: "Reset All Values", message: "Are you sure you want to reset all item values to 0?", preferredStyle: .alert)
            
            let resetAction = UIAlertAction(title: "Yes", style: .destructive) { _ in
                self.resetAllValues()
            }
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            
            alert.addAction(resetAction)
            alert.addAction(cancelAction)
            
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    @objc func handleLongPressForReordering(gesture: UILongPressGestureRecognizer) {
        let location = gesture.location(in: collectionView)
        
        switch gesture.state {
        case .began:
            if let selectedIndexPath = collectionView.indexPathForItem(at: location) {
                collectionView.beginInteractiveMovementForItem(at: selectedIndexPath)
            }
        case .changed:
            collectionView.updateInteractiveMovementTargetPosition(location)
        case .ended:
            collectionView.endInteractiveMovement()
        default:
            collectionView.cancelInteractiveMovement()
        }
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
            cell.nameTextField.isEnabled = isEditing
            cell.countTextField.isEnabled = isEditing
        }
    }
    
    @objc func toggleSelectionMode() {
        let alertController = UIAlertController(title: "Select Number of Cells", message: nil, preferredStyle: .actionSheet)
        
        let cellOptions = [1, 2, 3, 4, 5, 6]  // Customize the number of options as needed
        for option in cellOptions {
            let action = UIAlertAction(title: "\(option) cells per row", style: .default) { [weak self] _ in
                self?.cellsPerRow = CGFloat(option)
                self?.collectionView.collectionViewLayout.invalidateLayout()  // Invalidate layout to refresh the collection view
            }
            alertController.addAction(action)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        // For iPad, the popover presentation controller needs to be set
        if let popoverController = alertController.popoverPresentationController {
            popoverController.barButtonItem = selectButton
        }
        
        present(alertController, animated: true, completion: nil)
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
        
        // Determine the category based on the current image of areaButton
        let currentCategory: String
        if areaButton.image == UIImage(systemName: "1.square") {
            currentCategory = "1"
        } else if areaButton.image == UIImage(systemName: "2.square") {
            currentCategory = "2"
        } else {
            currentCategory = "1" // Default category if no image or unknown state
        }
        
        let newItem = Item(
            id: UUID().uuidString,
            name: "New Item",
            count: 1,
            stockCount: 0,
            color: UIColor.random(),
            timestamp: Timestamp(),
            imageName: "default background",
            location: "0",
            category: currentCategory // Set the category dynamically
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
    
    @IBAction func areaButtonClicked(_ sender: Any) {
        if let currentImage = areaButton.image {
            if currentImage == UIImage(systemName: "1.square") {
                areaButton.image = UIImage(systemName: "2.square")
            } else {
                areaButton.image = UIImage(systemName: "1.square")
            }
            
            // Refresh the item observation after changing the button's image
            observeItems()
        }
    }
    
    func observeItems() {
        let collectionId = collectionID(forSuffix: collectionSuffix)
        print("Using collection ID: \(collectionId)")
        let db = Firestore.firestore()
        
        // Determine the current category based on the areaButton's image
        let currentCategory: String
        if areaButton.image == UIImage(systemName: "1.square") {
            currentCategory = "1"
        } else if areaButton.image == UIImage(systemName: "2.square") {
            currentCategory = "2"
        } else {
            currentCategory = "1" // Default category if no image or unknown state
        }
        
        listener?.remove()
        
        // Modify the Firestore query to filter by the current category
        listener = db.collection(collectionId)
            .whereField("category", isEqualTo: currentCategory)  // Filter items by category
            .order(by: "timestamp", descending: false)
            .addSnapshotListener { [weak self] querySnapshot, error in
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
                    var data = doc.data()
                    
                    // Check and add missing fields with default values
                    var needsUpdate = false
                    
                    if data["location"] == nil {
                        data["location"] = "Unknown" // Default value for location
                        needsUpdate = true
                    }
                    
                    if data["stockCount"] == nil {
                        data["stockCount"] = 0 // Default stock count
                        needsUpdate = true
                    }
                    
                    if data["color"] == nil {
                        data["color"] = "#FFFFFF" // Default color in hex
                        needsUpdate = true
                    }
                    
                    if data["timestamp"] == nil {
                        data["timestamp"] = Timestamp() // Default timestamp
                        needsUpdate = true
                    }
                    
                    if data["category"] == nil {
                        data["category"] = "1" // Default category if missing
                        needsUpdate = true
                    }
                    
                    // Update the document in Firestore if any field is missing
                    if needsUpdate {
                        db.collection(collectionId).document(doc.documentID).updateData(data) { error in
                            if let error = error {
                                print("Error updating document \(doc.documentID): \(error)")
                            } else {
                                print("Document \(doc.documentID) updated with missing fields")
                            }
                        }
                    }
                    
                    // Parse required fields to create an Item
                    guard
                        let name = data["name"] as? String,
                        let count = data["count"] as? Int,
                        let location = data["location"] as? String,
                        let stockCount = data["stockCount"] as? Int,
                        let category = data["category"] as? String  // Ensure category is parsed
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
                    return Item(id: id, name: name, count: count, stockCount: stockCount, color: color, timestamp: timestamp, imageName: imageName, location: location, category: category)
                }
                
                print("Parsed items: \(self.items.map { $0.name })")
                
                DispatchQueue.main.async {
                    self.collectionView.reloadData()
                    self.refreshControl.endRefreshing()
                }
            }
    }
    
    func resetAllValues() {
        let db = Firestore.firestore()
        let collectionId = collectionID(forSuffix: collectionSuffix)
        
        for index in items.indices {
            items[index].count = 0
            
            let documentID = items[index].id
            let updateData: [String: Any] = [
                "count": 0
            ]
            
            db.collection(collectionId).document(documentID).updateData(updateData) { error in
                if let error = error {
                    print("Error resetting values: \(error)")
                } else {
                    print("Successfully reset values for item \(documentID)")
                }
            }
        }
        
        collectionView.reloadData()  // Refresh the collection view to reflect the changes
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
    
    // Update the collectionView's data source to handle the reordering of cells
    func collectionView(_ collectionView: UICollectionView, moveItemAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let movedItem = items.remove(at: sourceIndexPath.item)
        items.insert(movedItem, at: destinationIndexPath.item)
    }
    
    // Enable reordering of items
    func collectionView(_ collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath) -> Bool {
        return true // All items can be reordered
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        print("Total items: \(items.count)\nTotal images: \(imageNames.count)")
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
        
        // Check if the item has an associated image name
        if let imageName = item.imageName, !imageName.isEmpty {
            // Try to load the image from local storage first
            if let localImage = loadImageFromDocumentsDirectory(named: imageName) {
                cell.backgroundImageView.image = localImage
            } else {
                // If not found locally, fetch from Firebase Storage
                let storageRef = Storage.storage().reference().child("images/\(imageName)")
                
                // Fetch the download URL
                storageRef.downloadURL { url, error in
                    if let error = error {
                        print("Error fetching image URL: \(error)")
                        return
                    }
                    
                    if let url = url {
                        // Load the image using the URL
                        DispatchQueue.global().async {
                            if let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
                                // Save the image locally
                                self.saveImageToDocumentsDirectory(image: image, forImageName: imageName)
                                
                                DispatchQueue.main.async {
                                    cell.backgroundImageView.image = image
                                }
                            }
                        }
                    }
                }
            }
        } else {
            // Set a placeholder image if no image is associated
            cell.backgroundImageView.image = UIImage(named: "placeholderImage")
        }
        return cell
    }
    
    // Save image to the local device
    func saveImageToDocumentsDirectory(image: UIImage, forImageName imageName: String) {
        if let data = image.jpegData(compressionQuality: 1.0) {
            let filePath = getDocumentsDirectory().appendingPathComponent(imageName)
            do {
                try data.write(to: filePath)
                print("Image saved locally at: \(filePath)")
            } catch {
                print("Error saving image: \(error)")
            }
        }
    }
    
    // Load image from the local device
    func loadImageFromDocumentsDirectory(named imageName: String) -> UIImage? {
        let filePath = getDocumentsDirectory().appendingPathComponent(imageName)
        if FileManager.default.fileExists(atPath: filePath.path) {
            return UIImage(contentsOfFile: filePath.path)
        }
        return nil
    }
    
    // Get the local documents directory path
    func getDocumentsDirectory() -> URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let numberOfCellsPerRow: CGFloat = cellsPerRow  // Set your desired number of cells per row
        let padding: CGFloat = 10  // Adjust the padding as needed
        let totalPadding: CGFloat = padding * (numberOfCellsPerRow + 1)  // Total padding including edges and between items
        let availableWidth = collectionView.frame.width - totalPadding  // Available width for cells
        let cellWidth = availableWidth / numberOfCellsPerRow  // Calculate the cell width
        let cellHeight = cellWidth * 1.3  // Adjust the height-to-width ratio for desired cell shape
        
        return CGSize(width: cellWidth, height: cellHeight)
    }
    
    // UICollectionViewDelegateFlowLayout method to define spacing between cells
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 10  // Space between rows
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 10  // Space between columns
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)  // Adjust the insets if necessary
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        print("CollectionView width: \(collectionView.frame.width)")
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        collectionView.collectionViewLayout.invalidateLayout()
    }
    
    func didEditLocation(at indexPath: IndexPath, newLocation: String) {
        var item = items[indexPath.row]
        item.location = newLocation // Update the item locally
        items[indexPath.row] = item // Update the local list
        
        let documentID = item.id
        let collectionId = collectionID(forSuffix: collectionSuffix)
        let db = Firestore.firestore()
        
        // Update Firestore
        db.collection(collectionId).document(documentID).updateData(["location": newLocation]) { error in
            if let error = error {
                print("Error updating location: \(error)")
            } else {
                print("Successfully updated location to \(newLocation) in document \(documentID)")
            }
        }
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
            "name": item.name,
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
    
    func didEditName(at indexPath: IndexPath, newName: String) {
        var item = items[indexPath.row]
        item.name = newName
        items[indexPath.row] = item
        
        let documentID = item.id
        let collectionId = collectionID(forSuffix: collectionSuffix)
        let db = Firestore.firestore()
        
        // Update Firestore
        db.collection(collectionId).document(documentID).updateData(["name": newName]) { [weak self] error in
            if let error = error {
                print("Error updating name: \(error.localizedDescription)")
                self?.showAlert(title: "Update Failed", message: "Failed to update the item's name. Please try again.")
            } else {
                print("Successfully updated name in document \(documentID)")
                // Ensure the UI reloads to reflect the changes
                self?.observeItems() // Re-fetch the items from Firestore to reload the UI
            }
        }
    }
    
    // Helper function to show alerts
    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
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
        
        // Add Delete option to the menu
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { [weak self] _ in
            self?.deleteItem(at: indexPath)
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
    
    func fetchImagesFromFirebase(completion: @escaping ([String]) -> Void) {
        let storageRef = Storage.storage().reference().child("images/")
        
        storageRef.listAll { (result, error) in
            if let error = error {
                print("Error fetching images: \(error)")
                completion([])
                return
            }
            
            guard let result = result else {
                print("No result found")
                completion([])
                return
            }
            
            var imageNames: [String] = []
            let dispatchGroup = DispatchGroup()
            
            for item in result.items {
                dispatchGroup.enter()
                item.downloadURL { url, error in
                    if let error = error {
                        print("Error getting image URL: \(error)")
                        dispatchGroup.leave()
                        return
                    }
                    
                    if let url = url {
                        // Store only the image name, not the full URL
                        imageNames.append(item.name)
                    }
                    dispatchGroup.leave()
                }
            }
            
            dispatchGroup.notify(queue: .main) {
                completion(imageNames)
            }
        }
    }
    
    func presentImagePicker(for cell: EditableCollectionViewCell, at indexPath: IndexPath) {
        fetchImagesFromFirebase { imageNames in
            let alert = UIAlertController(title: "Choose Image", message: nil, preferredStyle: .actionSheet)
            
            for imageName in imageNames {
                alert.addAction(UIAlertAction(title: imageName, style: .default, handler: { _ in
                    // Use the imageName to fetch the actual image
                    let storageRef = Storage.storage().reference().child("images/\(imageName)")
                    storageRef.downloadURL { url, error in
                        if let error = error {
                            print("Error fetching image URL: \(error)")
                            return
                        }
                        
                        if let url = url {
                            DispatchQueue.global().async {
                                if let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
                                    DispatchQueue.main.async {
                                        cell.backgroundImageView.image = image
                                        self.updateItemImage(at: indexPath, imageName: imageName)
                                    }
                                }
                            }
                        }
                    }
                }))
            }
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            
            if let popoverController = alert.popoverPresentationController {
                popoverController.sourceView = cell
                popoverController.sourceRect = cell.bounds
            }
            
            self.present(alert, animated: true, completion: nil)
        }
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
