import XCTest
import Contacts
@testable import CleanMyContacts

final class EdgeCaseTests: XCTestCase {
    var contactsManager: ContactsManager!
    
    override func setUpWithError() throws {
        contactsManager = ContactsManager()
    }
    
    override func tearDownWithError() throws {
        contactsManager = nil
    }
    
    func testEmptyContactsInitialization() {
        XCTAssertEqual(contactsManager.contacts.count, 0)
        XCTAssertEqual(contactsManager.trashContacts.count, 0)
        XCTAssertEqual(contactsManager.currentContactIndex, 0)
        XCTAssertNil(contactsManager.currentContact)
        XCTAssertFalse(contactsManager.hasMoreContacts)
    }
    
    func testOperationsOnEmptyContactsList() {
        // All operations should be safe when contacts list is empty
        contactsManager.moveCurrentContactToTrash()
        XCTAssertEqual(contactsManager.contacts.count, 0)
        XCTAssertEqual(contactsManager.trashContacts.count, 0)
        
        contactsManager.keepCurrentContact()
        XCTAssertEqual(contactsManager.currentContactIndex, 0)
        
        XCTAssertNil(contactsManager.currentContact)
        XCTAssertFalse(contactsManager.hasMoreContacts)
    }
    
    func testContactWithMissingData() {
        // Create a contact with minimal data
        let mutableContact = CNMutableContact()
        mutableContact.givenName = "" // Empty name
        mutableContact.familyName = ""
        // No phone numbers or emails
        
        let emptyContact = mutableContact.copy() as! CNContact
        contactsManager.contacts = [emptyContact]
        
        XCTAssertNotNil(contactsManager.currentContact)
        XCTAssertEqual(contactsManager.currentContact?.givenName, "")
        XCTAssertEqual(contactsManager.currentContact?.familyName, "")
        XCTAssertTrue(contactsManager.currentContact?.phoneNumbers.isEmpty ?? false)
        XCTAssertTrue(contactsManager.currentContact?.emailAddresses.isEmpty ?? false)
        
        // Operations should still work
        contactsManager.moveCurrentContactToTrash()
        XCTAssertEqual(contactsManager.trashContacts.count, 1)
        XCTAssertEqual(contactsManager.contacts.count, 0)
    }
    
    func testContactWithSpecialCharacters() {
        let mutableContact = CNMutableContact()
        mutableContact.givenName = "José María"
        mutableContact.familyName = "García-López"
        mutableContact.phoneNumbers = [CNLabeledValue(label: CNLabelPhoneNumberMain, value: CNPhoneNumber(stringValue: "+1 (555) 123-4567"))]
        mutableContact.emailAddresses = [CNLabeledValue(label: CNLabelEmailiCloud, value: "josé.maría@example.com" as NSString)]
        
        let specialContact = mutableContact.copy() as! CNContact
        contactsManager.contacts = [specialContact]
        
        XCTAssertEqual(contactsManager.currentContact?.givenName, "José María")
        XCTAssertEqual(contactsManager.currentContact?.familyName, "García-López")
        
        // Operations should work normally
        contactsManager.moveCurrentContactToTrash()
        XCTAssertEqual(contactsManager.trashContacts.count, 1)
        XCTAssertEqual(contactsManager.trashContacts[0].givenName, "José María")
        
        contactsManager.restoreContactFromTrash(specialContact)
        XCTAssertEqual(contactsManager.contacts.count, 1)
        XCTAssertEqual(contactsManager.contacts[0].givenName, "José María")
    }
    
    func testLargeContactsList() {
        // Create a large number of contacts to test performance
        var largeContactsList: [CNContact] = []
        
        for i in 1...1000 {
            let mutableContact = CNMutableContact()
            mutableContact.givenName = "Person"
            mutableContact.familyName = "Number\(i)"
            mutableContact.phoneNumbers = [CNLabeledValue(label: CNLabelPhoneNumberMain, value: CNPhoneNumber(stringValue: "555-\(String(format: "%04d", i))"))]
            largeContactsList.append(mutableContact.copy() as! CNContact)
        }
        
        contactsManager.contacts = largeContactsList
        
        XCTAssertEqual(contactsManager.contacts.count, 1000)
        XCTAssertTrue(contactsManager.hasMoreContacts)
        XCTAssertEqual(contactsManager.currentContact?.familyName, "Number1")
        
        // Test navigation through large list
        for _ in 1...100 {
            contactsManager.keepCurrentContact()
        }
        XCTAssertEqual(contactsManager.currentContactIndex, 100)
        XCTAssertEqual(contactsManager.currentContact?.familyName, "Number101")
        
        // Test trashing from middle of large list
        contactsManager.moveCurrentContactToTrash()
        XCTAssertEqual(contactsManager.contacts.count, 999)
        XCTAssertEqual(contactsManager.trashContacts.count, 1)
        XCTAssertEqual(contactsManager.currentContact?.familyName, "Number102") // Next contact moved up
    }
    
