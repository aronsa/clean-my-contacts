import SwiftUI

struct ContentView: View {
    @StateObject private var contactsManager = ContactsManager()
    @State private var showingTrash = false
    
    var body: some View {
        NavigationView {
            VStack {
                if !contactsManager.hasPermission {
                    VStack(spacing: 20) {
                        Image(systemName: "person.crop.circle.badge.questionmark")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        
                        Text("Contacts Access Required")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("This app needs access to your contacts to help you organize them.")
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                        
                        Button("Grant Access") {
                            contactsManager.requestAccess()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                } else if contactsManager.contacts.isEmpty {
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Loading contacts...")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                } else if !contactsManager.hasMoreContacts {
                    VStack(spacing: 20) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.green)
                        
                        Text("All Done!")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("You've reviewed all your contacts.")
                            .foregroundColor(.secondary)
                    }
                    .padding()
                } else if let currentContact = contactsManager.currentContact {
                    VStack {
                        HStack {
                            Text("Contact \(contactsManager.currentContactIndex + 1) of \(contactsManager.contacts.count)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        .padding(.horizontal)
                        
                        ContactCardView(
                            contact: currentContact,
                            onSwipeLeft: {
                                contactsManager.moveCurrentContactToTrash()
                            },
                            onSwipeRight: {
                                contactsManager.keepCurrentContact()
                            },
                            contactsManager: contactsManager
                        )
                        .padding()
                        
                        VStack(spacing: 4) {
                            Text("← Swipe left to move to trash • Swipe right to keep →")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("Double-tap to edit contact")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Clean My Contacts")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingTrash = true
                    }) {
                        HStack {
                            Image(systemName: "trash")
                            if !contactsManager.trashContacts.isEmpty {
                                Text("\(contactsManager.trashContacts.count)")
                                    .font(.caption)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.red)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingTrash) {
            TrashView(contactsManager: contactsManager)
        }
    }
}