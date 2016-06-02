//
//  ContactManager.swift
//  JobTracker
//
//  Created by Joanne Dyer on 3/10/15.
//  Copyright (c) 2015 Joanne Maynard. All rights reserved.
//

import Foundation
import AddressBook
import AddressBookUI

protocol ContactDelegate: class {
    func personSelected(person: ABRecord)
}

class ContactManager: NSObject, ABPersonViewControllerDelegate, ABPeoplePickerNavigationControllerDelegate, ABNewPersonViewControllerDelegate {
    
    var addressBook: ABAddressBook!
    var accessToAddressBookGranted = false
    weak var contactDelegate: ContactDelegate?
    
    //MARK:- Singleton Class Creation
    
    class var sharedInstance: ContactManager {
        struct Static {
            static let instance = ContactManager()
        }
        return Static.instance
    }
    
    private override init() {
        super.init()
        addressBook = ABAddressBookCreateWithOptions(nil, nil).takeRetainedValue()
        setAccessToAddressBook()
    }
    
    //MARK:- Address Book Access
    
    func askForAddressBookAccessWithCompletion(completion: () -> Void) {
        if ABAddressBookGetAuthorizationStatus() == ABAuthorizationStatus.NotDetermined {
            ABAddressBookRequestAccessWithCompletion(addressBook, {(granted, error) in
                NSOperationQueue.mainQueue().addOperationWithBlock({
                    self.setAccessToAddressBook()
                    completion()
                })
            })
        }
    }
    
    private func setAccessToAddressBook() {
        if ABAddressBookGetAuthorizationStatus() == ABAuthorizationStatus.Authorized {
            accessToAddressBookGranted = true
        } else {
            accessToAddressBookGranted = false
        }
    }
    
    //MARK:- Check Stored Data Against Address Book
    
    //during the gap since the app was last used, records in the address book may have changed IDs or been deleted all together, if the stored id no longer seems correct we will search by name or company.
    func findAddressBookPersonMatchingNameOrCompanyAndUpdateID(contact contact: JobContact) -> ABRecord? {
        //get record from address book that matches our stored ID. Check the name or company if there is no name is correct.
        let person: ABRecord? = ABAddressBookGetPersonWithRecordID(addressBook, contact.contactID.intValue).takeUnretainedValue()
        let first = ABRecordCopyValue(person, kABPersonFirstNameProperty)?.takeRetainedValue() as? String
        let last = ABRecordCopyValue(person, kABPersonLastNameProperty)?.takeRetainedValue() as? String
        let company = ABRecordCopyValue(person, kABPersonOrganizationProperty)?.takeRetainedValue() as? String
        
        //if the contact has no name and the company returned does not match the contact's company, search all address book records for one matching the stored company.
        if contact.first.isEmpty && contact.last.isEmpty && (company == nil || company! != contact.company) {
            //when our contact has no name just a company, search the address book by company.
            let allPeople = ABAddressBookCopyArrayOfAllPeople(addressBook).takeRetainedValue() as NSArray
            let matchingRecords = allPeople.filteredArrayUsingPredicate(NSPredicate(block: { (record, bindings) in
                let recordCompany = ABRecordCopyValue(record, kABPersonOrganizationProperty)?.takeRetainedValue() as? String
                if recordCompany == nil || recordCompany! != contact.company {
                    return false
                }
                let recordFirst = ABRecordCopyValue(record, kABPersonFirstNameProperty)?.takeRetainedValue() as? String
                let recordLast = ABRecordCopyValue(record, kABPersonLastNameProperty)?.takeRetainedValue() as? String
                if recordFirst != nil || recordLast != nil {
                    return false
                }
                return true
            }))
            
            //if there are none or multiple contacts matching the company return nil we have not been able to find a definitive record that matches our stored contact.
            var matchingPerson: ABRecord?
            if matchingRecords.count != 1 {
                matchingPerson = nil
                contact.contactID = -1
            } else {
                matchingPerson = matchingRecords[0]
                contact.contactID = NSNumber(int: ABRecordGetRecordID(matchingPerson))
            }
            
            //save changes
            do {
                try Common.managedContext.save()
            } catch {
                print("Could not save.")
            }
            return matchingPerson
        }
        
        //if the contact has a name and the first and last names returned do not match the contact's, search all address book records for one with the exact same name.
        if (first == nil && !contact.first.isEmpty) || (first != nil && first! != contact.first) || (last == nil && !contact.last.isEmpty) || (last != nil && last! != contact.last) {
            //if the contact has a name, search the address book for a record that matches it exactly.
            let allPeopleWithSimilarNames = ABAddressBookCopyPeopleWithName(addressBook, "\(contact.first) \(contact.last)" as CFStringRef).takeRetainedValue() as NSArray
            let matchingRecords = allPeopleWithSimilarNames.filteredArrayUsingPredicate(NSPredicate(block: { (record, bindings) in
                let recordFirst = ABRecordCopyValue(record, kABPersonFirstNameProperty)?.takeRetainedValue() as? String
                let recordLast = ABRecordCopyValue(record, kABPersonLastNameProperty)?.takeRetainedValue() as? String
                if (recordFirst == nil && !contact.first.isEmpty) || (recordFirst != nil && recordFirst! != contact.first) || (recordLast == nil && !contact.last.isEmpty) || (recordLast != nil && recordLast! != contact.last) {
                    return false
                }
                return true
            }))
            
            //if there are none or multiple contacts matching the company return nil we have not been able to find a definitive record that matches our stored contact.
            var matchingPerson: ABRecord?
            if matchingRecords.count != 1 {
                matchingPerson = nil
                contact.contactID = -1
            } else {
                matchingPerson = matchingRecords[0]
                contact.contactID = NSNumber(int: ABRecordGetRecordID(matchingPerson))
            }
            
            //save changes
            do {
                try Common.managedContext.save()
            } catch {
                print("Could not save.")
            }
            return matchingPerson
        }
        
        return person

    }
    
