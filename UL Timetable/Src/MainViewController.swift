//
//  HomeTableViewController.swift
//
//  Created by Andrew on 8/17/16.
//

import UIKit
import EventKit
import MessageUI
import StoreKit
class HomeTableViewController: UITableViewController, UITextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource, MFMailComposeViewControllerDelegate {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return userRoles.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return userRoles[row]
    }
    
    @objc func doneClick() {
        self.userRolesTextField.text = userRoles[userRoleInput.selectedRow(inComponent: 0)]
        userRole = userRoles[userRoleInput.selectedRow(inComponent: 0)].uppercased()
        userRolesTextField.resignFirstResponder()
        self.userRolesTableViewCell.isSelected = false
        self.userID.resignFirstResponder()
        
        self.userID.text = ""
        self.userID.keyboardType = (userRole == "STUDENT" ? .numberPad: .default)
        self.userID.becomeFirstResponder()
    }
    
    @objc func cancelClick() {
        userRolesTextField.resignFirstResponder()
        self.userRolesTableViewCell.isSelected = false
        
    }
    
    // MARK: Properties
    var userId: String = ""
    var userRole: String = ""
    var startDateStr: String = ""
    var appStoreUpdate: Bool = false
    var errorHappened: Bool = false
    var errorCode: Int = 0
    let eventStore = EKEventStore()
    let dateMakerFormatter = DateFormatter()
    let userRoles = ["STUDENT", "STAFF"]
    
    var userRoleInput: UIPickerView!
    @IBOutlet weak var progressView: UIActivityIndicatorView!
    @IBOutlet weak var addBarButton: UIBarButtonItem!
    @IBOutlet weak var statusTableViewCell: UITableViewCell!
    @IBOutlet weak var userRolesTableViewCell: UITableViewCell!
    @IBOutlet weak var userIDTableViewCell: UITableViewCell!
    @IBOutlet weak var userID: UITextField!
    @IBOutlet weak var userRolesTextField: UITextField!
    @IBOutlet weak var noticeLabel: UILabel!
    
    @IBAction func tappedNoticeLabel(_ sender: Any) {
        
        if let config = AppDelegate.getRemoteConfig() {
            let actionType = config.getNumber(ULRemoteConfigurationKey.serviceNoticeType.rawValue)
            if actionType == 1 || actionType == 3 {
                var actionLink = config.getString(ULRemoteConfigurationKey.serviceNoticeAction.rawValue)
                if actionType == 1 && appStoreUpdate {
                    actionLink = config.getString(ULRemoteConfigurationKey.serviceIPAURL.rawValue)
                }
                guard let url = URL(string: actionLink!) else {
                    return //be safe
                }
                if #available(iOS 10.0, *) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                } else {
                    UIApplication.shared.openURL(url)
                }
            }
        }
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true)
    }
    
    func getMailBody() -> String {
        let path = Bundle.main.path(forResource: "Info", ofType: "plist")
        let resultDic = NSMutableDictionary(contentsOfFile: path!)! as NSMutableDictionary
        if let sysVersion = resultDic.object(forKey: "systemVersion") as? Int {
            return
                "<p>Error Details</p>" +
                "<ul><li>ID: \(userId)</li>" +
                "<li>App version: \(sysVersion)</li>" +
                "<li>iOS Version: \(UIDevice.current.systemVersion)</li>" +
                "<li>Error code: \(errorCode) </li></ul>"
        } else {
            return
                "<p>Error Details</p>" +
                "<ul><li>ID: \(userId)</li>" +
                "<li>iOS version: \(UIDevice.current.systemVersion)</li>" +
                "<li>Error code: \(errorCode) </li></ul>"
            
        }
    }
    
    func sendEmail() {
        if MFMailComposeViewController.canSendMail() {
            let mail = MFMailComposeViewController()
            
            mail.mailComposeDelegate = self
            mail.setToRecipients(["ul-timetable-app@outlook.com"])
            mail.setSubject("Error Report")
            mail.setMessageBody(getMailBody(), isHTML: true)
            
            present(mail, animated: true)
        } else {
            // show failure alert
        }
    }
    func tappedUserRoles() {
        // UIPickerView
        self.userRoleInput = UIPickerView(frame: CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: 216))
        self.userRoleInput.delegate = self
        self.userRoleInput.dataSource = self
        
        let index = userRoles.index(of: userRole)
        self.userRoleInput.selectRow(index!, inComponent: 0, animated: false)
        self.userRoleInput.backgroundColor = UIColor.white
        userRolesTextField.inputView = self.userRoleInput
        
        // ToolBar
        let toolBar = UIToolbar()
        toolBar.sizeToFit()
        
        // Adding Button ToolBar
        let doneButton = UIBarButtonItem.init(barButtonSystemItem: .done,
                                              target: self,
                                              action: #selector(self.doneClick))
        
        let spaceButton = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(self.cancelClick))
        toolBar.setItems([cancelButton, spaceButton, doneButton], animated: false)
        toolBar.isUserInteractionEnabled = true
        userRolesTextField.inputAccessoryView = toolBar
    }
    
    func request(requestURL: URL, completion: @escaping (Data?, URLResponse?, Error?) -> Swift.Void) {
        var request = URLRequest(url: requestURL)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.cachePolicy = NSURLRequest.CachePolicy.reloadIgnoringCacheData
        let session = URLSession.shared
        let task = session.dataTask(with: request as URLRequest) {(data, response, error) in
            
            guard let data = data, let _:URLResponse = response, error == nil else {
                print("error")
                completion(nil, response, error)
                return
            }
            completion(data, response, error)
        }
        
        task.resume()
    }
    //swiftlint:disable:next function_body_length
    func requestTimetable() {
        guard let config = AppDelegate.getRemoteConfig() else {
            return
        }
        
        startDateStr = config.semesterStartDate
        let type = (self.userRole == "STAFF" ? "true" : "false")
        let params = "/id/"+self.userId+"/staff/"+type+"/today/false"
        self.request(requestURL: URL.init(string: "\(config.serverHost)\(config.getServiceName(ULRemoteConfigurationKey.serviceTimeTable.rawValue, defaultValue: "id-timetable-v2.php"))\(params)")!, completion: { (data, _, error) in
            if !(error != nil) {
                do {
                    _ = self.cleanCalendar()
                    if let json = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? [String: AnyObject] {
                        if let results = json["classes"] as? [[String: AnyObject]] {
                            for result in results {
                                if let eventLocation = result["room"] as? String,
                                    let eventSequence = result["weeks"] as? String,
                                    let eventTime = result["time"] as? String,
                                    let eventTitle = result["name"] as? String,
                                    let eventCode = result["type"] as? String,
                                    let eventDay = result["day"] as? Int {
                                    for item in eventSequence.components(separatedBy: ",") {
                                        DispatchQueue.main.async {
                                            self.errorHappened = !self.addEventToCalendar(eventTitle, code: eventCode, sequence: item, location: eventLocation, time: eventTime, day: eventDay)
                                            if self.errorHappened {
                                                return
                                            }
                                        }
                                    }
                                }
                            }
                            
                            DispatchQueue.main.async {
                                if !self.errorHappened {
                                    self.displayAlert(2)
                                    self.saveUserInfo()
                                    self.statusTableViewCell.textLabel?.text = self.userRole+": "+self.userId
                                    self.addBarButton.isEnabled = true
                                } else {
                                    _ = self.cleanCalendar()
                                    self.displayAlert(5)
                                }
                                
                            }
                        }
                    }
                    
                } catch {
                    print("error serializing JSON: \(error)")
                    DispatchQueue.main.async {
                        self.errorCode = -10 // special code
                        self.displayAlert(6)
                        self.saveUserInfo()
                        self.statusTableViewCell.textLabel?.text = self.userRole+": "+self.userId
                        self.addBarButton.isEnabled = true
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.displayAlert(0)
                    self.saveUserInfo()
                    self.statusTableViewCell.textLabel?.text = self.userRole+": "+self.userId
                    self.addBarButton.isEnabled = true
                }
            }
        })
    }
    
    func formatTime(time: String) -> String {
        // The length constraint is added in the addEventToCalendar function
        return time.components(separatedBy: ":")[0]+time.components(separatedBy: ":")[1]
    }
    
    // MARK: Method
    func addEventToCalendar(_ title: String, code: String, sequence: String, location: String, time: String, day: Int) -> Bool {
        let event = EKEvent(eventStore: eventStore)
        
        // summary
        event.title = code
        // location
        event.location = location.replacingOccurrences(of: "&nbsp;", with: "No room available")
        // group + summary + sequence
        event.notes = title
        event.calendar = eventStore.defaultCalendarForNewEvents
        
        dateMakerFormatter.timeZone = TimeZone.current
        dateMakerFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateMakerFormatter.dateFormat = "yyyyMMdd'T'HHmm"
        
        if time.components(separatedBy: "-").count != 2 {
            self.errorCode = -1
            return false
        }
        
        var parts = time.components(separatedBy: "-")
        if parts[0].components(separatedBy: ":").count != 2 || parts[1].components(separatedBy: ":").count != 2 {
            self.errorCode = -2
            return false
        }
        
        if let startTime = dateMakerFormatter.date(from: startDateStr+formatTime(time: parts[0].trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines))),
            let endTime = dateMakerFormatter.date(from: startDateStr+formatTime(time: parts[1].trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines))) {
            let startDate = startTime.addingTimeInterval(3600.0*24*(Double(day)-1))
            let endDate = endTime.addingTimeInterval(3600.0*24*(Double(day)-1))
            
            // sequence: 1-8,10-13
            // sequence: 2, 4-6
            // sequence: 2-5,8,11
            if sequence.contains("-") {
                // eventTime + eventDuration
                let start = Int(sequence.components(separatedBy: "-")[0])!
                let end = Int(sequence.components(separatedBy: "-")[1])!
                
                event.startDate = startDate.addingTimeInterval(3600.0*24*7*Double(start-1))
                event.endDate = endDate.addingTimeInterval(3600.0*24*7*Double(start-1))
                event.addAlarm(EKAlarm.init(relativeOffset: -15*60))
                
                let recurringEnd = EKRecurrenceEnd(occurrenceCount: end-start+1)
                let recurringRule = EKRecurrenceRule(recurrenceWith: .weekly, interval: 1, end: recurringEnd)
                event.recurrenceRules = [recurringRule]
                
            } else {
                // eventTime + eventDuration
                event.startDate = startDate.addingTimeInterval(3600.0*24*7*(Double(sequence)!-1))
                event.endDate = endDate.addingTimeInterval(3600.0*24*7*(Double(sequence)!-1))
            }
            
            do {
                try eventStore.save(event, span: .futureEvents)
                return true
            } catch let error as NSError {
                print("\(error)")
                self.errorCode = -4
            }
        } else {
            self.errorCode = -3
        }
        
        return false
    }
    
    func cleanCalendar() -> Bool {
        
        var result = false
        dateMakerFormatter.dateFormat = "yyyyMMdd'T"
        if let startDate = dateMakerFormatter.date(from: startDateStr) {
            // 6 MONTH WINDOW
            let endDate = startDate.addingTimeInterval(3600*24*30*6)
            
            if let calList = eventStore.defaultCalendarForNewEvents {
                let predicate = eventStore.predicateForEvents(withStart: startDate,
                                                              end: endDate,
                                                              calendars: [calList])
                
                /* Get all the events that match the parameters */
                let events = eventStore.events(matching: predicate)
                    
                    as [EKEvent]
                
                if events.count > 0 {
                    /* Delete them all */
                    for event in events {
                        if event.title.contains("LEC")||event.title.contains("TUT")||event.title.contains("LAB") {
                            
                            do {
                                try eventStore.remove(event, span: .futureEvents, commit: false)
                            } catch let error as NSError {
                                print("Failed to remove \(event) with error = \(error)")
                            }
                        }
                    }
                    
                    do {
                        try eventStore.commit()
                        print("Successfully committed")
                        result = true
                    } catch let error as NSError {
                        print("Failed to commit the event store with error = \(error)")
                    }
                    
                } else {
                    print("No events matched your input.")
                }
            }
        }
        return result
    }
    
    func addTimetable() {
        // 0 -> Error happened
        // 1 -> Up to date
        // 2 -> Added successfully
        // 3 -> "Access to the event store is denied."
        // 4 -> "Access to the event store is restricted."
        
        self.errorHappened = false
        
        dateMakerFormatter.dateFormat = "yyyyMMdd'T'HHmm"
        switch EKEventStore.authorizationStatus(for: .event) {
            
        case .authorized:
            requestTimetable()
        case .denied:
            self.displayAlert(3)
        case .notDetermined:
            eventStore.requestAccess(to: .event, completion: {granted, _ in
                if granted {
                    self.requestTimetable()
                } else {
                    self.displayAlert(3)
                }
            })
        case .restricted:
            self.displayAlert(4)
        }
    }
    
    //swiftlint:disable:next function_body_length
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let savedUser = loadUserInfo() {
            userId = savedUser.userId
            userRole = savedUser.role
            
            statusTableViewCell.textLabel?.text = userRole+": "+userId
        } else {
            userId = "09003523"
            userRole = "STUDENT"
            
            statusTableViewCell.textLabel?.text = "Not added yet"
        }
        
        userID.delegate = self
        userID.text = userId
        
        userRolesTextField.delegate = self
        userRolesTextField.text = userRole
        
        if let config = AppDelegate.getRemoteConfig() {
            
            let actionType = config.getNumber(ULRemoteConfigurationKey.serviceNoticeType.rawValue)
            if actionType == 1 {
                // Open URL
                addBarButton.isEnabled = true
                noticeLabel.backgroundColor = UIColor.init(red: 19/255.0, green: 104/255.0, blue: 250/255.0, alpha: 1.0)
                
                userRolesTableViewCell.isUserInteractionEnabled = true
                userIDTableViewCell.isUserInteractionEnabled = true
                
                // check app version with App Store version
                // fetch system version from .plist file
                let path = Bundle.main.path(forResource: "Info", ofType: "plist")
                let resultDic = NSMutableDictionary(contentsOfFile: path!)! as NSMutableDictionary
                if let sysVersion = resultDic.object(forKey: "systemVersion") as? Int {
                    if sysVersion < (config.getNumber(ULRemoteConfigurationKey.appStoreVersion.rawValue)?.intValue)! {
                        appStoreUpdate = true
                        noticeLabel.text = "Click to update your app to latest version"
                    } else {
                        noticeLabel.text = config.getString(ULRemoteConfigurationKey.serviceNoticeMessage.rawValue)
                    }
                }
                
            } else if actionType == 2 || actionType == 3 {
                // Disable Button
                noticeLabel.text = config.getString(ULRemoteConfigurationKey.serviceNoticeMessage.rawValue)
                
                addBarButton.isEnabled = false
                noticeLabel.backgroundColor = UIColor.gray
                
                userRolesTableViewCell.isUserInteractionEnabled = false
                userIDTableViewCell.isUserInteractionEnabled = false
                
            }
        }
        
        //Add "DONE" button to the keyboard
        let toolbar = UIToolbar()
        let flexButton = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneButton = UIBarButtonItem.init(barButtonSystemItem: .done,
                                              target: self.userID,
                                              action: #selector(UITextField.resignFirstResponder))
        toolbar.setItems([flexButton, doneButton], animated: true)
        toolbar.sizeToFit()
        
        self.userID.inputAccessoryView = toolbar
    }
    
    @IBAction func addButton(_ sender: UIBarButtonItem) {
        progressView.startAnimating()
        addBarButton.isEnabled = false
        addTimetable()
    }
    
    func displayAlert(_ type: Int) {
        var typeDescription: String?
        switch type {
        case 0:
            typeDescription = "Please make sure there is internet connection and try again!"
        case 1:
            typeDescription = "Your timetable is already added."
        case 2:
            typeDescription = "Your timetable is added."
        case 3:
            typeDescription = "Access to the event store is denied. Please go to Settings -> UL Timetable and turn on the Calendars access."
        case 4:
            typeDescription = "Access to the event store is restricted. Please go to Settings -> UL Timetable and turn on the Calendars access."
        case 5:
            typeDescription = "Something is wrong, sorry it happened."
        case 6:
            typeDescription = "Something is wrong, sorry it happened."
        default:
            typeDescription = "Unknown error happened"
        }
        
        DispatchQueue.main.async {
            self.progressView.stopAnimating()
            self.addBarButton.isEnabled = true
        }
        
        let alertController = UIAlertController(title: typeDescription, message: nil, preferredStyle: .alert)
        let OKAction = UIAlertAction(title: "OK", style: .default) { (_) in
            if type == 1 || type == 2 {
                SKStoreReviewController.requestReview()
            }
            
            if type >= 5 {
                let alertController = UIAlertController(title: "Report Issue", message: "This will help us in addressing the issue you have, thanks!", preferredStyle: .alert)
                let okAction = UIAlertAction(title: "OK", style: .default) { (_) in
                    self.sendEmail()
                }
                let cancelAction = UIAlertAction(title: "Not Now", style: .default) {(_) in }
                
                alertController.addAction(okAction)
                alertController.addAction(cancelAction)
                
                alertController.preferredAction = okAction
                
                self.present(alertController, animated: true) {}
            }
        }
        alertController.addAction(OKAction)
        self.present(alertController, animated: true) {}
    }
    
    func loadUserInfo() -> User? {
        return NSKeyedUnarchiver.unarchiveObject(withFile: User.ArchiveURL.path) as? User
    }
    
    func saveUserInfo() {
        let isSuccessfulSave = NSKeyedArchiver.archiveRootObject(User(role: userRole, userId: userId)!, toFile: User.ArchiveURL.path)
        if !isSuccessfulSave {
            print("Failed to save user...")
        }
    }
    
    func checkData() -> Bool {
        if userID.hasText == false || (userID.text?.count)! < 7 || (userID.text?.count)! > 9 {
            return false
        }
        if userRole == "STUDENT" {
            if let value = userID.text {
                // swiftlint:disable:next force_try
                let regex = try! NSRegularExpression(pattern: "^[0-9]+$", options: [])
                // swiftlint:disable:next legacy_constructor
                let isMatch = regex.firstMatch(in: value, options: [], range: NSMakeRange(0, value.utf16.count)) != nil
                
                return isMatch
            }
            return false
        } else {
            if let value = userID.text {
                // swiftlint:disable:next force_try
                let regex = try! NSRegularExpression(pattern: "^[a-z]+[0-9]{1}$", options: [])
                // swiftlint:disable:next legacy_constructor
                let isMatch = regex.firstMatch(in: value, options: [], range: NSMakeRange(0, value.utf16.count)) != nil
                
                return isMatch
            }
            return false
        }
    }
    
    // MARK: UITextFieldDelegate
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField === userRolesTextField {
            tappedUserRoles()
        } else {
            addBarButton.isEnabled = false
            textField.keyboardType = (userRolesTextField.text?.uppercased() == "STUDENT" ? UIKeyboardType.numberPad: UIKeyboardType.default)
            textField.becomeFirstResponder()
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField === userRolesTextField {
            
        } else {
            textField.resignFirstResponder()
            userId = textField.text!
            addBarButton.isEnabled = checkData()
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
