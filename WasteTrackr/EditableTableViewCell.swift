//
//  EditableTableViewCell.swift
//  WasteTrackr
//
//  Created by Piotr Jandura on 5/8/24.
//

import UIKit

class EditableTableViewCell: UITableViewCell, UITextFieldDelegate {
    var textField = UITextField()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupTextField()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupTextField() {
        textField.frame = self.contentView.bounds.insetBy(dx: 15, dy: 0)
        textField.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        textField.delegate = self  // Set delegate to self
        textField.returnKeyType = .done
        self.contentView.addSubview(textField)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()  // Hide the keyboard
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        // Optionally, notify the view controller if needed
    }
}
