//
//  EditableCellDelegate.swift
//  WasteTrackr
//
//  Created by Piotr Jandura on 5/9/24.
//

import UIKit

protocol EditableCellDelegate: AnyObject {
    func updateData(forDocumentID docID: String, collectionID: String, field: String, newValue: Any)
    func shouldEnableEditing() -> Bool
    func collectionID() -> String
}
