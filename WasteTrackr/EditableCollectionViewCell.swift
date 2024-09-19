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
    var nameTextField = UITextField()
    var customCountTextField = UITextField()
    var countTextField = UITextField()
    var countStepper = UIStepper()
    var selectionIndicator = UIView()
    var editButton = UIButton(type: .system)
    var indexPath: IndexPath?
    
    var documentID: String?
    var collectionSuffix: String?
    
    var nameBarView = UIView()
    var isSelectionModeEnabled = false
    
    // Tracks if we are allowing textfield editing
    var isCountTextFieldEditable = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        addGestureRecognizers()
        self.layer.cornerRadius = 30
        self.layer.masksToBounds = true
        self.layer.borderColor = UIColor.black.cgColor
        self.layer.borderWidth = 2.0
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        // Configure backgroundImageView with circular border
        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.clipsToBounds = true
        backgroundImageView.layer.cornerRadius = 50 // Circular image
        backgroundImageView.layer.masksToBounds = true
        backgroundImageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(backgroundImageView)
        
        // Configure nameTextField directly without a background
        nameTextField.layer.borderWidth = 0
        nameTextField.placeholder = "Enter name"
        nameTextField.textAlignment = .center
        nameTextField.returnKeyType = .done
        nameTextField.delegate = self
        nameTextField.font = UIFont.boldSystemFont(ofSize: 22)
        nameTextField.isEnabled = false
        nameTextField.backgroundColor = .clear
        nameTextField.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(nameTextField)
        
        // Configure countTextField
        countTextField.font = .systemFont(ofSize: 40)
        countTextField.placeholder = "Enter #"
        countTextField.textAlignment = .center
        countTextField.returnKeyType = .done
        countTextField.delegate = self
        countTextField.isEnabled = false
        countTextField.backgroundColor = .clear
        countTextField.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(countTextField)
        
        // Configure countStepper
        countStepper.wraps = false
        countStepper.layer.cornerRadius = 8
        countStepper.backgroundColor = .white
        countStepper.autorepeat = true
        countStepper.minimumValue = 0
        countStepper.maximumValue = 1000
        countStepper.addTarget(self, action: #selector(stepperValueChanged(_:)), for: .valueChanged)
        countStepper.translatesAutoresizingMaskIntoConstraints = false
        countStepper.tintColor = .white
        contentView.addSubview(countStepper)
        
        // Setting the content hugging and compression resistance priorities
        nameTextField.setContentHuggingPriority(.defaultLow, for: .vertical)
        countTextField.setContentHuggingPriority(.defaultHigh, for: .vertical)
        countStepper.setContentHuggingPriority(.defaultHigh, for: .vertical)
        
        countTextField.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        countStepper.setContentCompressionResistancePriority(.required, for: .vertical)
        
        // Update constraints
        NSLayoutConstraint.activate([
            // BackgroundImageView constraints
            backgroundImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            backgroundImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            backgroundImageView.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.4),
            backgroundImageView.heightAnchor.constraint(equalTo: backgroundImageView.widthAnchor), // Circular aspect ratio
            
            // NameTextField constraints
            nameTextField.topAnchor.constraint(equalTo: backgroundImageView.bottomAnchor, constant: 10),
            nameTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            nameTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),
            
            // CountTextField constraints
            countTextField.topAnchor.constraint(equalTo: nameTextField.bottomAnchor, constant: 5),
            countTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            countTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),
            
            // CountStepper constraints
            countStepper.topAnchor.constraint(equalTo: countTextField.bottomAnchor, constant: 10),
            countStepper.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            countStepper.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -10)
        ])
    }
    
    private func addGestureRecognizers() {
        // Swipe right to increment the count
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        swipeRight.direction = .right
        contentView.addGestureRecognizer(swipeRight)
        
        // Swipe left to decrement the count
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        swipeLeft.direction = .left
        contentView.addGestureRecognizer(swipeLeft)
    }
    
    @objc private func handleSwipe(_ gesture: UISwipeGestureRecognizer) {
        guard let currentCountText = countTextField.text, let currentCount = Int(currentCountText) else {
            return
        }
        
        switch gesture.direction {
        case .right:
            // Increment the count when swiping right
            let newCount = currentCount + 1
            countTextField.text = "\(newCount)"
            updateCountInFirestore(newValue: newCount)
        case .left:
            // Decrement the count when swiping left, ensure count doesn't go below 0
            let newCount = max(currentCount - 1, 0)
            countTextField.text = "\(newCount)"
            updateCountInFirestore(newValue: newCount)
        default:
            break
        }
    }
    
    private func updateCountInFirestore(newValue: Int) {
        guard let indexPath = indexPath, let del = delegate else { return }
        del.updateItem(at: indexPath, with: newValue, newStockCount: 0)  // Update Firestore with the new count
    }
    
    @objc private func stepperValueChanged(_ sender: UIStepper) {
        let newValue = Int(sender.value)
        countTextField.text = String(newValue)
        // Update Firestore with the new count when the stepper value changes
        updateCountInFirestore(newValue: newValue)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        countStepper.value = 0
        countTextField.text = "0"
        backgroundImageView.image = nil
        contentView.backgroundColor = .clear // Reset background color
    }
    
    func configure(with item: Item, collectionSuffix: String) {
        documentID = item.id
        nameTextField.text = item.name
        countTextField.text = String(item.count)
        countStepper.value = Double(item.count)
        
        // Set the background image
        if let imageName = item.imageName, let backgroundImage = UIImage(named: imageName) {
            backgroundImageView.image = backgroundImage
        } else {
            backgroundImageView.image = UIImage(named: "default_background")
        }
        
        // Update cell background color based on item color
        contentView.backgroundColor = item.color.withAlphaComponent(0.9)
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField == countTextField, let newValue = Int(textField.text ?? "0") {
            // Update Firestore when the countTextField finishes editing
            updateCountInFirestore(newValue: newValue)
        } else if textField == nameTextField, let newName = textField.text {
            // Update Firestore when the nameTextField finishes editing
            updateNameInFirestore(newName: newName)
        }
    }
    private func updateNameInFirestore(newName: String) {
        guard let indexPath = indexPath, let del = delegate else { return }
        // Call delegate to update the name in Firestore
        del.didEditName(at: indexPath, newName: newName)
    }

}
