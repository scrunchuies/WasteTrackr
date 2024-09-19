//
//  EditableTableViewCell.swift
//  WasteTrackr
//
//  Created by Piotr Jandura on 5/8/24.
//

import UIKit
import FirebaseFirestore

class EditableTableViewCell: UITableViewCell, UITextFieldDelegate {
    var nameTextField: UITextField!
    var countTextField: UITextField!
    var stockCountTextField: UITextField!
    var stepper: UIStepper!
    var indexPath: IndexPath?
    weak var delegate: EditableCellDelegate?
    var nameChangedHandler: ((String, IndexPath) -> Void)?
    var itemImageView: UIImageView!
    var locationTextField: UITextField!
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
        setupConstraints()
        addLongPressGesture()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupViews() {
        nameTextField = UITextField()
        nameTextField.borderStyle = .roundedRect
        nameTextField.translatesAutoresizingMaskIntoConstraints = false
        nameTextField.delegate = self
        contentView.addSubview(nameTextField)
        
        countTextField = UITextField()
        countTextField.translatesAutoresizingMaskIntoConstraints = false
        countTextField.keyboardType = .numberPad
        countTextField.borderStyle = .roundedRect
        countTextField.addTarget(self, action: #selector(countChanged), for: .editingChanged)
        contentView.addSubview(countTextField)
        
        stockCountTextField = UITextField()
        stockCountTextField.translatesAutoresizingMaskIntoConstraints = false
        stockCountTextField.keyboardType = .numberPad
        stockCountTextField.borderStyle = .roundedRect
        stockCountTextField.addTarget(self, action: #selector(stockCountChanged), for: .editingChanged)
        contentView.addSubview(stockCountTextField)
        
        locationTextField = UITextField()
        locationTextField.borderStyle = .roundedRect
        locationTextField.translatesAutoresizingMaskIntoConstraints = false
        locationTextField.addTarget(self, action: #selector(locationChanged), for: .editingDidEnd)
        contentView.addSubview(locationTextField)
        
        stepper = UIStepper()
        stepper.translatesAutoresizingMaskIntoConstraints = false
        stepper.addTarget(self, action: #selector(stepperValueChanged), for: .valueChanged)
        contentView.addSubview(stepper)
        
        // Initialize the image view for preview
        itemImageView = UIImageView()
        itemImageView.translatesAutoresizingMaskIntoConstraints = false
        itemImageView.contentMode = .scaleAspectFit
        itemImageView.isHidden = true // Hidden until long press
        contentView.addSubview(itemImageView)
    }
    
    func setupConstraints() {
        // Remove any autoresizing masks to avoid conflicts with Auto Layout
        nameTextField.translatesAutoresizingMaskIntoConstraints = false
        countTextField.translatesAutoresizingMaskIntoConstraints = false
        stockCountTextField.translatesAutoresizingMaskIntoConstraints = false
        stepper.translatesAutoresizingMaskIntoConstraints = false
        itemImageView.translatesAutoresizingMaskIntoConstraints = false
        locationTextField.translatesAutoresizingMaskIntoConstraints = false
        
        // Set compression resistance and content hugging priority to avoid collapsing
        nameTextField.setContentHuggingPriority(.defaultHigh, for: .vertical)
        countTextField.setContentHuggingPriority(.defaultHigh, for: .vertical)
        stockCountTextField.setContentHuggingPriority(.defaultHigh, for: .vertical)
        locationTextField.setContentHuggingPriority(.defaultHigh, for: .vertical)
        
        // Activate constraints
        NSLayoutConstraint.activate([
            // Name Text Field Constraints
            nameTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            nameTextField.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            nameTextField.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            nameTextField.trailingAnchor.constraint(equalTo: countTextField.leadingAnchor, constant: -8),
            
            // Count Text Field Constraints
            countTextField.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            countTextField.widthAnchor.constraint(equalToConstant: 60),
            countTextField.trailingAnchor.constraint(equalTo: stockCountTextField.leadingAnchor, constant: -8),
            
            // Stock Count Text Field Constraints
            stockCountTextField.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            stockCountTextField.widthAnchor.constraint(equalToConstant: 60),
            stockCountTextField.trailingAnchor.constraint(equalTo: locationTextField.leadingAnchor, constant: -8),
            
            // Location Text Field Constraints
            locationTextField.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            locationTextField.widthAnchor.constraint(equalToConstant: 60),
            locationTextField.trailingAnchor.constraint(equalTo: stepper.leadingAnchor, constant: -8),
            
            // Stepper Constraints
            stepper.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            stepper.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // Item Image View Constraints (if needed for long press preview)
            itemImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            itemImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            itemImageView.widthAnchor.constraint(equalToConstant: 200),
            itemImageView.heightAnchor.constraint(equalToConstant: 200)
        ])
    }
    
    @objc func countChanged() {
        guard let text = countTextField.text, let newValue = Int(text), let indexPath = indexPath else { return }
        delegate?.didEditCell(at: indexPath, newValue: newValue)
    }
    
    @objc func stockCountChanged() {
        guard let text = stockCountTextField.text, let newValue = Int(text), let indexPath = indexPath else { return }
        delegate?.didEditStockCount(at: indexPath, newStockCount: newValue)
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        guard let text = textField.text, let indexPath = indexPath else { return }
        nameChangedHandler?(text, indexPath)
    }
    
    func configure(with item: Item, collectionSuffix: String, nameChangedHandler: @escaping (String, IndexPath) -> Void) {
        nameTextField.text = item.name
        countTextField.text = "\(item.count)"
        stockCountTextField.text = "\(item.stockCount)"
        locationTextField.text = item.location // Set the location text field
        stepper.value = Double(item.count)
        self.nameChangedHandler = nameChangedHandler
        
        // Set up the item image (if you have it stored in assets)
        let imageName = item.name.lowercased().replacingOccurrences(of: " ", with: "_") // Convert item name to asset name format
        if let image = UIImage(named: imageName) {
            itemImageView.image = image // Load the image from assets
        }
    }
    
    @objc func locationChanged() {
        guard let text = locationTextField.text, let indexPath = indexPath else { return }
        
        // Call the delegate to handle the Firestore update
        delegate?.didEditLocation(at: indexPath, newLocation: text)
    }
    
    @objc func stepperValueChanged() {
        guard let indexPath = indexPath, let delegate = delegate else { return }
        let newValue = Int(stepper.value)
        countTextField.text = "\(newValue)" // Update the count text field
        delegate.didEditCell(at: indexPath, newValue: newValue) // Notify the delegate
    }
    
    func setEditable(_ editable: Bool, keepStepperEnabled: Bool = false) {
        nameTextField.isEnabled = editable
        countTextField.isEnabled = editable
        stockCountTextField.isEnabled = editable  // Enable or disable the stockCountTextField
        locationTextField.isEnabled = editable
        stepper.isEnabled = true  // Stepper should always be enabled
    }
    
    // Add the long press gesture to show image preview
    func addLongPressGesture() {
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        self.addGestureRecognizer(longPressGesture)
    }
    
    @objc func handleLongPress(gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began {
            // Show the image preview when long press begins
            itemImageView.isHidden = false
        } else if gesture.state == .ended || gesture.state == .cancelled {
            // Hide the image preview when long press ends
            itemImageView.isHidden = true
        }
    }
}

