//
//  ShowContactsViewController.swift
//  JobTracker
//
//  Created by Joanne Dyer on 3/9/15.
//  Copyright (c) 2015 Joanne Maynard. All rights reserved.
//

import Foundation
import AddressBook
import CoreData

class ShowContactsViewController: UITableViewController, ContactDelegate {
    
    var loadedBasic: JobBasic!
    
    private var contacts: [(contact: JobContact, person: ABRecord?, doubleHeight: Bool)] = []
    private var reloadRequired = false
    
    //MARK:- UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //ask for access to address book if it hasn't already been done
        ContactManager.sharedInstance.askForAddressBookAccessWithCompletion(accessRequestCompleted)
        
        //set the contacts array initially up with nil for person, the correct data will be filled-in in updateContactsAndCheckIfTheyShouldBeEnabled
        for contact in loadedBasic!.orderedContacts {
            contacts.append(contact: contact, person: nil, doubleHeight: false)
        }
        updateContactIDsAndCheckIfTheyShouldBeEnabled()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if reloadRequired {
        //check for changes in contacts
            updateContactDataAndCheckIfTheyShouldBeEnabled()
            tableView.reloadData()
            reloadRequired = false
        }
    }
    
    //MARK:-
    
    func accessRequestCompleted() {
        //reload tableview to make sure add/select contact buttons are enabled as appropriate
        tableView.reloadData()
    }
    
    //checks for changes in contact ids since the app was last opened.
    private func updateContactIDsAndCheckIfTheyShouldBeEnabled() {
        let originalContacts = contacts
        contacts = []
        for contactTuple in originalContacts {
            let person: ABRecord? = ContactManager.sharedInstance.findAddressBookPersonMatchingNameOrCompanyAndUpdateID(contact: contactTuple.contact)
            let doubleHeight = doesPersonRequireDoubleHeightCell(person: person)
            contacts.append(contact: contactTuple.contact, person: person, doubleHeight: doubleHeight)
        }
    }
    
    //check for changes in contact data (e.g. name) following a contact being viewed.
    private func updateContactDataAndCheckIfTheyShouldBeEnabled() {
        let originalContacts = contacts
        contacts = []
        for contactTuple in originalContacts {
            let person: ABRecord? = ContactManager.sharedInstance.findAddressBookPersonMatchingIDAndUpdateName(contact: contactTuple.contact)
            let doubleHeight = doesPersonRequireDoubleHeightCell(person: person)
            contacts.append(contact: contactTuple.contact, person: person, doubleHeight: doubleHeight)
        }
    }
    
    //MARK:- UITableViewDataSource
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if contacts.count == 0 {
            return 1
        }
        return 2
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 1 {
            return "Contacts"
        }
        return nil
    }
    
    override func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        let accessGranted = ContactManager.sharedInstance.accessToAddressBookGranted
        if section == 0 && !accessGranted {
            return "Requires access to your contacts"
        }
        return nil
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 2
        }
        return contacts.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell: ShowResultCell
        if indexPath.section == 0 {
            cell = tableView.dequeueReusableCellWithIdentifier("showContactCell") as! ShowResultCell
        } else {
            let doubleHeight = contacts[indexPath.row].doubleHeight
            if doubleHeight {
                cell = tableView.dequeueReusableCellWithIdentifier("showContactWithDetailCell") as! ShowResultCell
            } else {
                cell = tableView.dequeueReusableCellWithIdentifier("showContactCell") as! ShowResultCell
            }
        }
        
        configureCell(cell, atIndexPath: indexPath)
        return cell
    }

    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        if indexPath.section == 1 {
            return true
        }
        return false
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == UITableViewCellEditingStyle.Delete {
            let contact = contacts[indexPath.row].contact
            Common.managedContext.deleteObject(contact)
            deleteContactAtIndex(indexPath)
            saveData()
        }
    }
    
    //MARK:-
    
    private func configureCell(cell: ShowResultCell, atIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 0 {
            let accessGranted = ContactManager.sharedInstance.accessToAddressBookGranted
            cell.userInteractionEnabled = accessGranted
            cell.mainLabel.enabled = accessGranted
            
            if indexPath.row == 0 {
                cell.mainLabel.text = "Create New Contact"
            } else {
                cell.mainLabel.text = "Select Existing Contact"
            }
        } else {
            if contacts[indexPath.row].person != nil {
                cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
                cell.selectionStyle = UITableViewCellSelectionStyle.Default
                cell.mainLabel.enabled = true
            } else {
                cell.accessoryType = UITableViewCellAccessoryType.None
                cell.selectionStyle = UITableViewCellSelectionStyle.None
                cell.mainLabel.enabled = false
            }
            
            let contactTuple = contacts[indexPath.row]
            cell.mainLabel.text = mainTextForCell(contact: contactTuple.contact, person: contactTuple.person)
            
            if contactTuple.doubleHeight {
                cell.secondaryLabel!.text = secondaryTextForCell(contact: contactTuple.contact, person: contactTuple.person)
            }
        }
    }

    private func mainTextForCell(#contact: JobContact, person: ABRecord?) -> String {
        if person != nil {
            return ABRecordCopyCompositeName(person).takeRetainedValue() as String
        } else {
            var textArray = [String]()
            if !contact.first.isEmpty {
                textArray.append(contact.first)
            }
            if !contact.last.isEmpty {
                textArray.append(contact.last)
            }
            if textArray.count == 0 {
                textArray.append(contact.company)
            }
            textArray.append("- not found")
            return join(" ", textArray)
        }
    }
    
    private func secondaryTextForCell(#contact: JobContact, person: ABRecord?) -> String {
        if person == nil {
            return ""
        }
        
        let jobTitle = ABRecordCopyValue(person, kABPersonJobTitleProperty)?.takeRetainedValue() as? String
        let department = ABRecordCopyValue(person, kABPersonDepartmentProperty)?.takeRetainedValue() as? String
        let company = ABRecordCopyValue(person, kABPersonOrganizationProperty)?.takeRetainedValue() as? String
        
        var textArray = [String]()
        if jobTitle != nil {
            textArray.append(jobTitle!)
        }
        if department != nil {
            textArray.append(department!)
        }
        if company != nil {
            textArray.append(company!)
        }
        return join(" - ", textArray)
    }
    
    private func doesPersonRequireDoubleHeightCell(#person: ABRecord?) -> Bool {
        if person == nil {
            return false
        }
        
        let compositeName = ABRecordCopyCompositeName(person).takeRetainedValue() as String
        let company = ABRecordCopyValue(person, kABPersonOrganizationProperty)?.takeRetainedValue() as? String
        if company != nil && compositeName == company! {
            return false
        }
        
        let jobTitle = ABRecordCopyValue(person, kABPersonJobTitleProperty)?.takeRetainedValue() as? String
        let department = ABRecordCopyValue(person, kABPersonDepartmentProperty)?.takeRetainedValue() as? String
        if jobTitle != nil || department != nil || company != nil {
            return true
        }
        return false
    }
    
    private func deleteContactAtIndex(indexPath: NSIndexPath) {
        contacts.removeAtIndex(indexPath.row)
        tableView.beginUpdates()
        tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
        if contacts.count == 0 {
            let indexSet = NSIndexSet(index: 1)
            tableView.deleteSections(indexSet, withRowAnimation: .Automatic)
        }
        tableView.endUpdates()
    }
    
    //MARK:- UITableViewDelegate
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.section == 0 {
            return 44
        }
        
        let doubleHeight = contacts[indexPath.row].doubleHeight
        if doubleHeight {
            return 79
        }
        return 44
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 0 {
            if indexPath.row == 0 {
                addNewContactSelected()
            } else {
                addCurrentContactSelected()
            }
        } else {
            if contacts[indexPath.row].person != nil {
                let contact = contacts[indexPath.row].contact
                displayContact(contact)
            }
        }
    }
    
    //MARK:-
    
    private func displayContact(contact: JobContact) {
        ContactManager.sharedInstance.displayContactInPersonVC(contact, viewController: self)
        reloadRequired = true
    }
    
    private func addNewContactSelected() {
        ContactManager.sharedInstance.contactDelegate = self
        ContactManager.sharedInstance.createPersonInNewPersonVC(self)
    }
    
    private func addCurrentContactSelected() {
        ContactManager.sharedInstance.contactDelegate = self
        ContactManager.sharedInstance.pickPersonInPeoplePickerVC(self)
    }

    //MARK:- ContactDelegate
    
    func personSelected(person: ABRecord) {
        createJobContactFromPerson(person)
    }
    
    //MARK:-
    
    private func createJobContactFromPerson(person: ABRecord) {
        let personFirst = ABRecordCopyValue(person, kABPersonFirstNameProperty)?.takeRetainedValue() as? String
        let personLast = ABRecordCopyValue(person, kABPersonLastNameProperty)?.takeRetainedValue() as? String
        let personCompany = ABRecordCopyValue(person, kABPersonOrganizationProperty)?.takeRetainedValue() as? String
        let personID = NSNumber(int: ABRecordGetRecordID(person))
        
        //the person picked must have a name or a company
        if personFirst == nil && personLast == nil && personCompany == nil {
            let alert = UIAlertView(title: "Selection Failed", message: "The selected contact must have a first name, a last name or a company.", delegate: nil, cancelButtonTitle: "OK")
            alert.show()
            return
        }
        
        //the person picked must not already have been picked.
        for existingContact in contacts {
            if existingContact.person != nil && personID == existingContact.contact.contactID {
                let alert = UIAlertView(title: "Selection Failed", message: "The selected contact has already been added", delegate: nil, cancelButtonTitle: "OK")
                alert.show()
                return
            }
        }
        
        let contact = NSEntityDescription.insertNewObjectForEntityForName("JobContact", inManagedObjectContext: Common.managedContext) as! JobContact
        Common.managedContext.insertObject(contact)
        loadedBasic.contacts.setByAddingObject(contact)
        contact.basic = loadedBasic
        
        if personFirst != nil {
            contact.first = personFirst!
        } else {
            contact.first = ""
        }
        if personLast != nil {
            contact.last = personLast!
        } else {
            contact.last = ""
        }
        if personCompany != nil {
            contact.company = personCompany!
        } else {
            contact.company = ""
        }
        contact.contactID = personID
        
        //find out where to add into contacts, should be alphabetical by surname, firstname then company
        let contactText = mainTextForCell(contact: contact, person: person)
        var insertionIndex = 0
        if contacts.count != 0 {
            for i in 0..<contacts.count {
                let otherContact = contacts[i]
                let otherContactText = mainTextForCell(contact: otherContact.contact, person: otherContact.person)
                
                if otherContactText < contactText {
                    insertionIndex++
                } else {
                    break
                }
            }
        }
        
        let indexPath = NSIndexPath(forRow: insertionIndex, inSection: 1)
        insertContact(contact, person: person, indexPath: indexPath)
        saveData()
    }
    
    private func insertContact(contact: JobContact, person: ABRecord, indexPath: NSIndexPath) {
        let doubleHeight = doesPersonRequireDoubleHeightCell(person: person)
        contacts.insert((contact: contact, person: person, doubleHeight: doubleHeight), atIndex: indexPath.row)
        tableView.beginUpdates()
        if contacts.count == 1 {
            let indexSet = NSIndexSet(index: 1)
            tableView.insertSections(indexSet, withRowAnimation: .Automatic)
        }
        tableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
        tableView.endUpdates()
    }

    //MARK:- Core Data Changers
    
    private func saveData() {
        var error: NSError?
        if !Common.managedContext.save(&error) {
            println("Could not save \(error), \(error?.userInfo)")
        }
    }
}



