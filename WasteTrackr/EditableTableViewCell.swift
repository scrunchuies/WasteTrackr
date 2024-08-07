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
    var stepper: UIStepper!
    var indexPath: IndexPath?
    weak var delegate: EditableCellDelegate?
    var nameChangedHandler: ((String, IndexPath) -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
        setupConstraints()
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

        stepper = UIStepper()
        stepper.translatesAutoresizingMaskIntoConstraints = false
        stepper.addTarget(self, action: #selector(stepperValueChanged), for: .valueChanged)
        contentView.addSubview(stepper)
    }
    
    func setupConstraints() {
        NSLayoutConstraint.activate([
            nameTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            nameTextField.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            nameTextField.trailingAnchor.constraint(equalTo: countTextField.leadingAnchor, constant: -8),
            
            countTextField.trailingAnchor.constraint(equalTo: stepper.leadingAnchor, constant: -8),
            countTextField.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            countTextField.widthAnchor.constraint(equalToConstant: 60),

            stepper.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            stepper.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }
    
    @objc func countChanged() {
        guard let text = countTextField.text, let newValue = Int(text), let indexPath = indexPath else { return }
        delegate?.didEditCell(at: indexPath, newValue: newValue)
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        guard let text = textField.text, let indexPath = indexPath else { return }
        nameChangedHandler?(text, indexPath)
    }

    func configure(with item: Item, collectionSuffix: String, nameChangedHandler: @escaping (String, IndexPath) -> Void) {
        nameTextField.text = item.name
        countTextField.text = "\(item.count)"
        stepper.value = Double(item.count)
        self.nameChangedHandler = nameChangedHandler
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
        stepper.isEnabled = true  // Stepper should always be enabled
    }
}
