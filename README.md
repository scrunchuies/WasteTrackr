# WasteTrackr

**WasteTrackr** is an inventory management application designed to track items, monitor usage, and alert users when inventory counts reach a minimum threshold. Originally built for a Chick-fil-A internship project, the app is designed to be adaptable for any business that needs to manage stock or inventory effectively.

## Features

- **Real-Time Inventory Tracking:** Monitor the count of items in stock, adjust quantities, and view usage history.
- **Firebase Integration:** Stores data securely in Firebase Firestore, including images and item details.
- **Custom Alerts:** Sends notifications when an item's stock falls below the minimum threshold.
- **Changelog Management:** Tracks changes to inventory names and counts with timestamps and user details.
- **Data Export:** Export daily usage reports as PDFs for easy sharing and record-keeping.
- **User Management:** Individual accounts with unique store codes, allowing for easy collaboration across teams.
- **UI Customization:** Editable collection view cells where users can update item names, counts, and associated images.

## Getting Started

### Prerequisites

Before running the app, ensure that you have the following installed:

- Xcode 12 or later
- Swift 5.0+
- Firebase SDKs (Firestore, Firebase Cloud Messaging)
- Cocoapods (for dependency management)

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/your-username/wastetrackr.git
   cd wastetrackr
   ```

2. Install dependencies:
   ```bash
   pod install
   ```

3. Open the Xcode workspace:
   ```bash
   open WasteTrackr.xcworkspace
   ```

4. Configure Firebase:
   - Add your `GoogleService-Info.plist` file to the project for Firebase integration.
   - Ensure that Firestore and Firebase Cloud Messaging are enabled in your Firebase console.

### Running the App

1. Build and run the app in Xcode by selecting the appropriate simulator or connected device.
2. Sign in with your user account, or create a new account by reaching out to the admin.
3. Start tracking your inventory items and adjust their counts as needed.

## App Structure

### Main Components

- **Tab1ViewController:** Displays a UICollectionView with editable cells for items. Users can update, delete, or add new items with custom images and colors.
- **Firestore Integration:** All item data, including names, counts, and images, are stored in Firebase Firestore under a collection named `00000-STORAGE`.
- **Changelog System:** Tracks changes to inventory, including updates to names and counts, with a detailed history saved for each item.

### Key Classes

- `Item`: A class that represents each inventory item. It includes properties such as `id`, `name`, `count`, `color`, `timestamp`, `imageName`, and `changeLog`.
- `EditableCollectionViewCell`: A custom cell for displaying and editing item details in the collection view.

## Cloud Functions

- **dataReset Function:** A Firebase Cloud Function that resets item counts at the end of the day or week.
- **Notification System:** Push notifications are sent using Firebase Cloud Messaging when item counts reach the specified minimum threshold.

## Contribution

If you'd like to contribute to WasteTrackr, feel free to submit a pull request! Here are some ways you can help:

- Improve UI/UX design.
- Add additional features like barcode scanning for inventory items.
- Optimize Firebase data fetching and saving methods.
- Create additional tests for more thorough app testing.

## License

This project is proprietary and not licensed for use, modification, or distribution. All rights are reserved by the author.