    func testBoundaryConditions() {
        // Create contacts for boundary testing
        let contact1 = createMockContact(givenName: "First", familyName: "Contact")
        let contact2 = createMockContact(givenName: "Second", familyName: "Contact")
        let contact3 = createMockContact(givenName: "Third", familyName: "Contact")
        
        contactsManager.contacts = [contact1, contact2, contact3]
        
        // Test at first index
        XCTAssertEqual(contactsManager.currentContactIndex, 0)
        contactsManager.moveCurrentContactToTrash()
        XCTAssertEqual(contactsManager.currentContactIndex, 0) // Should stay at 0
        XCTAssertEqual(contactsManager.contacts.count, 2)
        
        // Move to last index
        contactsManager.keepCurrentContact() // Index 1
        XCTAssertEqual(contactsManager.currentContactIndex, 1)
        XCTAssertEqual(contactsManager.currentContact?.givenName, "Third")
        
        // Trash last contact
        contactsManager.moveCurrentContactToTrash()
        XCTAssertEqual(contactsManager.currentContactIndex, 0) // Should adjust to 0 (last valid index)
        XCTAssertEqual(contactsManager.contacts.count, 1)
        
        // Trash the final contact
        contactsManager.moveCurrentContactToTrash()
        XCTAssertEqual(contactsManager.currentContactIndex, 0)
        XCTAssertEqual(contactsManager.contacts.count, 0)
        XCTAssertFalse(contactsManager.hasMoreContacts)
    }
    
    func testRestoreNonExistentContact() {
        let contact1 = createMockContact(givenName: "Existing", familyName: "Contact")
        let contact2 = createMockContact(givenName: "Non-existent", familyName: "Contact")
        
        contactsManager.contacts = [contact1]
        contactsManager.moveCurrentContactToTrash()
        
        XCTAssertEqual(contactsManager.trashContacts.count, 1)
        
        // Try to restore a contact that was never in trash
        contactsManager.restoreContactFromTrash(contact2)
        
        // Should not change anything
        XCTAssertEqual(contactsManager.trashContacts.count, 1)
        XCTAssertEqual(contactsManager.contacts.count, 0)
    }
    
    func testDuplicateRestore() {
        let contact = createMockContact(givenName: "Test", familyName: "Contact")
        contactsManager.contacts = [contact]
        
        // Move to trash
        contactsManager.moveCurrentContactToTrash()
        XCTAssertEqual(contactsManager.trashContacts.count, 1)
        
        // Restore once
        contactsManager.restoreContactFromTrash(contact)
        XCTAssertEqual(contactsManager.contacts.count, 1)
        XCTAssertEqual(contactsManager.trashContacts.count, 0)
        
        // Try to restore again (should be safe)
        contactsManager.restoreContactFromTrash(contact)
        XCTAssertEqual(contactsManager.contacts.count, 1)
        XCTAssertEqual(contactsManager.trashContacts.count, 0)
    }
    
    func testContactWithLongData() {
        let longName = String(repeating: "A", count: 1000)
        let longEmail = String(repeating: "b", count: 100) + "@" + String(repeating: "c", count: 100) + ".com"
        
        let mutableContact = CNMutableContact()
        mutableContact.givenName = longName
        mutableContact.familyName = longName
        mutableContact.emailAddresses = [CNLabeledValue(label: CNLabelEmailiCloud, value: longEmail as NSString)]
        
        let longContact = mutableContact.copy() as! CNContact
        contactsManager.contacts = [longContact]
        
        XCTAssertEqual(contactsManager.currentContact?.givenName.count, 1000)
        XCTAssertEqual(contactsManager.currentContact?.familyName.count, 1000)
        
        // Operations should still work
        contactsManager.moveCurrentContactToTrash()
        XCTAssertEqual(contactsManager.trashContacts.count, 1)
        XCTAssertEqual(contactsManager.trashContacts[0].givenName.count, 1000)
    }
    
    // Helper function to create mock contacts
    private func createMockContact(givenName: String, familyName: String) -> CNContact {
        let mutableContact = CNMutableContact()
        mutableContact.givenName = givenName
        mutableContact.familyName = familyName
        mutableContact.phoneNumbers = [CNLabeledValue(label: CNLabelPhoneNumberMain, value: CNPhoneNumber(stringValue: "555-0000"))]
        return mutableContact.copy() as! CNContact
    }
}