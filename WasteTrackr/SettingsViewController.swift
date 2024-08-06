// SettingsViewController.swift
// WasteTrackr
//
// Created by Piotr Jandura on 5/22/24.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth

class SettingsViewController: UIViewController, UITextFieldDelegate {
    // User Profile Management Views
    var accountHolderNameLabel: UILabel!
    var nameTextField: UITextField!
    var logoutButton: UIButton!

    // Notification Settings Views
    var allNotificationsSwitch: UISwitch!
    var allNotificationsLabel: UILabel!
    var storageRoomSwitch: UISwitch!
    var storageRoomLabel: UILabel!
    var frontOfHouseSwitch: UISwitch!
    var frontOfHouseLabel: UILabel!
    var backOfHouseSwitch: UISwitch!
    var backOfHouseLabel: UILabel!
    var bulkWasteSwitch: UISwitch!
    var bulkWasteLabel: UILabel!
    var notificationSeparators: [UIView] = []
    var fcmLabel: UILabel!

    // Display and Accessibility Options Views
    var themeSegmentedControl: UISegmentedControl!

    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .light // Default to light mode
        setupViews()
        setupConstraints()
        loadUserProfile()
        loadNotificationSettings()
        loadDisplaySettings()
        setupGestureRecognizers()
    }

    func setupViews() {
        // Initialize and configure views

        // User Profile Management
        accountHolderNameLabel = UILabel()
        accountHolderNameLabel.font = .systemFont(ofSize: 15)
        accountHolderNameLabel.text = "Account holder's name"

        nameTextField = UITextField()
        nameTextField.borderStyle = .roundedRect
        nameTextField.delegate = self

        logoutButton = UIButton(type: .system)
        logoutButton.setTitle("Logout", for: .normal)
        logoutButton.addTarget(self, action: #selector(logout), for: .touchUpInside)

        // Notification Settings
        allNotificationsLabel = UILabel()
        allNotificationsLabel.text = "All Notifications"
        allNotificationsSwitch = createSwitch(selector: #selector(notificationSwitchChanged))

        storageRoomLabel = UILabel()
        storageRoomLabel.text = "Storage Room"
        storageRoomSwitch = createSwitch(selector: #selector(notificationSwitchChanged))

        frontOfHouseLabel = UILabel()
        frontOfHouseLabel.text = "Front of House"
        frontOfHouseSwitch = createSwitch(selector: #selector(notificationSwitchChanged))

        backOfHouseLabel = UILabel()
        backOfHouseLabel.text = "Back of House"
        backOfHouseSwitch = createSwitch(selector: #selector(notificationSwitchChanged))

        bulkWasteLabel = UILabel()
        bulkWasteLabel.text = "Bulk Waste"
        bulkWasteSwitch = createSwitch(selector: #selector(notificationSwitchChanged))

        // Add separators
        for _ in 0..<5 {
            let separator = UIView()
            separator.backgroundColor = UIColor.lightGray.withAlphaComponent(0.5)
            notificationSeparators.append(separator)
            view.addSubview(separator)
        }

        // Display and Accessibility Options
        themeSegmentedControl = UISegmentedControl(items: ["Light", "Dark", "System"])
        themeSegmentedControl.selectedSegmentIndex = 0 // Default to "Light"
        themeSegmentedControl.addTarget(self, action: #selector(themeChanged), for: .valueChanged)

        // Initialize and configure fcmLabel
        fcmLabel = UILabel()
        fcmLabel.text = "latestFCMToken"
        fcmLabel.font = .systemFont(ofSize: 12) // Set to a smaller font size
        fcmLabel.textAlignment = .center // Center align the text

        // Add tap gesture recognizer to fcmLabel
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(copyFCMToClipboard))
        fcmLabel.isUserInteractionEnabled = true
        fcmLabel.addGestureRecognizer(tapGestureRecognizer)

        // Add views to the main view
        view.addSubview(accountHolderNameLabel)
        view.addSubview(nameTextField)
        view.addSubview(logoutButton)
        view.addSubview(allNotificationsLabel)
        view.addSubview(allNotificationsSwitch)
        view.addSubview(storageRoomLabel)
        view.addSubview(storageRoomSwitch)
        view.addSubview(frontOfHouseLabel)
        view.addSubview(frontOfHouseSwitch)
        view.addSubview(backOfHouseLabel)
        view.addSubview(backOfHouseSwitch)
        view.addSubview(bulkWasteLabel)
        view.addSubview(bulkWasteSwitch)
        view.addSubview(themeSegmentedControl)
        view.addSubview(fcmLabel) // Add fcmLabel to the view
    }

    @objc func copyFCMToClipboard() {
        UIPasteboard.general.string = fcmLabel.text
        let alert = UIAlertController(title: "Copied to Clipboard", message: "FCM Token has been copied to clipboard.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }

    func setupConstraints() {
        // Disable autoresizing mask translation
        let views: [UIView?] = [
            accountHolderNameLabel, nameTextField, logoutButton,
            allNotificationsLabel, allNotificationsSwitch,
            storageRoomLabel, storageRoomSwitch,
            frontOfHouseLabel, frontOfHouseSwitch,
            backOfHouseLabel, backOfHouseSwitch,
            bulkWasteLabel, bulkWasteSwitch,
            themeSegmentedControl, fcmLabel
        ]
        views.forEach { $0?.translatesAutoresizingMaskIntoConstraints = false }
        notificationSeparators.forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        // Add constraints
        let margin = view.layoutMarginsGuide

        NSLayoutConstraint.activate([
            // User Profile Management
            accountHolderNameLabel.topAnchor.constraint(equalTo: margin.topAnchor, constant: 20),
            accountHolderNameLabel.leadingAnchor.constraint(equalTo: margin.leadingAnchor),

            nameTextField.topAnchor.constraint(equalTo: accountHolderNameLabel.bottomAnchor, constant: 5),
            nameTextField.leadingAnchor.constraint(equalTo: margin.leadingAnchor),
            nameTextField.trailingAnchor.constraint(equalTo: margin.trailingAnchor),

            logoutButton.topAnchor.constraint(equalTo: nameTextField.bottomAnchor, constant: 10),
            logoutButton.leadingAnchor.constraint(equalTo: margin.leadingAnchor),
            logoutButton.trailingAnchor.constraint(equalTo: margin.trailingAnchor),

            // Notification Settings
            allNotificationsLabel.topAnchor.constraint(equalTo: logoutButton.bottomAnchor, constant: 20),
            allNotificationsLabel.leadingAnchor.constraint(equalTo: margin.leadingAnchor),
            
            allNotificationsSwitch.centerYAnchor.constraint(equalTo: allNotificationsLabel.centerYAnchor),
            allNotificationsSwitch.trailingAnchor.constraint(equalTo: margin.trailingAnchor, constant: -10),

            storageRoomLabel.topAnchor.constraint(equalTo: allNotificationsLabel.bottomAnchor, constant: 20),
            storageRoomLabel.leadingAnchor.constraint(equalTo: margin.leadingAnchor),

            storageRoomSwitch.centerYAnchor.constraint(equalTo: storageRoomLabel.centerYAnchor),
            storageRoomSwitch.trailingAnchor.constraint(equalTo: margin.trailingAnchor, constant: -10),

            frontOfHouseLabel.topAnchor.constraint(equalTo: storageRoomLabel.bottomAnchor, constant: 20),
            frontOfHouseLabel.leadingAnchor.constraint(equalTo: margin.leadingAnchor),

            frontOfHouseSwitch.centerYAnchor.constraint(equalTo: frontOfHouseLabel.centerYAnchor),
            frontOfHouseSwitch.trailingAnchor.constraint(equalTo: margin.trailingAnchor, constant: -10),

            backOfHouseLabel.topAnchor.constraint(equalTo: frontOfHouseLabel.bottomAnchor, constant: 20),
            backOfHouseLabel.leadingAnchor.constraint(equalTo: margin.leadingAnchor),

            backOfHouseSwitch.centerYAnchor.constraint(equalTo: backOfHouseLabel.centerYAnchor),
            backOfHouseSwitch.trailingAnchor.constraint(equalTo: margin.trailingAnchor, constant: -10),

            bulkWasteLabel.topAnchor.constraint(equalTo: backOfHouseLabel.bottomAnchor, constant: 20),
            bulkWasteLabel.leadingAnchor.constraint(equalTo: margin.leadingAnchor),

            bulkWasteSwitch.centerYAnchor.constraint(equalTo: bulkWasteLabel.centerYAnchor),
            bulkWasteSwitch.trailingAnchor.constraint(equalTo: margin.trailingAnchor, constant: -10),

            // Display and Accessibility Options
            themeSegmentedControl.topAnchor.constraint(equalTo: bulkWasteSwitch.bottomAnchor, constant: 20),
            themeSegmentedControl.leadingAnchor.constraint(equalTo: margin.leadingAnchor),
            themeSegmentedControl.trailingAnchor.constraint(equalTo: margin.trailingAnchor),

            // fcmLabel at the very bottom
            fcmLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            fcmLabel.leadingAnchor.constraint(equalTo: margin.leadingAnchor),
            fcmLabel.trailingAnchor.constraint(equalTo: margin.trailingAnchor)
        ])

        // Add separators
        let labels = [
            allNotificationsLabel,
            storageRoomLabel,
            frontOfHouseLabel,
            backOfHouseLabel,
            bulkWasteLabel
        ]
        
        for (index, separator) in notificationSeparators.enumerated() {
            if let label = labels[index] { // Safely unwrapping
                NSLayoutConstraint.activate([
                    separator.leadingAnchor.constraint(equalTo: margin.leadingAnchor),
                    separator.trailingAnchor.constraint(equalTo: margin.trailingAnchor),
                    separator.heightAnchor.constraint(equalToConstant: 1),
                    separator.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 10)
                ])
            }
        }
    }

    func createSwitch(selector: Selector) -> UISwitch {
        let switchControl = UISwitch()
        switchControl.isOn = true
        switchControl.addTarget(self, action: selector, for: .valueChanged)
        return switchControl
    }

    // MARK: - User Profile Management

    func loadUserProfile() {
        guard let user = Auth.auth().currentUser else { return }
        let db = Firestore.firestore()
        let docRef = db.collection("userProfiles").document(user.uid)

        docRef.getDocument { (document, error) in
            if let document = document, document.exists {
                let data = document.data()
                if let name = data?["name"] as? String {
                    self.nameTextField.placeholder = "Please enter a name"
                    self.nameTextField.text = name
                }
                if let latestFCMToken = data?["latestFCMToken"] as? String {
                    self.fcmLabel.text = latestFCMToken
                }
            } else {
                self.createUserProfile(for: user)
            }
        }
    }

    func createUserProfile(for user: User) {
        let db = Firestore.firestore()
        let userRef = db.collection("userProfiles").document(user.uid)
        let userData: [String: Any] = [
            "name": "",
            "email": user.email ?? ""
        ]
        userRef.setData(userData) { error in
            if let error = error {
                print("Error creating user profile: \(error)")
            } else {
                self.nameTextField.text = ""
                self.nameTextField.placeholder = "Please enter a name"
            }
        }
    }

    @objc func saveProfileChanges() {
        guard let user = Auth.auth().currentUser else { return }
        let db = Firestore.firestore()
        let userRef = db.collection("userProfiles").document(user.uid)

        let updatedData: [String: Any] = [
            "name": nameTextField.text ?? ""
        ]

        userRef.updateData(updatedData) { error in
            if let error = error {
                print("Error updating document: \(error)")
            } else {
                print("Document successfully updated")
            }
        }
    }

    @objc func logout() {
        do {
            try Auth.auth().signOut()
            NotificationCenter.default.post(name: NSNotification.Name("UserDidLogout"), object: nil)
            performSegue(withIdentifier: "logoutSwish", sender: self)
        } catch let signOutError as NSError {
            print("Error signing out: \(signOutError)")
        }
    }

    // MARK: - Notification Settings

    func loadNotificationSettings() {
        let userDefaults = UserDefaults.standard
        allNotificationsSwitch.isOn = userDefaults.bool(forKey: "allNotifications")
        storageRoomSwitch.isOn = userDefaults.bool(forKey: "storageRoomNotifications")
        frontOfHouseSwitch.isOn = userDefaults.bool(forKey: "frontOfHouseNotifications")
        backOfHouseSwitch.isOn = userDefaults.bool(forKey: "backOfHouseNotifications")
        bulkWasteSwitch.isOn = userDefaults.bool(forKey: "bulkWasteNotifications")
        updateNotificationSwitches()
    }

    @objc func notificationSwitchChanged(_ sender: UISwitch) {
        let userDefaults = UserDefaults.standard
        switch sender {
        case allNotificationsSwitch:
            userDefaults.set(sender.isOn, forKey: "allNotifications")
            updateNotificationSwitches()
        case storageRoomSwitch:
            userDefaults.set(sender.isOn, forKey: "storageRoomNotifications")
        case frontOfHouseSwitch:
            userDefaults.set(sender.isOn, forKey: "frontOfHouseNotifications")
        case backOfHouseSwitch:
            userDefaults.set(sender.isOn, forKey: "backOfHouseNotifications")
        case bulkWasteSwitch:
            userDefaults.set(sender.isOn, forKey: "bulkWasteNotifications")
        default:
            break
        }
    }

    func updateNotificationSwitches() {
        let isAllNotificationsOn = allNotificationsSwitch.isOn
        storageRoomSwitch.isEnabled = !isAllNotificationsOn
        frontOfHouseSwitch.isEnabled = !isAllNotificationsOn
        backOfHouseSwitch.isEnabled = !isAllNotificationsOn
        bulkWasteSwitch.isEnabled = !isAllNotificationsOn
    }

    // MARK: - Display and Accessibility Options

    func loadDisplaySettings() {
        guard let user = Auth.auth().currentUser else { return }
        let db = Firestore.firestore()
        let docRef = db.collection("userProfiles").document(user.uid)

        docRef.getDocument { [weak self] (document, error) in
            guard let self = self else { return }
            if let document = document, document.exists {
                let data = document.data()
                self.themeSegmentedControl.selectedSegmentIndex = data?["theme"] as? Int ?? 0
                self.applyTheme()
            } else {
                // If the document does not exist, create it with default settings
                self.themeSegmentedControl.selectedSegmentIndex = 0
                self.saveDisplaySettings()
            }
        }
    }

    @objc func saveDisplaySettings() {
        guard let user = Auth.auth().currentUser else { return }
        let db = Firestore.firestore()
        let userRef = db.collection("userProfiles").document(user.uid)

        let updatedData: [String: Any] = [
            "theme": themeSegmentedControl.selectedSegmentIndex
        ]

        userRef.setData(updatedData, merge: true) { error in
            if let error = error {
                print("Error updating document: \(error)")
            } else {
                print("Document successfully updated")
                self.applyTheme()
            }
        }
    }

    @objc func themeChanged() {
        saveDisplaySettings()
    }

    func applyTheme() {
        switch themeSegmentedControl.selectedSegmentIndex {
        case 0:
            overrideUserInterfaceStyle = .light
        case 1:
            overrideUserInterfaceStyle = .dark
        default:
            overrideUserInterfaceStyle = .unspecified
        }
    }

    // MARK: - Keyboard Handling

    func setupGestureRecognizers() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
    }

    @objc func dismissKeyboard() {
        view.endEditing(true)
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        saveProfileChanges()
        return true
    }
}
