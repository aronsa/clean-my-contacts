import XCTest
import Contacts
@testable import CleanMyContacts

final class ContactWorkflowTests: XCTestCase {
    var contactsManager: ContactsManager!
    var sampleContacts: [CNContact]!
    
    override func setUpWithError() throws {
        contactsManager = ContactsManager()
        
        // Create a realistic set of sample contacts
        sampleContacts = []
        
        let contactData = [
            ("Alice", "Johnson", "555-0101", "alice@email.com"),
            ("Bob", "Smith", "555-0102", nil),
            ("Charlie", "Brown", "555-0103", "charlie@email.com"),
            ("Diana", "Prince", "555-0104", "diana@email.com"),
            ("Edward", "Cullen", "555-0105", nil),
            ("Fiona", "Apple", "555-0106", "fiona@email.com")
        ]
        
        for (givenName, familyName, phone, email) in contactData {
            let mutableContact = CNMutableContact()
            mutableContact.givenName = givenName
            mutableContact.familyName = familyName
            mutableContact.phoneNumbers = [CNLabeledValue(label: CNLabelPhoneNumberMain, value: CNPhoneNumber(stringValue: phone))]
            
            if let email = email {
                mutableContact.emailAddresses = [CNLabeledValue(label: CNLabelEmailiCloud, value: email as NSString)]
            }
            
            sampleContacts.append(mutableContact.copy() as! CNContact)
        }
        
        contactsManager.contacts = sampleContacts
        contactsManager.currentContactIndex = 0
    }
    
    override func tearDownWithError() throws {
        contactsManager = nil
        sampleContacts = nil
    }
    
    func testCompleteCleaningWorkflow() {
        // Simulate user going through all contacts making decisions
        XCTAssertEqual(contactsManager.contacts.count, 6)
        XCTAssertEqual(contactsManager.currentContactIndex, 0)
        
        // Keep Alice (index 0)
        XCTAssertEqual(contactsManager.currentContact?.givenName, "Alice")
        contactsManager.keepCurrentContact()
        XCTAssertEqual(contactsManager.currentContactIndex, 1)
        
        // Trash Bob (index 1)
        XCTAssertEqual(contactsManager.currentContact?.givenName, "Bob")
        contactsManager.moveCurrentContactToTrash()
        XCTAssertEqual(contactsManager.contacts.count, 5)
        XCTAssertEqual(contactsManager.trashContacts.count, 1)
        XCTAssertEqual(contactsManager.currentContactIndex, 1) // Still at index 1, but now Charlie
        
        // Keep Charlie (now at index 1)
        XCTAssertEqual(contactsManager.currentContact?.givenName, "Charlie")
        contactsManager.keepCurrentContact()
        XCTAssertEqual(contactsManager.currentContactIndex, 2)
        
        // Keep Diana (index 2)
        XCTAssertEqual(contactsManager.currentContact?.givenName, "Diana")
        contactsManager.keepCurrentContact()
        XCTAssertEqual(contactsManager.currentContactIndex, 3)
        
        // Trash Edward (index 3)
        XCTAssertEqual(contactsManager.currentContact?.givenName, "Edward")
        contactsManager.moveCurrentContactToTrash()
        XCTAssertEqual(contactsManager.contacts.count, 4)
        XCTAssertEqual(contactsManager.trashContacts.count, 2)
        XCTAssertEqual(contactsManager.currentContactIndex, 3) // Now Fiona
        
        // Keep Fiona (last contact)
        XCTAssertEqual(contactsManager.currentContact?.givenName, "Fiona")
        contactsManager.keepCurrentContact()
        XCTAssertEqual(contactsManager.currentContactIndex, 4)
        XCTAssertFalse(contactsManager.hasMoreContacts)
        
        // Final state verification
        XCTAssertEqual(contactsManager.contacts.count, 4)
        XCTAssertEqual(contactsManager.trashContacts.count, 2)
        
        let remainingNames = contactsManager.contacts.map { $0.givenName }
        XCTAssertEqual(remainingNames, ["Alice", "Charlie", "Diana", "Fiona"])
        
        let trashedNames = contactsManager.trashContacts.map { $0.givenName }
        XCTAssertEqual(trashedNames, ["Bob", "Edward"])
    }
    
    func testUndoWorkflow() {
        // User accidentally trashes a contact and wants to restore it
        let contactToAccidentallyTrash = contactsManager.currentContact!
        XCTAssertEqual(contactToAccidentallyTrash.givenName, "Alice")
        
        contactsManager.moveCurrentContactToTrash()
        XCTAssertEqual(contactsManager.trashContacts.count, 1)
        XCTAssertEqual(contactsManager.contacts.count, 5)
        
        // User realizes mistake and restores from trash
        contactsManager.restoreContactFromTrash(contactToAccidentallyTrash)
        XCTAssertEqual(contactsManager.trashContacts.count, 0)
        XCTAssertEqual(contactsManager.contacts.count, 6)
        
        // Alice should be back in the contacts list (at the end)
        let restoredContact = contactsManager.contacts.last!
        XCTAssertEqual(restoredContact.identifier, contactToAccidentallyTrash.identifier)
    }
    
