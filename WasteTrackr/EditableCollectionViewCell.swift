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
    var indexPath: IndexPath?
    
    var documentID: String?
    var collectionSuffix: String?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        self.layer.cornerRadius = 10 // Rounded corners
        self.layer.masksToBounds = true
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
        selectionIndicator.backgroundColor = UIColor.red.withAlphaComponent(0.5)
        selectionIndicator.translatesAutoresizingMaskIntoConstraints = false
        selectionIndicator.isHidden = true
        contentView.addSubview(selectionIndicator)
        
        // Add nameTextField
        nameTextField.borderStyle = .roundedRect
        nameTextField.placeholder = "Enter name"
        nameTextField.textAlignment = .center
        nameTextField.returnKeyType = .done
        nameTextField.delegate = self
        nameTextField.font = UIFont.systemFont(ofSize: 16)
        nameTextField.isEnabled = false
        nameTextField.backgroundColor = .white
        nameTextField.alpha = 0.95
        nameTextField.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(nameTextField)
        
        // Add countTextField
        countTextField.borderStyle = .roundedRect
        countTextField.placeholder = "Enter #"
        countTextField.textAlignment = .center
        countTextField.returnKeyType = .done
        countTextField.delegate = self
        countTextField.font = UIFont.systemFont(ofSize: 16)
        countTextField.isEnabled = false
        countTextField.backgroundColor = .white
        countTextField.alpha = 0.95
        countTextField.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(countTextField)
        
        // Add customCountTextField
        customCountTextField.borderStyle = .roundedRect
        customCountTextField.placeholder = "Custom #"
        customCountTextField.textAlignment = .center
        customCountTextField.returnKeyType = .done
        customCountTextField.delegate = self
        customCountTextField.font = UIFont.systemFont(ofSize: 16)
        customCountTextField.isEnabled = true
        customCountTextField.backgroundColor = .white
        customCountTextField.alpha = 0.95
        customCountTextField.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(customCountTextField)
        
        // Add countStepper
        countStepper.wraps = false
        countStepper.layer.cornerRadius = 8
        countStepper.backgroundColor = .white
        countStepper.alpha = 0.95
        countStepper.autorepeat = true
        countStepper.minimumValue = 0
        countStepper.maximumValue = 1000
        countStepper.addTarget(self, action: #selector(stepperValueChanged(_:)), for: .valueChanged)
        countStepper.translatesAutoresizingMaskIntoConstraints = false
        countStepper.tintColor = .white // Set the tint color to white
        contentView.addSubview(countStepper)
        
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
            
            nameTextField.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 5),
            nameTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 5),
            nameTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -5),
            
            countTextField.topAnchor.constraint(equalTo: nameTextField.bottomAnchor, constant: 5),
            countTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 5),
            countTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -5),
            
            customCountTextField.topAnchor.constraint(equalTo: countTextField.bottomAnchor, constant: 5),
            customCountTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 5),
            customCountTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -5),
            
            countStepper.topAnchor.constraint(equalTo: customCountTextField.bottomAnchor, constant: 5),
            countStepper.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            countStepper.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -5)
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
        self.layer.borderWidth = 0.0 // Reset the border width
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
    }
    
    func setSelectable(_ isSelectable: Bool) {
        self.layer.borderWidth = isSelectable ? 2.0 : 0.0
        self.layer.borderColor = isSelectable ? UIColor.red.cgColor : nil
        selectionIndicator.isHidden = !isSelectable
    }
    
    override var isSelected: Bool {
        didSet {
            selectionIndicator.isHidden = !isSelected
        }
    }
}
