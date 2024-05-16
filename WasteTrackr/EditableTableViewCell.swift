//
//  EditableTableViewCell.swift
//  WasteTrackr
//
//  Created by Piotr Jandura on 5/8/24.
//

import UIKit
import FirebaseFirestore

class EditableTableViewCell: UITableViewCell, UITextFieldDelegate {
    weak var delegate: EditableCellDelegate?
    
    var nameTextField = UITextField()
    var customCountTextField = UITextField()
    var countTextField = UITextField()
    var countStepper = UIStepper()
    var indexPath: IndexPath?
    
    var documentID: String?
    var collectionSuffix: String?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupTextFields()  // sets up nameTextField and countTextField
        setupCustomCountTextField()  // sets up customCountTextField
        setupStepper()  // sets up the countStepper
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupCustomCountTextField() {
        contentView.addSubview(customCountTextField)

        customCountTextField.delegate = self
        customCountTextField.placeholder = "Custom #"
        customCountTextField.keyboardType = .numberPad
        customCountTextField.borderStyle = .roundedRect
        customCountTextField.returnKeyType = .done
        customCountTextField.isEnabled = true

        customCountTextField.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            customCountTextField.leadingAnchor.constraint(equalTo: countTextField.trailingAnchor, constant: 10),
            customCountTextField.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 5),
            customCountTextField.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.2)
        ])
    }
    
    private func setupTextFields() {
        let textFieldHeight: CGFloat = 30
        
        // Add subviews first
        contentView.addSubview(nameTextField)
        contentView.addSubview(countTextField)
        
        // Set properties
        nameTextField.borderStyle = .roundedRect
        countTextField.borderStyle = .roundedRect
        
        nameTextField.delegate = self
        countTextField.delegate = self
        
        nameTextField.font = UIFont.systemFont(ofSize: 20)
        countTextField.font = UIFont.systemFont(ofSize: 20)
        
        // Lock textfields on startup
        nameTextField.isEnabled = false
        countTextField.isEnabled = false
        
        // Use Auto Layout entirely
        nameTextField.translatesAutoresizingMaskIntoConstraints = false
        countTextField.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // NameTextField
            nameTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            nameTextField.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 5),
            nameTextField.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.4),
            
            // CountTextField
            countTextField.leadingAnchor.constraint(equalTo: nameTextField.trailingAnchor, constant: 10),
            countTextField.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 5),
            countTextField.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.2),
        ])
        
        // Now setup customCountTextField after setting up other text fields
        setupCustomCountTextField()
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
        countStepper.maximumValue = 1000
        countStepper.addTarget(self, action: #selector(stepperValueChanged(_:)), for: .valueChanged)
        
        contentView.addSubview(countStepper)

        countStepper.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            countStepper.leadingAnchor.constraint(equalTo: customCountTextField.trailingAnchor, constant: 10),
            countStepper.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 5),
            countStepper.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.15),
            countStepper.heightAnchor.constraint(equalToConstant: 30)
        ])
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        countStepper.value = 0
        countTextField.text = "0"
        countStepper.removeTarget(nil, action: nil, for: .allEvents)
    }
    
    @objc private func stepperValueChanged(_ sender: UIStepper) {
        countTextField.text = "\(Int(sender.value))"
        if let indexPath = indexPath, let del = delegate {
            del.updateItem(at: indexPath, with: Int(sender.value))
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        customCountTextField.delegate = self
    }

     func textFieldDidEndEditing(_ textField: UITextField) {
        guard let docID = documentID, let del = delegate else { return }
        
        // Determine the field and value to update based on which textField is being edited
        let field: String
        let value: Any
        
        switch textField {
        case nameTextField:
            field = "name"
            value = textField.text ?? ""
        case countTextField, customCountTextField:
            field = "count"
            let newValue = Int(textField.text ?? "0") ?? 0
            if textField == customCountTextField {
                let currentCount = Int(countTextField.text ?? "0") ?? 0
                value = currentCount + newValue  // Increment the current count by the new value
                countTextField.text = "\(value)"  // Also update the countTextField display
            } else {
                value = newValue
            }
        default:
            return
        }

        // Update Firestore
        del.updateData(forDocumentID: docID, collectionID: del.collectionID(), field: field, newValue: value)
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()  // Dismiss the keyboard

        if textField == customCountTextField {
            processCustomCountInput()
        }

        return true
    }
    
    private func processCustomCountInput() {
        guard let newCountText = customCountTextField.text, let newCount = Int(newCountText),
              let currentCountText = countTextField.text, let currentCount = Int(currentCountText),
              let docID = documentID, let del = delegate else {
            print("Failed to retrieve necessary data for operation.")
            return
        }

        let updatedCount = currentCount + newCount
        print("Adding \(newCount) to \(currentCount) gives a new count of \(updatedCount)")
        
        countTextField.text = "\(updatedCount)"  // Update the countTextField display
        customCountTextField.text = ""  // Optionally clear the customCountTextField

        // Simulate Firestore update (Debugging print instead of actual update for now)
        print("Would update Firestore: Document ID \(docID), New Count \(updatedCount)")
        // Uncomment the next line when ready to actually update Firestore
        // del.updateData(forDocumentID: docID, collectionID: del.collectionID(), field: "count", newValue: updatedCount)
    }


    
    private func updateFirestoreCount() {
        guard let docID = documentID, let count = Int(countTextField.text ?? "0"), let storeId = UserDefaults.standard.string(forKey: "UserStoreID") else { return }
        let db = Firestore.firestore()
        let collectionName = "\(storeId)-\(String(describing: collectionSuffix))"  // Use the dynamic suffix
        db.collection(collectionName).document(docID).updateData(["count": count]) { err in
            if let err = err {
                print("Error updating document count: \(err)")
            } else {
                print("Document count successfully updated to \(count)")
            }
        }
    }
    
    func configure(with item: Item, collectionSuffix: String) {
        documentID = item.id
        nameTextField.text = item.name
        countTextField.text = String(item.count)
        countStepper.value = Double(item.count)
        self.collectionSuffix = collectionSuffix  // Store it in the cell if needed

        countStepper.addTarget(self, action: #selector(stepperValueChanged(_:)), for: .valueChanged)
    }


    
    private func updateFirestore(documentID: String, field: String, value: Any) {
        guard let storeId = UserDefaults.standard.string(forKey: "UserStoreID") else { return }
        let db = Firestore.firestore()
        let collectionName = "\(storeId)-FOH"  // Dynamic collection name
        db.collection(collectionName).document(documentID).updateData([field: value]) { error in
            if let error = error {
                print("Error updating document: \(error)")
            } else {
                print("Successfully updated \(field) to \(value) in document \(documentID)")
            }
        }
    }
    
    // Method to enable or disable editing of text fields
    func setEditable(_ isEditable: Bool) {
        nameTextField.isEnabled = isEditable
        countTextField.isEnabled = isEditable
    }
}
