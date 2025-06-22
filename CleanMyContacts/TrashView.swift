import SwiftUI
import Contacts

struct TrashView: View {
    @ObservedObject var contactsManager: ContactsManager
    @Environment(\.dismiss) private var dismiss
    @State private var showingEmptyTrashAlert = false
    
    var body: some View {
        NavigationView {
            VStack {
                if contactsManager.trashContacts.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "trash")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        
                        Text("Trash is Empty")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Contacts you remove will appear here before being permanently deleted.")
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                } else {
                    List {
                        ForEach(contactsManager.trashContacts, id: \.identifier) { contact in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("\(contact.givenName) \(contact.familyName)")
                                        .font(.headline)
                                    
                                    if !contact.phoneNumbers.isEmpty {
                                        Text(contact.phoneNumbers.first?.value.stringValue ?? "")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                Spacer()
                                
                                HStack(spacing: 8) {
                                    Button(action: {
                                        contactsManager.restoreContactFromTrash(contact)
                                    }) {
                                        Image(systemName: "arrow.uturn.backward")
                                            .foregroundColor(.blue)
                                    }
                                    .buttonStyle(BorderlessButtonStyle())
                                    
                                    Button(action: {
                                        contactsManager.permanentlyDeleteContact(contact)
                                    }) {
                                        Image(systemName: "trash")
                                            .foregroundColor(.red)
                                    }
                                    .buttonStyle(BorderlessButtonStyle())
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .navigationTitle("Trash (\(contactsManager.trashContacts.count))")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                if !contactsManager.trashContacts.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Empty Trash") {
                            showingEmptyTrashAlert = true
                        }
                        .foregroundColor(.red)
                    }
                }
            }
        }
        .alert("Empty Trash", isPresented: $showingEmptyTrashAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete All", role: .destructive) {
                contactsManager.emptyTrash()
            }
        } message: {
            Text("Are you sure you want to permanently delete all \(contactsManager.trashContacts.count) contacts in trash? This action cannot be undone.")
        }
    }
}