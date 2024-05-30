//
//  EditableCollectionViewCell.swift
//  WasteTrackr
//
//  Created by Piotr Jandura on 5/8/24.
//

import UIKit

class EditableCollectionViewCell: UICollectionViewCell, UITextFieldDelegate {
    weak var delegate: EditableCellDelegate?
    
    var backgroundImageView = UIImageView()
    var overlayView = UIView()
    var nameTextField = UITextField()
    var customCountTextField = UITextField()
    var countTextField = UITextField()
    var countStepper = UIStepper()
    var selectionIndicator = UIView()
    var editButton = UIButton(type: .system) // Edit button with ellipsis icon
    var indexPath: IndexPath?
    
    var documentID: String?
    var collectionSuffix: String?
    
    var nameBarView = UIView() // New white bar for holding the nameTextField
    var isSelectionModeEnabled = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        self.layer.cornerRadius = 30
        self.layer.masksToBounds = true
        self.layer.borderColor = UIColor.black.cgColor
        self.layer.borderWidth = 2.0
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        // Add backgroundImageView first
        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.clipsToBounds = true
        backgroundImageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(backgroundImageView)
        
        // Add overlayView second to ensure it's above the background
        overlayView.backgroundColor = UIColor(white: 0, alpha: 0.5) // Semi-transparent overlay
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(overlayView)
        
        // Add selectionIndicator
        selectionIndicator.backgroundColor = UIColor.white.withAlphaComponent(0.5)
        selectionIndicator.translatesAutoresizingMaskIntoConstraints = false
        selectionIndicator.isHidden = true
        contentView.addSubview(selectionIndicator)
        
        // Add nameBarView
        nameBarView.backgroundColor = .white
        nameBarView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(nameBarView)
        
        // Add nameTextField to nameBarView
        nameTextField.layer.borderWidth = 0
        nameTextField.placeholder = "Enter name"
        nameTextField.textAlignment = .center
        nameTextField.returnKeyType = .done
        nameTextField.delegate = self
        nameTextField.font = UIFont.systemFont(ofSize: 22)
        nameTextField.isEnabled = false
        nameTextField.backgroundColor = .clear
        nameTextField.translatesAutoresizingMaskIntoConstraints = false
        nameBarView.addSubview(nameTextField)
        
        // Add countTextField
        countTextField.font = .systemFont(ofSize: 40)
        countTextField.placeholder = "Enter #"
        countTextField.textAlignment = .center
        countTextField.returnKeyType = .done
        countTextField.delegate = self
        countTextField.isEnabled = false
        countTextField.backgroundColor = .clear
        countTextField.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(countTextField)
        
        // Add customCountTextField
        customCountTextField.placeholder = "Custom #"
        customCountTextField.textAlignment = .center
        customCountTextField.returnKeyType = .done
        customCountTextField.delegate = self
        customCountTextField.font = UIFont.systemFont(ofSize: 22)
        customCountTextField.isEnabled = true
        customCountTextField.backgroundColor = .white
        customCountTextField.alpha = 0.4
        customCountTextField.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(customCountTextField)
        
        // Add countStepper
        countStepper.wraps = false
        countStepper.layer.cornerRadius = 8
        countStepper.backgroundColor = .white
        countStepper.autorepeat = true
        countStepper.minimumValue = 0
        countStepper.maximumValue = 1000
        countStepper.addTarget(self, action: #selector(stepperValueChanged(_:)), for: .valueChanged)
        countStepper.translatesAutoresizingMaskIntoConstraints = false
        countStepper.tintColor = .white // Set the tint color to white
        contentView.addSubview(countStepper)
        
        // Add editButton with system icon
        let editIcon = UIImage(systemName: "ellipsis.circle")
        editButton.setImage(editIcon, for: .normal)
        editButton.tintColor = .black
        editButton.translatesAutoresizingMaskIntoConstraints = false
        editButton.isHidden = true // Initially hidden
        editButton.addTarget(self, action: #selector(showEditMenu), for: .touchUpInside)
        contentView.addSubview(editButton)
        
        // Setup constraints
        NSLayoutConstraint.activate([
            backgroundImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            backgroundImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            overlayView.topAnchor.constraint(equalTo: contentView.topAnchor),
            overlayView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            overlayView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            selectionIndicator.topAnchor.constraint(equalTo: contentView.topAnchor),
            selectionIndicator.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            selectionIndicator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            selectionIndicator.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            nameBarView.topAnchor.constraint(equalTo: contentView.topAnchor),
            nameBarView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            nameBarView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            nameBarView.heightAnchor.constraint(equalToConstant: 50), // Height of the white bar
            
            nameTextField.topAnchor.constraint(equalTo: nameBarView.topAnchor, constant: 5),
            nameTextField.leadingAnchor.constraint(equalTo: nameBarView.leadingAnchor, constant: 5),
            nameTextField.trailingAnchor.constraint(equalTo: nameBarView.trailingAnchor, constant: -5),
            nameTextField.bottomAnchor.constraint(equalTo: nameBarView.bottomAnchor, constant: -5),
            
            countTextField.topAnchor.constraint(equalTo: nameBarView.bottomAnchor, constant: 5),
            countTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 5),
            countTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -5),
            
            customCountTextField.topAnchor.constraint(equalTo: countTextField.bottomAnchor, constant: 5),
            customCountTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 5),
            customCountTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -5),
            
