//
//  Tab1ViewController.swift
//  WasteTrackr
//
//  Created by Piotr Jandura on 5/8/24.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth

class Tab1ViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, EditableCellDelegate {
    @IBOutlet weak var selectButton: UIBarButtonItem!
    @IBOutlet weak var addButton: UIBarButtonItem!
    @IBOutlet weak var editButton: UIBarButtonItem!
    @IBOutlet weak var deleteButton: UIBarButtonItem!
    @IBOutlet weak var collectionView: UICollectionView!
    
    var collectionSuffix = "FOH"
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
        overrideUserInterfaceStyle = .light
        
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(EditableCollectionViewCell.self, forCellWithReuseIdentifier: "EditableCell")
        
        setupNavigationItems()
        setupRefreshControl()
        observeItems()
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
            cell.setEditable(isEditing)
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
            cell.setSelectable(isSelectionMode)
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
        let collectionId = collectionID(forSuffix: "FOH")
        let newItem = Item(
            id: UUID().uuidString,
            name: "New Item",
            count: 1,
            color: UIColor.random(),
            timestamp: Timestamp(),
            imageName: "default_background"
        )
        
        db.collection(collectionId).document(newItem.id).setData(newItem.dictionary) { err in
            if let err = err {
                print("Error adding document: \(err)")
            } else {
                print("Successfully added document: \(newItem.id)")
            }
        }
    }
    
    func observeItems() {
        let collectionId = collectionID(forSuffix: "FOH")
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
            self.items = snapshot.documents.compactMap { doc -> Item? in
                let item = Item(document: doc)
                if item == nil {
                    print("Failed to parse document: \(doc.documentID)")
                }
                return item
            }
            
            print("Parsed items: \(self.items)")
            
            DispatchQueue.main.async {
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
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
    }
    
    func updateItem(at indexPath: IndexPath, with newValue: Int) {
        var item = items[indexPath.row]
        item.count = newValue
        items[indexPath.row] = item
        
        let documentID = item.id
        let collectionId = collectionID(forSuffix: collectionSuffix)
        let db = Firestore.firestore()
        
        db.collection(collectionId).document(documentID).updateData(["count": newValue]) { error in
            if let error = error {
                print("Error updating document: \(error)")
            } else {
                print("Successfully updated count to \(newValue) in document \(documentID)")
            }
        }
    }
    
    func collectionID() -> String {
        return collectionID(forSuffix: "FOH")
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
}
