//
//  NavigationViewController.swift
//  WasteTrackr
//
//  Created by Piotr Jandura on 5/8/24.
//

import UIKit

class NavigationViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    @IBOutlet weak var editItem: UIBarButtonItem!
    @IBOutlet weak var addItem: UIBarButtonItem!
    @IBOutlet weak var tableView: UITableView!
    
    var items = ["Sample Item 1", "Sample Item 2"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(EditableTableViewCell.self, forCellReuseIdentifier: "EditableCell")
        
        setupNavigationItems()
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleTextChange(_:)), name: NSNotification.Name("LabelDidChange"), object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func setupNavigationItems() {
        addItem.target = self
        addItem.action = #selector(addNewItem)
        editItem.target = self
        editItem.action = #selector(toggleEditingMode)
    }
    
    @objc func addNewItem() {
        let newItem = "New Item \(items.count + 1)"
        items.append(newItem)
        let newIndexPath = IndexPath(row: items.count - 1, section: 0)
        tableView.insertRows(at: [newIndexPath], with: .automatic)
    }
    
    @objc func toggleEditingMode() {
        tableView.setEditing(!tableView.isEditing, animated: true)
        editItem.title = tableView.isEditing ? "Done" : "Edit"
        tableView.visibleCells.forEach { cell in
            if let editableCell = cell as? EditableTableViewCell {
                editableCell.textField.isEnabled = tableView.isEditing
            }
        }
    }
    
    @objc func handleTextChange(_ notification: Notification) {
        if let userInfo = notification.userInfo,
           let newText = userInfo["newText"] as? String,
           let cell = userInfo["cell"] as? EditableTableViewCell,
           let indexPath = tableView.indexPath(for: cell) {
            items[indexPath.row] = newText
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "EditableCell", for: indexPath) as! EditableTableViewCell
        cell.textField.text = items[indexPath.row]
        cell.textField.isEnabled = tableView.isEditing
        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            print("Attempting to delete row at \(indexPath.row)")
            items.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }

}