    //When a user edits the address book within the app our stored data may become incorrect and will need to be updated.
    func findAddressBookPersonMatchingIDAndUpdateName(contact contact: JobContact) -> ABRecord? {
        let person: ABRecord? = ABAddressBookGetPersonWithRecordID(addressBook, contact.contactID.intValue).takeUnretainedValue()
        
        if person == nil {
            return nil
        }
        
        let first = ABRecordCopyValue(person, kABPersonFirstNameProperty)?.takeRetainedValue() as? String
        let last = ABRecordCopyValue(person, kABPersonLastNameProperty)?.takeRetainedValue() as? String
        let company = ABRecordCopyValue(person, kABPersonOrganizationProperty)?.takeRetainedValue() as? String
            
        //if the user has deleted all the above fields, it is not longer a viable contact for our app and must be changed to not found.
        if first == nil && last == nil && company == nil {
            contact.contactID = -1
            do {
                try Common.managedContext.save()
            } catch {
                print("Could not save.")
            }
            return nil
        }
        
        if first != nil {
            contact.first = first!
        } else {
            contact.first = ""
        }
        if last != nil {
            contact.last = last!
        } else {
            contact.last = ""
        }
        if company != nil {
            contact.company = company!
        } else {
            contact.company = ""
        }
        
        do {
            try Common.managedContext.save()
        } catch {
            print("Could not save.")
        }

        return person
    }
    
    //MARK:- Display/Pick/Create Address Book Contact
    
    func displayContactInPersonVC(contact: JobContact, viewController: UIViewController) {
        let controller = ABPersonViewController()
        let person: ABRecord? = ABAddressBookGetPersonWithRecordID(addressBook, contact.contactID.intValue).takeUnretainedValue()
        if person != nil {
            controller.displayedPerson = person!
            controller.allowsActions = true
            controller.allowsEditing = true
            controller.personViewDelegate = self
            viewController.navigationController!.pushViewController(controller, animated: true)
        }
    }
    
    func pickPersonInPeoplePickerVC(viewController: UIViewController) {
        let controller = ABPeoplePickerNavigationController()
        controller.peoplePickerDelegate = self
        viewController.presentViewController(controller, animated: true, completion: nil)
    }
    
    func createPersonInNewPersonVC(viewController: UIViewController) {
        let controller = ABNewPersonViewController()
        controller.newPersonViewDelegate = self
        let newNavController = UINavigationController(rootViewController: controller)
        viewController.presentViewController(newNavController, animated: true, completion: nil)
    }
    
    //MARK:- ABPersonViewControllerDelegate
    
    func personViewController(personViewController: ABPersonViewController!, shouldPerformDefaultActionForPerson person: ABRecord!, property: ABPropertyID, identifier: ABMultiValueIdentifier) -> Bool {
        return true
    }
    
    //MARK:- ABPeoplePickerNavigationControllerDelegate
    
    func peoplePickerNavigationControllerDidCancel(peoplePicker: ABPeoplePickerNavigationController!) {
        peoplePicker.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func peoplePickerNavigationController(peoplePicker: ABPeoplePickerNavigationController!, didSelectPerson person: ABRecord!) {
        peoplePicker.dismissViewControllerAnimated(true, completion: nil)
        contactDelegate?.personSelected(person)
    }
    
    func peoplePickerNavigationController(peoplePicker: ABPeoplePickerNavigationController!, didSelectPerson person: ABRecord!, property: ABPropertyID, identifier: ABMultiValueIdentifier) {
        peoplePicker.dismissViewControllerAnimated(true, completion: nil)
        contactDelegate?.personSelected(person)
    }
    
    //MARK:- ABNewPersonViewControllerDelegate
    
    func newPersonViewController(newPersonView: ABNewPersonViewController!, didCompleteWithNewPerson person: ABRecord!) {
        newPersonView.dismissViewControllerAnimated(true, completion: nil)
        if person != nil {
            contactDelegate?.personSelected(person)
        }
    }
}