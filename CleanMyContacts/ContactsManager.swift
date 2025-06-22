import Foundation
import Contacts

class ContactsManager: ObservableObject {
    @Published var contacts: [CNContact] = []
    @Published var trashContacts: [CNContact] = []
    @Published var currentContactIndex = 0
    @Published var hasPermission = false
    
    private let contactStore = CNContactStore()
    
    init() {
        requestAccess()
    }
    
    func requestAccess() {
        contactStore.requestAccess(for: .contacts) { granted, error in
            DispatchQueue.main.async {
                self.hasPermission = granted
                if granted {
                    self.fetchContacts()
                }
            }
        }
    }
    
    private func fetchContacts() {
        let keys = [CNContactGivenNameKey, CNContactFamilyNameKey, CNContactPhoneNumbersKey, CNContactEmailAddressesKey] as [CNKeyDescriptor]
        let request = CNContactFetchRequest(keysToFetch: keys)
        
        do {
            try contactStore.enumerateContacts(with: request) { contact, _ in
                DispatchQueue.main.async {
                    self.contacts.append(contact)
                }
            }
        } catch {
            print("Failed to fetch contacts: \(error)")
        }
    }
    
    func moveCurrentContactToTrash() {
        guard currentContactIndex < contacts.count else { return }
        
        let contactToTrash = contacts[currentContactIndex]
        trashContacts.append(contactToTrash)
        contacts.remove(at: currentContactIndex)
        
        if currentContactIndex >= contacts.count && contacts.count > 0 {
            currentContactIndex = contacts.count - 1
        }
    }
    
    func restoreContactFromTrash(_ contact: CNContact) {
        guard let index = trashContacts.firstIndex(where: { $0.identifier == contact.identifier }) else { return }
        
        trashContacts.remove(at: index)
        contacts.append(contact)
    }
    
    func permanentlyDeleteContact(_ contact: CNContact) {
        let mutableContact = contact.mutableCopy() as! CNMutableContact
        let request = CNSaveRequest()
        request.delete(mutableContact)
        
        do {
            try contactStore.execute(request)
            if let index = trashContacts.firstIndex(where: { $0.identifier == contact.identifier }) {
                trashContacts.remove(at: index)
            }
        } catch {
            print("Failed to permanently delete contact: \(error)")
        }
    }
    
    func emptyTrash() {
        for contact in trashContacts {
            let mutableContact = contact.mutableCopy() as! CNMutableContact
            let request = CNSaveRequest()
            request.delete(mutableContact)
            
            do {
                try contactStore.execute(request)
            } catch {
                print("Failed to delete contact \(contact.givenName) \(contact.familyName): \(error)")
            }
        }
        trashContacts.removeAll()
    }
    
    func keepCurrentContact() {
        guard currentContactIndex < contacts.count else { return }
        currentContactIndex += 1
    }
    
    var currentContact: CNContact? {
        guard currentContactIndex < contacts.count else { return nil }
        return contacts[currentContactIndex]
    }
    
    var hasMoreContacts: Bool {
        return currentContactIndex < contacts.count
    }
}