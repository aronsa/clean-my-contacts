import XCTest
import Contacts
@testable import CleanMyContacts

final class ContactsManagerTests: XCTestCase {
    var contactsManager: ContactsManager!
    var mockContact1: CNContact!
    var mockContact2: CNContact!
    var mockContact3: CNContact!
    
    override func setUpWithError() throws {
        contactsManager = ContactsManager()
        
        // Create mock contacts for testing
        let mutableContact1 = CNMutableContact()
        mutableContact1.givenName = "John"
        mutableContact1.familyName = "Doe"
        mutableContact1.phoneNumbers = [CNLabeledValue(label: CNLabelPhoneNumberMain, value: CNPhoneNumber(stringValue: "555-0001"))]
        mockContact1 = mutableContact1.copy() as? CNContact
        
        let mutableContact2 = CNMutableContact()
        mutableContact2.givenName = "Jane"
        mutableContact2.familyName = "Smith"
        mutableContact2.phoneNumbers = [CNLabeledValue(label: CNLabelPhoneNumberMain, value: CNPhoneNumber(stringValue: "555-0002"))]
        mutableContact2.emailAddresses = [CNLabeledValue(label: CNLabelEmailiCloud, value: "jane@example.com" as NSString)]
        mockContact2 = mutableContact2.copy() as? CNContact
        
        let mutableContact3 = CNMutableContact()
        mutableContact3.givenName = "Bob"
        mutableContact3.familyName = "Johnson"
        mutableContact3.phoneNumbers = [CNLabeledValue(label: CNLabelPhoneNumberMain, value: CNPhoneNumber(stringValue: "555-0003"))]
        mockContact3 = mutableContact3.copy() as? CNContact
        
        // Set up test data without triggering actual Contacts API
        contactsManager.contacts = [mockContact1!, mockContact2!, mockContact3!]
        contactsManager.currentContactIndex = 0
    }
    
    override func tearDownWithError() throws {
        contactsManager = nil
        mockContact1 = nil
        mockContact2 = nil
        mockContact3 = nil
    }
    
    func testInitialState() {
        let newManager = ContactsManager()
        XCTAssertEqual(newManager.contacts.count, 0)
        XCTAssertEqual(newManager.trashContacts.count, 0)
        XCTAssertEqual(newManager.currentContactIndex, 0)
        XCTAssertFalse(newManager.hasPermission)
    }
    
    func testCurrentContact() {
        XCTAssertEqual(contactsManager.currentContact?.identifier, mockContact1.identifier)
        
        contactsManager.currentContactIndex = 1
        XCTAssertEqual(contactsManager.currentContact?.identifier, mockContact2.identifier)
        
        contactsManager.currentContactIndex = 2
        XCTAssertEqual(contactsManager.currentContact?.identifier, mockContact3.identifier)
        
        contactsManager.currentContactIndex = 3
        XCTAssertNil(contactsManager.currentContact)
    }
    
    func testHasMoreContacts() {
        XCTAssertTrue(contactsManager.hasMoreContacts)
        
        contactsManager.currentContactIndex = 2
        XCTAssertTrue(contactsManager.hasMoreContacts)
        
        contactsManager.currentContactIndex = 3
        XCTAssertFalse(contactsManager.hasMoreContacts)
    }
    
    func testKeepCurrentContact() {
        XCTAssertEqual(contactsManager.currentContactIndex, 0)
        
        contactsManager.keepCurrentContact()
        XCTAssertEqual(contactsManager.currentContactIndex, 1)
        
        contactsManager.keepCurrentContact()
        XCTAssertEqual(contactsManager.currentContactIndex, 2)
        
        contactsManager.keepCurrentContact()
        XCTAssertEqual(contactsManager.currentContactIndex, 3)
        
        // Should not increment beyond bounds
        contactsManager.keepCurrentContact()
        XCTAssertEqual(contactsManager.currentContactIndex, 3)
    }
    
    func testMoveCurrentContactToTrash() {
        let initialContactsCount = contactsManager.contacts.count
        let initialTrashCount = contactsManager.trashContacts.count
        let contactToTrash = contactsManager.currentContact!
        
        contactsManager.moveCurrentContactToTrash()
        
        XCTAssertEqual(contactsManager.contacts.count, initialContactsCount - 1)
        XCTAssertEqual(contactsManager.trashContacts.count, initialTrashCount + 1)
        XCTAssertEqual(contactsManager.trashContacts.last?.identifier, contactToTrash.identifier)
        XCTAssertEqual(contactsManager.currentContactIndex, 0) // Should stay at same index
    }
    