    func testSelectiveTrashManagement() {
        // Move several contacts to trash
        contactsManager.moveCurrentContactToTrash() // Alice
        contactsManager.moveCurrentContactToTrash() // Bob
        contactsManager.moveCurrentContactToTrash() // Charlie
        
        XCTAssertEqual(contactsManager.trashContacts.count, 3)
        XCTAssertEqual(contactsManager.contacts.count, 3)
        
        // User decides to restore only specific contacts
        let aliceInTrash = contactsManager.trashContacts[0] // Alice was first
        let charlieInTrash = contactsManager.trashContacts[2] // Charlie was third
        
        // Restore Alice and Charlie, leave Bob in trash
        contactsManager.restoreContactFromTrash(aliceInTrash)
        contactsManager.restoreContactFromTrash(charlieInTrash)
        
        XCTAssertEqual(contactsManager.trashContacts.count, 1)
        XCTAssertEqual(contactsManager.contacts.count, 5)
        XCTAssertEqual(contactsManager.trashContacts[0].givenName, "Bob")
    }
    
    func testEdgeCaseEmptyList() {
        // Simulate user trashing all contacts
        while contactsManager.hasMoreContacts {
            contactsManager.moveCurrentContactToTrash()
        }
        
        XCTAssertEqual(contactsManager.contacts.count, 0)
        XCTAssertEqual(contactsManager.trashContacts.count, 6)
        XCTAssertFalse(contactsManager.hasMoreContacts)
        XCTAssertNil(contactsManager.currentContact)
        
        // Operations on empty list should be safe
        contactsManager.moveCurrentContactToTrash() // Should not crash
        contactsManager.keepCurrentContact() // Should not crash
        
        XCTAssertEqual(contactsManager.contacts.count, 0)
        XCTAssertEqual(contactsManager.trashContacts.count, 6)
    }
    
    func testRecoveryFromEmptyState() {
        // Start with empty contacts
        contactsManager.contacts = []
        contactsManager.currentContactIndex = 0
        
        // Add some contacts to trash (simulating previous session)
        contactsManager.trashContacts = Array(sampleContacts.prefix(3))
        
        XCTAssertEqual(contactsManager.contacts.count, 0)
        XCTAssertEqual(contactsManager.trashContacts.count, 3)
        XCTAssertFalse(contactsManager.hasMoreContacts)
        
        // Restore contacts one by one
        contactsManager.restoreContactFromTrash(contactsManager.trashContacts[0])
        XCTAssertEqual(contactsManager.contacts.count, 1)
        XCTAssertTrue(contactsManager.hasMoreContacts)
        XCTAssertNotNil(contactsManager.currentContact)
        
        contactsManager.restoreContactFromTrash(contactsManager.trashContacts[0]) // Index 0 again since array shifted
        XCTAssertEqual(contactsManager.contacts.count, 2)
        
        contactsManager.restoreContactFromTrash(contactsManager.trashContacts[0]) // Last one
        XCTAssertEqual(contactsManager.contacts.count, 3)
        XCTAssertEqual(contactsManager.trashContacts.count, 0)
    }
    
    func testIndexConsistencyThroughoutWorkflow() {
        // Test that currentContactIndex remains consistent through various operations
        var operationLog: [(String, Int, Int)] = [] // (operation, index, contactsCount)
        
        operationLog.append(("start", contactsManager.currentContactIndex, contactsManager.contacts.count))
        
        // Keep first contact
        contactsManager.keepCurrentContact()
        operationLog.append(("keep", contactsManager.currentContactIndex, contactsManager.contacts.count))
        
        // Trash second contact
        contactsManager.moveCurrentContactToTrash()
        operationLog.append(("trash", contactsManager.currentContactIndex, contactsManager.contacts.count))
        
        // Keep current contact (which shifted up)
        contactsManager.keepCurrentContact()
        operationLog.append(("keep", contactsManager.currentContactIndex, contactsManager.contacts.count))
        
        // Verify all operations maintained valid state
        for (operation, index, count) in operationLog {
            XCTAssertTrue(index >= 0, "Index should never be negative after \(operation)")
            if count > 0 {
                XCTAssertTrue(index <= count, "Index should not exceed contacts count after \(operation)")
            }
        }
        
        // Verify we can still access current contact if there are contacts
        if contactsManager.hasMoreContacts {
            XCTAssertNotNil(contactsManager.currentContact)
        } else {
            XCTAssertNil(contactsManager.currentContact)
        }
    }
    
    func testCompleteAppLifecycle() {
        // Simulate a complete app usage session
        
        // Phase 1: Initial review
        contactsManager.keepCurrentContact() // Keep Alice
        contactsManager.moveCurrentContactToTrash() // Trash Bob
        contactsManager.keepCurrentContact() // Keep Charlie
        
        let midSessionState = (
            contacts: contactsManager.contacts.count,
            trash: contactsManager.trashContacts.count,
            index: contactsManager.currentContactIndex
        )
        
        // Phase 2: User goes to trash and makes adjustments
        let bobInTrash = contactsManager.trashContacts.first { $0.givenName == "Bob" }!
        contactsManager.restoreContactFromTrash(bobInTrash) // User changes mind about Bob
        
        // Phase 3: Continue reviewing
        contactsManager.keepCurrentContact() // Keep Diana
        contactsManager.moveCurrentContactToTrash() // Trash Edward
        contactsManager.keepCurrentContact() // Keep Fiona
        
        // Phase 4: Process restored Bob (who was appended to the end)
        contactsManager.keepCurrentContact() // Keep Bob (now at the end)
        
        // Final verification
        XCTAssertFalse(contactsManager.hasMoreContacts)
        XCTAssertEqual(contactsManager.trashContacts.count, 1) // Only Edward
        XCTAssertEqual(contactsManager.trashContacts[0].givenName, "Edward")
        
        let finalContactNames = contactsManager.contacts.map { $0.givenName }.sorted()
        XCTAssertEqual(finalContactNames, ["Alice", "Bob", "Charlie", "Diana", "Fiona"])
    }
}