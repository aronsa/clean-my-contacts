import XCTest
import Contacts
@testable import CleanMyContacts

final class TrashFunctionalityTests: XCTestCase {
    var contactsManager: ContactsManager!
    var mockContacts: [CNContact]!
    
    override func setUpWithError() throws {
        contactsManager = ContactsManager()
        
        // Create multiple mock contacts
        mockContacts = []
        for i in 1...5 {
            let mutableContact = CNMutableContact()
            mutableContact.givenName = "Person"
            mutableContact.familyName = "Number\(i)"
            mutableContact.phoneNumbers = [CNLabeledValue(label: CNLabelPhoneNumberMain, value: CNPhoneNumber(stringValue: "555-000\(i)"))]
            mockContacts.append(mutableContact.copy() as! CNContact)
        }
        
        contactsManager.contacts = mockContacts
        contactsManager.currentContactIndex = 0
    }
    
    override func tearDownWithError() throws {
        contactsManager = nil
        mockContacts = nil
    }
    
    func testBulkTrashOperations() {
        // Move multiple contacts to trash
        contactsManager.moveCurrentContactToTrash() // Person Number1
        contactsManager.moveCurrentContactToTrash() // Person Number2 (now at index 0)
        contactsManager.moveCurrentContactToTrash() // Person Number3 (now at index 0)
        
        XCTAssertEqual(contactsManager.contacts.count, 2)
        XCTAssertEqual(contactsManager.trashContacts.count, 3)
        
        // Verify the order in trash
        XCTAssertEqual(contactsManager.trashContacts[0].familyName, "Number1")
        XCTAssertEqual(contactsManager.trashContacts[1].familyName, "Number2") 
        XCTAssertEqual(contactsManager.trashContacts[2].familyName, "Number3")
    }
    
    func testRestoreMultipleContacts() {
        // Move contacts to trash first
        let contact1 = mockContacts[0]
        let contact2 = mockContacts[1]
        let contact3 = mockContacts[2]
        
        contactsManager.moveCurrentContactToTrash()
        contactsManager.moveCurrentContactToTrash()
        contactsManager.moveCurrentContactToTrash()
        
        XCTAssertEqual(contactsManager.trashContacts.count, 3)
        XCTAssertEqual(contactsManager.contacts.count, 2)
        
        // Restore them in different order
        contactsManager.restoreContactFromTrash(contact2)
        contactsManager.restoreContactFromTrash(contact1)
        
        XCTAssertEqual(contactsManager.trashContacts.count, 1)
        XCTAssertEqual(contactsManager.contacts.count, 4)
        XCTAssertEqual(contactsManager.trashContacts[0].identifier, contact3.identifier)
    }
    
    func testTrashStateAfterMultipleOperations() {
        let initialContact = contactsManager.currentContact!
        
        // Complex sequence: trash, restore, trash again, restore again
        contactsManager.moveCurrentContactToTrash()
        XCTAssertEqual(contactsManager.trashContacts.count, 1)
        XCTAssertEqual(contactsManager.contacts.count, 4)
        
        contactsManager.restoreContactFromTrash(initialContact)
        XCTAssertEqual(contactsManager.trashContacts.count, 0)
        XCTAssertEqual(contactsManager.contacts.count, 5)
        
        // Find the contact again (it's now at the end)
        let restoredContact = contactsManager.contacts.last!
        XCTAssertEqual(restoredContact.identifier, initialContact.identifier)
        
        contactsManager.restoreContactFromTrash(restoredContact) // Should do nothing
        XCTAssertEqual(contactsManager.trashContacts.count, 0)
        XCTAssertEqual(contactsManager.contacts.count, 5)
    }
    
    func testCurrentIndexAfterComplexTrashOperations() {
        // Start at index 0, move to index 2
        contactsManager.keepCurrentContact() // index 1
        contactsManager.keepCurrentContact() // index 2
        XCTAssertEqual(contactsManager.currentContactIndex, 2)
        
        // Trash current contact (index 2)
        let contactAtIndex2 = contactsManager.currentContact!
        contactsManager.moveCurrentContactToTrash()
        
        // Index should adjust since we removed the contact at index 2
        XCTAssertEqual(contactsManager.currentContactIndex, 2)
        XCTAssertEqual(contactsManager.contacts.count, 4)
        
        // Current contact should be what was previously at index 3
        XCTAssertEqual(contactsManager.currentContact?.familyName, "Number4")
        
        // Move to last contact and trash it
        contactsManager.keepCurrentContact() // Should be at index 3 (last)
        XCTAssertEqual(contactsManager.currentContactIndex, 3)
        
        contactsManager.moveCurrentContactToTrash()
        
        // Index should adjust to 2 (last valid index)
        XCTAssertEqual(contactsManager.currentContactIndex, 2)
        XCTAssertEqual(contactsManager.contacts.count, 3)
    }
    
    func testTrashWithSingleContact() {
        // Set up with just one contact
        contactsManager.contacts = [mockContacts[0]]
        contactsManager.currentContactIndex = 0
        
        XCTAssertTrue(contactsManager.hasMoreContacts)
        XCTAssertNotNil(contactsManager.currentContact)
        
        contactsManager.moveCurrentContactToTrash()
        
        XCTAssertEqual(contactsManager.contacts.count, 0)
        XCTAssertEqual(contactsManager.trashContacts.count, 1)
        XCTAssertEqual(contactsManager.currentContactIndex, 0)
        XCTAssertFalse(contactsManager.hasMoreContacts)
        XCTAssertNil(contactsManager.currentContact)
    }
    
    func testRestoreToEmptyContacts() {
        // Move all contacts to trash
        while !contactsManager.contacts.isEmpty {
            contactsManager.moveCurrentContactToTrash()
        }
        
        XCTAssertEqual(contactsManager.contacts.count, 0)
        XCTAssertEqual(contactsManager.trashContacts.count, 5)
        XCTAssertFalse(contactsManager.hasMoreContacts)
        
        // Restore one contact
        let contactToRestore = contactsManager.trashContacts[0]
        contactsManager.restoreContactFromTrash(contactToRestore)
        
        XCTAssertEqual(contactsManager.contacts.count, 1)
        XCTAssertEqual(contactsManager.trashContacts.count, 4)
        XCTAssertTrue(contactsManager.hasMoreContacts)
        XCTAssertNotNil(contactsManager.currentContact)
        XCTAssertEqual(contactsManager.currentContact?.identifier, contactToRestore.identifier)
    }
    
    func testTrashPreservesContactOrder() {
        // Note original order
        let originalOrder = contactsManager.contacts.map { $0.familyName }
        
        // Trash the middle contact (index 2)
        contactsManager.currentContactIndex = 2
        let middleContact = contactsManager.currentContact!
        contactsManager.moveCurrentContactToTrash()
        
        // Check that remaining contacts maintain their relative order
        let remainingOrder = contactsManager.contacts.map { $0.familyName }
        let expectedOrder = ["Number1", "Number2", "Number4", "Number5"]
        XCTAssertEqual(remainingOrder, expectedOrder)
        
        // Restore the contact
        contactsManager.restoreContactFromTrash(middleContact)
        
        // Contact should be added to end
        let finalOrder = contactsManager.contacts.map { $0.familyName }
        let expectedFinalOrder = ["Number1", "Number2", "Number4", "Number5", "Number3"]
        XCTAssertEqual(finalOrder, expectedFinalOrder)
    }
}