    func testMoveMultipleContactsToTrash() {
        // Move first contact to trash
        let firstContact = contactsManager.currentContact!
        contactsManager.moveCurrentContactToTrash()
        
        // Move second contact (now at index 0) to trash
        let secondContact = contactsManager.currentContact!
        contactsManager.moveCurrentContactToTrash()
        
        XCTAssertEqual(contactsManager.contacts.count, 1)
        XCTAssertEqual(contactsManager.trashContacts.count, 2)
        XCTAssertEqual(contactsManager.trashContacts[0].identifier, firstContact.identifier)
        XCTAssertEqual(contactsManager.trashContacts[1].identifier, secondContact.identifier)
    }
    
    func testMoveLastContactToTrash() {
        // Move to last contact
        contactsManager.currentContactIndex = 2
        let lastContact = contactsManager.currentContact!
        
        contactsManager.moveCurrentContactToTrash()
        
        XCTAssertEqual(contactsManager.contacts.count, 2)
        XCTAssertEqual(contactsManager.trashContacts.count, 1)
        XCTAssertEqual(contactsManager.trashContacts.first?.identifier, lastContact.identifier)
        XCTAssertEqual(contactsManager.currentContactIndex, 1) // Should adjust to valid index
    }
    
    func testRestoreContactFromTrash() {
        // First move a contact to trash
        let contactToTrash = contactsManager.currentContact!
        contactsManager.moveCurrentContactToTrash()
        
        let initialContactsCount = contactsManager.contacts.count
        let initialTrashCount = contactsManager.trashContacts.count
        
        // Then restore it
        contactsManager.restoreContactFromTrash(contactToTrash)
        
        XCTAssertEqual(contactsManager.contacts.count, initialContactsCount + 1)
        XCTAssertEqual(contactsManager.trashContacts.count, initialTrashCount - 1)
        XCTAssertTrue(contactsManager.contacts.contains { $0.identifier == contactToTrash.identifier })
        XCTAssertFalse(contactsManager.trashContacts.contains { $0.identifier == contactToTrash.identifier })
    }
    
    func testRestoreNonExistentContact() {
        let initialContactsCount = contactsManager.contacts.count
        let initialTrashCount = contactsManager.trashContacts.count
        
        // Try to restore a contact that's not in trash
        contactsManager.restoreContactFromTrash(mockContact1)
        
        XCTAssertEqual(contactsManager.contacts.count, initialContactsCount)
        XCTAssertEqual(contactsManager.trashContacts.count, initialTrashCount)
    }
    
    func testContactIndexAdjustmentWhenTrashingAll() {
        // Move all contacts to trash one by one
        contactsManager.moveCurrentContactToTrash() // Remove contact at index 0
        XCTAssertEqual(contactsManager.currentContactIndex, 0)
        XCTAssertEqual(contactsManager.contacts.count, 2)
        
        contactsManager.moveCurrentContactToTrash() // Remove contact at index 0 again
        XCTAssertEqual(contactsManager.currentContactIndex, 0)
        XCTAssertEqual(contactsManager.contacts.count, 1)
        
        contactsManager.moveCurrentContactToTrash() // Remove last contact
        XCTAssertEqual(contactsManager.currentContactIndex, 0)
        XCTAssertEqual(contactsManager.contacts.count, 0)
        XCTAssertFalse(contactsManager.hasMoreContacts)
    }
    
    func testCurrentContactAfterRestore() {
        // Move current contact to trash
        let originalCurrentContact = contactsManager.currentContact!
        contactsManager.moveCurrentContactToTrash()
        
        // Current contact should now be the next one
        let newCurrentContact = contactsManager.currentContact!
        XCTAssertNotEqual(originalCurrentContact.identifier, newCurrentContact.identifier)
        
        // Restore the original contact
        contactsManager.restoreContactFromTrash(originalCurrentContact)
        
        // Current contact should still be the same (restore doesn't change current index)
        XCTAssertEqual(contactsManager.currentContact?.identifier, newCurrentContact.identifier)
    }
    
    func testTrashOperationsWithEmptyContacts() {
        // Clear all contacts
        contactsManager.contacts = []
        contactsManager.currentContactIndex = 0
        
        XCTAssertNil(contactsManager.currentContact)
        XCTAssertFalse(contactsManager.hasMoreContacts)
        
        // These operations should not crash
        contactsManager.moveCurrentContactToTrash()
        contactsManager.keepCurrentContact()
        
        XCTAssertEqual(contactsManager.contacts.count, 0)
        XCTAssertEqual(contactsManager.trashContacts.count, 0)
    }
}