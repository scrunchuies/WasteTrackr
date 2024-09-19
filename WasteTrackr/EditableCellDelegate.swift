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
    func updateItem(at indexPath: IndexPath, with newValue: Int, newStockCount: Int)
    func deleteItem(at indexPath: IndexPath)
    func presentEditMenu(for cell: EditableCollectionViewCell, at indexPath: IndexPath)
    func didEditCell(at indexPath: IndexPath, newValue: Int)
    func didEditStockCount(at indexPath: IndexPath, newStockCount: Int)
    func didEditLocation(at indexPath: IndexPath, newLocation: String)
    func didEditName(at indexPath: IndexPath, newName: String)
}
