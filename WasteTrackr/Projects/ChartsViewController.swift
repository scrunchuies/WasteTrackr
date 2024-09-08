//  ChartsViewController.swift
//  WasteTrackr
//
//  Created by Piotr Jandura on 6/6/24.
//

import UIKit
import SwiftUI
import Charts
import FirebaseFirestore
import FirebaseAuth

class ChartsViewController: UIViewController {
    @IBOutlet weak var chartViewContainer: UIView!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    var items: [Item] = []
    var listener: ListenerRegistration?
    var collectionSuffix: String = "FOH"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        observeItems()
    }
    
    @IBAction func segmentedControlChanged(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            collectionSuffix = "FOH"
        case 1:
            collectionSuffix = "BOH"
        case 2:
            collectionSuffix = "BLK"
        default:
            collectionSuffix = "FOH"
        }
        observeItems()
    }
    
    func observeItems() {
        let collectionId = collectionID(forSuffix: collectionSuffix)
        print("Using collection ID: \(collectionId)")
        let db = Firestore.firestore()
        
        listener?.remove()
        
        listener = db.collection(collectionId).order(by: "timestamp", descending: false).addSnapshotListener { [weak self] querySnapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Error fetching snapshots: \(error)")
                return
            }
            
            guard let snapshot = querySnapshot else {
                print("No data found in collection: \(collectionId)")
                return
            }
            
            print("Fetched \(snapshot.documents.count) documents")
            self.items = snapshot.documents.compactMap { doc -> Item? in
                let item = Item(document: doc)
                if item == nil {
                    print("Failed to parse document: \(doc.documentID)")
                }
                return item
            }
            
            print("Parsed items: \(self.items)")
            self.updateChart()
        }
    }
    
    func updateChart() {
        var barData: [(x: Date, y: Double)] = []
        
        for item in items {
            for logEntry in item.changeLog {
                if let timestamp = logEntry["timestamp"] as? Timestamp,
                   let newCount = logEntry["newCount"] as? Int {
                    barData.append((x: timestamp.dateValue(), y: Double(newCount)))
                }
            }
        }
        
        let chartView = UIHostingController(rootView: BarChartView(barData: barData))
        addChild(chartView)
        chartView.view.translatesAutoresizingMaskIntoConstraints = false
        chartViewContainer.addSubview(chartView.view)
        
        // Set constraints for the hosted view
        NSLayoutConstraint.activate([
            chartView.view.leadingAnchor.constraint(equalTo: chartViewContainer.leadingAnchor),
            chartView.view.trailingAnchor.constraint(equalTo: chartViewContainer.trailingAnchor),
            chartView.view.topAnchor.constraint(equalTo: chartViewContainer.topAnchor),
            chartView.view.bottomAnchor.constraint(equalTo: chartViewContainer.bottomAnchor)
        ])
        
        chartView.didMove(toParent: self)
    }
    
    func collectionID(forSuffix suffix: String) -> String {
        if let storeId = UserDefaults.standard.string(forKey: "UserStoreID") {
            return "\(storeId)-\(suffix)"
        } else {
            print("Store ID not set, defaulting to a temporary value")
            return "defaultStoreID-\(suffix)"
        }
    }
}

struct BarChartView: View {
    let barData: [(x: Date, y: Double)]
    
    var body: some View {
        Chart {
            ForEach(barData, id: \.x) { entry in
                BarMark(
                    x: .value("Date", entry.x, unit: .day),
                    y: .value("Count", entry.y)
                )
                .foregroundStyle(.blue)
            }
        }
        .chartXAxisLabel("Date")
        .chartYAxisLabel("Count")
        .padding()
    }
}
