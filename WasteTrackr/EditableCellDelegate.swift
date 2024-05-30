//
//  EditableCellDelegate.swift
//  WasteTrackr
//
//  Created by Piotr Jandura on 5/9/24.
//

import UIKit

protocol EditableCellDelegate: AnyObject {
    func updateData(forDocumentID docID: String, collectionID: String, field: String, newValue: Any)
    func collectionID() -> String
    func shouldEnableEditing() -> Bool
    func updateItem(at indexPath: IndexPath, with newValue: Int)
    func deleteItem(at indexPath: IndexPath)
    func presentEditMenu(for cell: EditableCollectionViewCell, at indexPath: IndexPath)
}
