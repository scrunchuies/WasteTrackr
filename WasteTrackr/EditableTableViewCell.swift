//
//  EditableTableViewCell.swift
//  WasteTrackr
//
//  Created by Piotr Jandura on 5/8/24.
//

import UIKit
import FirebaseFirestore

class EditableTableViewCell: UITableViewCell, UITextFieldDelegate {
    var nameTextField = UITextField()
    var countTextField = UITextField()
    var countStepper = UIStepper()
    
    var documentID: String?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupTextFields()
        setupStepper()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupTextFields() {
        let textFieldHeight: CGFloat = 30
        let nameFieldWidth = contentView.bounds.width / 2 - 30
        let countFieldWidth = contentView.bounds.width / 4 - 10 // Make count field shorter
        
        nameTextField.frame = CGRect(x: 15, y: 5, width: nameFieldWidth, height: textFieldHeight)
        countTextField.frame = CGRect(x: nameFieldWidth + 30, y: 5, width: countFieldWidth, height: textFieldHeight)
        
        nameTextField.borderStyle = .roundedRect
        countTextField.borderStyle = .roundedRect
        
        nameTextField.delegate = self
        countTextField.delegate = self
        
        // Lock textfields on startup
        nameTextField.isEnabled = false
        countTextField.isEnabled = false
        
        contentView.addSubview(nameTextField)
        contentView.addSubview(countTextField)
    }
    
    private func setupStepper() {
        // Adjust the stepper's position and size
        let stepperWidth: CGFloat = 94
        let stepperHeight: CGFloat = 30
        countStepper.frame = CGRect(x: contentView.bounds.width - stepperWidth - 15,
                                    y: (contentView.bounds.height - stepperHeight) / 2,
                                    width: stepperWidth,
                                    height: stepperHeight)
        countStepper.autoresizingMask = [.flexibleLeftMargin, .flexibleTopMargin]

        // Set properties for the stepper
        countStepper.wraps = false
        countStepper.autorepeat = true
        countStepper.minimumValue = 0
        countStepper.maximumValue = 250  // Increase the maximum value to 250
        countStepper.addTarget(self, action: #selector(stepperValueChanged(_:)), for: .valueChanged)

        contentView.addSubview(countStepper)
    }
    
    @objc private func stepperValueChanged(_ sender: UIStepper) {
        // Update the countTextField with the new stepper value
        countTextField.text = "\(Int(sender.value))"

        // Optionally, update Firestore immediately when stepper changes
        updateFirestoreCount()
    }

    private func updateFirestoreCount() {
        guard let docID = documentID, let count = Int(countTextField.text ?? "0") else { return }
        let db = Firestore.firestore()
        db.collection("items").document(docID).updateData(["count": count]) { err in
            if let err = err {
                print("Error updating document count: \(err)")
            } else {
                print("Document count successfully updated to \(count)")
            }
        }
    }
    
    func configure(with item: Item) {
        documentID = item.id
        nameTextField.text = item.name
        countTextField.text = String(item.count)
        countStepper.value = Double(item.count)
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        guard let docID = documentID else {
            print("Document ID is nil")
            return
        }

        // Identify which field was edited and prepare data for Firestore update
        let field = textField == nameTextField ? "name" : "count"
        let value: Any = textField == nameTextField ? textField.text ?? "" : Int(textField.text ?? "0") ?? 0
        
        updateFirestore(documentID: docID, field: field, value: value)
    }
    
    private func updateFirestore(documentID: String, field: String, value: Any) {
        let db = Firestore.firestore()
        db.collection("items").document(documentID).updateData([field: value]) { error in
            if let error = error {
                print("Error updating document: \(error)")
            } else {
                print("Successfully updated \(field) to \(value) in document \(documentID)")
            }
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    // Method to enable or disable editing of text fields
    func setEditable(_ isEditable: Bool) {
        nameTextField.isEnabled = isEditable
        countTextField.isEnabled = isEditable
    }
    
}