            countStepper.topAnchor.constraint(equalTo: customCountTextField.bottomAnchor, constant: 5),
            countStepper.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            countStepper.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -5),
            
            // Edit button constraints
            editButton.centerYAnchor.constraint(equalTo: countStepper.centerYAnchor),
            editButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10)
        ])
        
        // Ensure the cell is square
        NSLayoutConstraint.activate([
            contentView.widthAnchor.constraint(equalTo: contentView.heightAnchor)
        ])
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        countStepper.value = 0
        countTextField.text = "0"
        countStepper.removeTarget(nil, action: nil, for: .allEvents)
        backgroundImageView.image = nil
        overlayView.backgroundColor = UIColor(white: 0, alpha: 0.5)
        selectionIndicator.isHidden = true
        self.layer.borderWidth = 2.0 // Reset the border width
        self.layer.borderColor = UIColor.black.cgColor // Reset the border color
        isSelected = false // Reset the selection state
        editButton.isHidden = true // Reset edit button visibility
    }
    
    @objc private func stepperValueChanged(_ sender: UIStepper) {
        let newValue = Int(sender.value)
        countTextField.text = "\(newValue)"
        updateCountInFirestore(newValue: newValue)
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField == customCountTextField {
            processCustomCountInput()
        } else if textField == nameTextField || textField == countTextField {
            updateFirestoreField(textField: textField)
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        
        if textField == customCountTextField {
            processCustomCountInput()
        } else if textField == nameTextField || textField == countTextField {
            updateFirestoreField(textField: textField)
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
        
        countTextField.text = "\(updatedCount)"
        countStepper.value = Double(updatedCount)
        customCountTextField.text = ""
        
        del.updateData(forDocumentID: docID, collectionID: del.collectionID(), field: "count", newValue: updatedCount)
    }
    
    private func updateFirestoreField(textField: UITextField) {
        guard let docID = documentID, let del = delegate else { return }
        let field: String
        let value: Any
        
        switch textField {
        case nameTextField:
            field = "name"
            value = textField.text ?? ""
        case countTextField:
            field = "count"
            value = Int(textField.text ?? "0") ?? 0
        default:
            return
        }
        
        del.updateData(forDocumentID: docID, collectionID: del.collectionID(), field: field, newValue: value)
    }
    
    private func updateCountInFirestore(newValue: Int) {
        guard let indexPath = indexPath, let del = delegate else { return }
        del.updateItem(at: indexPath, with: newValue)
    }
    
    func configure(with item: Item, collectionSuffix: String) {
        documentID = item.id
        nameTextField.text = item.name
        countTextField.text = String(item.count)
        countStepper.value = Double(item.count)
        
        // Set background image
        if let imageName = item.imageName, let backgroundImage = UIImage(named: imageName) {
            backgroundImageView.image = backgroundImage
            print("Set background image for item \(item.id)")
        } else {
            backgroundImageView.image = UIImage(named: "default_background")
            print("Set default background image for item \(item.id)")
        }
        
        // Set overlay color
        overlayView.backgroundColor = item.color.withAlphaComponent(0.5)
        
        self.collectionSuffix = collectionSuffix
        
        countStepper.addTarget(self, action: #selector(stepperValueChanged(_:)), for: .valueChanged)
    }
    
    func setEditable(_ isEditable: Bool) {
        nameTextField.isEnabled = isEditable
        countTextField.isEnabled = isEditable
        editButton.isHidden = !isEditable
        
        if isEditable {
            let editTapGesture = UITapGestureRecognizer(target: self, action: #selector(showEditMenu))
            contentView.addGestureRecognizer(editTapGesture)
        } else {
            contentView.gestureRecognizers?.forEach(contentView.removeGestureRecognizer)
        }
    }
    
    @objc private func showEditMenu() {
        guard let indexPath = indexPath, let delegate = delegate as? Tab1ViewController else { return }
        delegate.presentEditMenu(for: self, at: indexPath)
    }
    
    func setSelectable(_ isSelectable: Bool) {
        isSelectionModeEnabled = isSelectable
        updateSelectionMode()
    }
    
    private func updateSelectionMode() {
        if isSelectionModeEnabled {
            self.layer.borderWidth = 2.0
            self.layer.borderColor = UIColor.red.cgColor
            selectionIndicator.isHidden = !isSelected
        } else {
            self.layer.borderWidth = 2.0
            self.layer.borderColor = UIColor.black.cgColor
            selectionIndicator.isHidden = true
        }
    }
    
    override var isSelected: Bool {
        didSet {
            if isSelectionModeEnabled {
                selectionIndicator.isHidden = !isSelected
                self.layer.borderColor = isSelected ? UIColor.red.cgColor : UIColor.black.cgColor
            }
        }
    }
}
