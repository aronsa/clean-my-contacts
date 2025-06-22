# CleanMyContacts

A SwiftUI iOS app that provides a "Tinder-like" interface for quickly organizing and cleaning up your contact list. Perfect for when your contacts get mixed up or you need to remove outdated entries (as I did after my contacts got merged with my family's).

I built this using Claude Code. I am not an iOS developer. 

## Features

### Core Functionality
- **Swipe Interface**: Swipe right to keep contacts, swipe left to trash them
- **Visual Feedback**: Cards turn green when swiping right (keep) and red when swiping left (trash)
- **Smooth Animations**: Fluid card animations and color transitions during swipes
- **Trash System**: Move contacts to trash instead of immediate deletion
- **Restore Capability**: Recover accidentally trashed contacts

### Contact Management
- **Batch Operations**: Empty entire trash at once or restore individual contacts
- **Safe Operations**: No permanent deletion without explicit confirmation
- **Contact Permissions**: Proper iOS Contacts framework integration
- **Real Contact Data**: Works with your actual iOS contacts

## Technical Implementation

### Architecture
- **SwiftUI**: Modern declarative UI framework
- **MVVM Pattern**: ContactsManager as ObservableObject
- **Contacts Framework**: Native iOS contact access
- **State Management**: @Published properties for reactive UI updates

### Prerequisites
- iOS 17.0+
- Xcode 15.0+
- Contacts permission (requested automatically)

### Project Generation
This project uses XcodeGen for project file management:
```bash
xcodegen generate
```

## Development

### Running Tests
```bash
xcodebuild test -project CleanMyContacts.xcodeproj -scheme CleanMyContacts -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.2'
```

