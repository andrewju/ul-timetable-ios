//
//  ULConfiguration.swift
//  UL Timetable
//
//  Created by Andrew Ju on 21/06/2018.
//  Copyright © 2018 Andrew Design. All rights reserved.
//
import UIKit
import FirebaseCore
import FirebaseRemoteConfig

enum ULRemoteConfigurationKey: String {
    case serviceIPAURL = "service_ipa_url"
    case serviceNoticeMessage = "service_notice_message"
    case serviceNoticeType = "service_notice_type"
    case serviceNoticeAction = "service_notice_action"
    case serverHost = "server_prefix"
    case appStoreVersion = "app_store_version"
    case miniAppVersion = "minimal_version_ipa"
    case semesterStartDate = "semester_start_date"
    case serviceTimeTable = "service_name_time_table"
}

enum PushCommandKey: String {
    case messageType
}

enum PushMessageType: String {
    case news
    case emergency
}
enum PushConfigurationKey: String {
    case link
    case badge
    case title
    case message
    case tabIndex
}

class ULConfiguration: NSObject {
    var remoteCofig: RemoteConfig?
    func loadDefaultConfigs() -> Bool {
        FirebaseApp.configure()
        let remoteConfi = RemoteConfig.remoteConfig()
        
        if let path = Bundle.main.path(forResource: "ULRemoteConfDefaults", ofType: "plist"),
            let defaultConfigs = NSDictionary(contentsOfFile: path) as? [String: NSObject] {
            let remoteConfigSettings = RemoteConfigSettings(developerModeEnabled: true)
            remoteConfi.configSettings = remoteConfigSettings
            remoteConfi.setDefaults(defaultConfigs)
            self.remoteCofig = remoteConfi
            
            return true
        } else {
            print("Waring!!! failed to load the default configurations")
            return false
        }
    }
    
    func fetchRemoteConfigs(_ timeoutDuration: TimeInterval, callback: @escaping (_ status: RemoteConfigFetchStatus, _ error: Error?) -> Void) {
        
        self.remoteCofig?.fetch(withExpirationDuration: TimeInterval(5)) { (status, error) in
            if status == .success {
                self.remoteCofig?.activateFetched()
                callback(status, error)
            } else {
                print("Waring!!! failed to fetch remote configurations")
                callback(status, error)
            }
        }
    }
    
    func getString(_ forKey: String) -> String? {
        return remoteCofig?[forKey].stringValue
    }
    
    func getBool(_ forKey: String) -> Bool {
        return remoteCofig?[forKey].boolValue ?? false
    }
    
    func getNumber(_ forKey: String) -> NSNumber? {
        return remoteCofig?[forKey].numberValue
    }
    
    var semesterStartDate: String {
        return getString(ULRemoteConfigurationKey.semesterStartDate.rawValue) ?? "20180910T"
    }
    
    var serverHost: String {
        return getString(ULRemoteConfigurationKey.serverHost.rawValue) ?? "35.189.65.75"
    }
    
    func getServiceName(_ key: String, defaultValue: String) -> String {
        return getString(key) ?? defaultValue
    }
}
