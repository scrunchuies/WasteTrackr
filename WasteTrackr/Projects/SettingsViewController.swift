// SettingsViewController.swift
// WasteTrackr
//
// Created by Piotr Jandura on 5/22/24.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth
import FirebaseFunctions
import FirebaseStorage

class SettingsViewController: UIViewController, UITextFieldDelegate, UICollectionViewDelegate, UICollectionViewDataSource {
    // User Profile Management Views
    var accountHolderNameLabel: UILabel!
    var nameTextField: UITextField!
    var logoutButton: UIButton!
    var storeCodeLabel: UILabel!
    
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
    var uploadImageButton: UIButton!
    var selectedImageName: String?
    var collectionView: UICollectionView!
    var imageNames: [String] = []
    
    // Display and Accessibility Options Views
    var themeSegmentedControl: UISegmentedControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .light // Default to light mode
        setupViews()
        setupCollectionView()  // Ensure collectionView is initialized before constraints
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
        
        // Store Code Label (instead of a text field)
        storeCodeLabel = UILabel()
        storeCodeLabel.font = .systemFont(ofSize: 17)
        storeCodeLabel.textColor = .darkGray
        storeCodeLabel.isUserInteractionEnabled = true // Enable interaction
        
        // Add tap gesture recognizer to handle tap on the label
        let storeCodeTapGesture = UITapGestureRecognizer(target: self, action: #selector(storeCodeTapped))
        storeCodeLabel.addGestureRecognizer(storeCodeTapGesture)
        
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
        
        uploadImageButton = UIButton(type: .system)
        uploadImageButton.setTitle("Upload Image", for: .normal)
        uploadImageButton.addTarget(self, action: #selector(promptForImageUpload), for: .touchUpInside)
        
        // Add views to the main view
        view.addSubview(accountHolderNameLabel)
        view.addSubview(nameTextField)
        view.addSubview(storeCodeLabel)
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
        view.addSubview(fcmLabel)
        view.addSubview(uploadImageButton)
    }
    
    @objc func copyFCMToClipboard() {
        UIPasteboard.general.string = fcmLabel.text
        let alert = UIAlertController(title: "Copied to Clipboard", message: "FCM Token has been copied to clipboard.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    func setupConstraints() {
        let views: [UIView?] = [
            accountHolderNameLabel, nameTextField, storeCodeLabel, logoutButton,
            allNotificationsLabel, allNotificationsSwitch,
            storageRoomLabel, storageRoomSwitch,
            frontOfHouseLabel, frontOfHouseSwitch,
            backOfHouseLabel, backOfHouseSwitch,
            bulkWasteLabel, bulkWasteSwitch,
            themeSegmentedControl, fcmLabel,
            uploadImageButton, collectionView
        ]
        views.forEach { $0?.translatesAutoresizingMaskIntoConstraints = false }
        notificationSeparators.forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        
        let margin = view.layoutMarginsGuide
        
        NSLayoutConstraint.activate([
            // User Profile Management
            accountHolderNameLabel.topAnchor.constraint(equalTo: margin.topAnchor, constant: 20),
            accountHolderNameLabel.leadingAnchor.constraint(equalTo: margin.leadingAnchor),
            
            nameTextField.topAnchor.constraint(equalTo: accountHolderNameLabel.bottomAnchor, constant: 5),
            nameTextField.leadingAnchor.constraint(equalTo: margin.leadingAnchor),
            nameTextField.trailingAnchor.constraint(equalTo: margin.trailingAnchor),
            
            // Store Code Label Constraints
            storeCodeLabel.topAnchor.constraint(equalTo: nameTextField.bottomAnchor, constant: 10),
            storeCodeLabel.leadingAnchor.constraint(equalTo: margin.leadingAnchor),
            storeCodeLabel.trailingAnchor.constraint(equalTo: margin.trailingAnchor),
            
            logoutButton.topAnchor.constraint(equalTo: storeCodeLabel.bottomAnchor, constant: 10),
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
            
            themeSegmentedControl.topAnchor.constraint(equalTo: bulkWasteSwitch.bottomAnchor, constant: 20),
            themeSegmentedControl.leadingAnchor.constraint(equalTo: margin.leadingAnchor),
            themeSegmentedControl.trailingAnchor.constraint(equalTo: margin.trailingAnchor),
            
            fcmLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            fcmLabel.leadingAnchor.constraint(equalTo: margin.leadingAnchor),
            fcmLabel.trailingAnchor.constraint(equalTo: margin.trailingAnchor),
            
            uploadImageButton.topAnchor.constraint(equalTo: themeSegmentedControl.bottomAnchor, constant: 20),
            uploadImageButton.leadingAnchor.constraint(equalTo: margin.leadingAnchor),
            uploadImageButton.trailingAnchor.constraint(equalTo: margin.trailingAnchor),
            
            collectionView.topAnchor.constraint(equalTo: uploadImageButton.bottomAnchor, constant: 10),
            collectionView.leadingAnchor.constraint(equalTo: margin.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: margin.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: fcmLabel.topAnchor, constant: -20),
            
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
    
    @objc func storeCodeTapped() {
        let alert = UIAlertController(
            title: "Store Code",
            message: "Please contact Piotr Jandura to update your store code.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    // MARK: - User Profile Management
    
    func loadUserProfile() {
        guard let user = Auth.auth().currentUser else { return }
        
        // Fetch store code from UserDefaults using "UserStoreID"
        let storeCode = UserDefaults.standard.string(forKey: "UserStoreID") ?? "00000" // Default value if none exists
        storeCodeLabel.text = "Store Code: \(storeCode)" // Set store code in the label
        
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
            
            if !sender.isOn {
                // Disable all notifications
                disableAllNotifications()
            } else {
                // Enable notifications
                enableAllNotifications()
            }
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
    
    func disableAllNotifications() {
        // Call Firebase or local code to stop notifications
        print("All notifications disabled")
    }
    
    func enableAllNotifications() {
        // Call Firebase or local code to enable notifications
        print("All notifications enabled")
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
    
    func setupCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 100, height: 100)
        
        collectionView = UICollectionView(frame: self.view.bounds, collectionViewLayout: layout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(ImageCell.self, forCellWithReuseIdentifier: "ImageCell")
        collectionView.backgroundColor = .white
        
        self.view.addSubview(collectionView)
    }
    
    func fetchImagesFromFirebase() {
        let storageRef = Storage.storage().reference().child("images/")
        
        storageRef.listAll { (result, error) in
            if let error = error {
                print("Error fetching images: \(error)")
                return
            }
            
            guard let result = result else {
                print("No result found")
                return
            }
            
            var imageUrls: [String] = []
            let dispatchGroup = DispatchGroup()
            
            for item in result.items {
                dispatchGroup.enter()
                item.downloadURL { url, error in
                    if let error = error {
                        print("Error getting image URL: \(error)")
                        dispatchGroup.leave()
                        return
                    }
                    
                    if let url = url {
                        imageUrls.append(url.absoluteString)
                    }
                    dispatchGroup.leave()
                }
            }
            
            dispatchGroup.notify(queue: .main) {
                self.imageNames = imageUrls
                self.collectionView.reloadData()
            }
        }
    }
    
    func saveImageURLToFirestore(imageName: String, url: String) {
        guard let user = Auth.auth().currentUser else { return }
        let db = Firestore.firestore()
        let userRef = db.collection("userProfiles").document(user.uid)
        
        userRef.updateData(["imageURLs.\(imageName)" : url]) { error in
            if let error = error {
                print("Error saving image URL to Firestore: \(error)")
            } else {
                print("Image URL saved to Firestore successfully.")
            }
        }
    }
    
    func saveImageToAssets(image: UIImage, name: String, fileExtension: String) {
        let storageRef = Storage.storage().reference().child("images/\(name).\(fileExtension)")
        
        var imageData: Data?
        var contentType: String?
        
        switch fileExtension.lowercased() {
        case "png":
            imageData = image.pngData()
            contentType = "image/png"
        case "jpg", "jpeg":
            imageData = image.jpegData(compressionQuality: 0.8)
            contentType = "image/jpeg"
        case "heic":
            if #available(iOS 17.0, *) {
                imageData = image.heicData()
            } else {
                // Fallback on earlier versions
            } // Assuming you're using a library or extension to handle HEIC
            contentType = "image/heic"
        default:
            imageData = image.jpegData(compressionQuality: 0.8) // Default to JPEG if unknown format
            contentType = "image/jpeg"
        }
        
        guard let data = imageData, let mimeType = contentType else {
            print("Failed to process image data.")
            return
        }
        
        let metadata = StorageMetadata()
        metadata.contentType = mimeType
        
        storageRef.putData(data, metadata: metadata) { metadata, error in
            if let error = error {
                print("Error uploading image: \(error)")
                return
            }
            
            // Fetch the download URL after upload
            storageRef.downloadURL { url, error in
                if let error = error {
                    print("Error fetching download URL: \(error)")
                    return
                }
                guard let downloadURL = url else { return }
                print("Image uploaded successfully, download URL: \(downloadURL)")
                
                self.saveImageURLToFirestore(imageName: "\(name).\(fileExtension)", url: downloadURL.absoluteString)
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imageNames.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageCell", for: indexPath) as! ImageCell
        let imageUrlString = imageNames[indexPath.item]
        
        // Fetch image data from the URL
        if let url = URL(string: imageUrlString) {
            DispatchQueue.global().async {
                if let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        cell.imageView.image = image
                    }
                }
            }
        }
        
        return cell
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
    
    // MARK: - Upload Media
    
    @objc func promptForImageUpload() {
        let alert = UIAlertController(title: "Image Name", message: "Enter a name for the image", preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = "Image name"
        }
        let uploadAction = UIAlertAction(title: "Upload", style: .default) { [weak self] _ in
            if let imageName = alert.textFields?.first?.text, !imageName.isEmpty {
                self?.pickImage(imageName: imageName)
            }
        }
        alert.addAction(uploadAction)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alert, animated: true)
    }
    
    @objc func pickImage(imageName: String) {
        selectedImageName = imageName  // Store the image name
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .photoLibrary
        imagePicker.delegate = self
        present(imagePicker, animated: true)
    }
}

extension SettingsViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = info[.originalImage] as? UIImage, let imageName = selectedImageName else {
            picker.dismiss(animated: true)
            return
        }
        
        // Determine the file extension based on the image type
        let fileExtension: String
        if let url = info[.imageURL] as? URL {
            fileExtension = url.pathExtension.lowercased()
        } else {
            fileExtension = "jpg"  // Default to JPG if no URL is available
        }
        
        saveImageToAssets(image: image, name: imageName, fileExtension: fileExtension)
        picker.dismiss(animated: true)
    }
}

class ImageCell: UICollectionViewCell {
    var imageView: UIImageView!
    var deleteButton: UIButton!
    var renameButton: UIButton!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        imageView.contentMode = .scaleAspectFit
        self.contentView.addSubview(imageView)
        
        deleteButton = UIButton(type: .system)
        deleteButton.setTitle("Delete", for: .normal)
        deleteButton.frame = CGRect(x: 0, y: 80, width: 100, height: 20)
        deleteButton.backgroundColor = .red
        deleteButton.setTitleColor(.white, for: .normal)
        self.contentView.addSubview(deleteButton)
        
        renameButton = UIButton(type: .system)
        renameButton.setTitle("Rename", for: .normal)
        renameButton.frame = CGRect(x: 0, y: 60, width: 100, height: 20)
        renameButton.backgroundColor = .blue
        renameButton.setTitleColor(.white, for: .normal)
        self.contentView.addSubview(renameButton)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
