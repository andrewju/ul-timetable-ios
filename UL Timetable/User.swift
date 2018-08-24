//
//  User.swift
//
//  Created by Andrew on 16/8/8.
//

import UIKit

class User: NSObject, NSCoding {
    struct  PropertyKey {
        static let roleKey = "role"
        static let idKey = "id"
    }

    // MARK: Properties
    var role: String
    var userId: String
    
    // MARK: Archiving Paths
    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let ArchiveURL = DocumentsDirectory.appendingPathComponent("ul-timetable")
    
    // MARK: Initialization
    init?(role: String, userId: String) {
        self.role = role
        self.userId = userId
        
        super.init()
        
        if role.isEmpty || userId.isEmpty {
            return nil
        }
    }
    
    // MARK: NSCoding
    func encode(with aCoder: NSCoder) {
        aCoder.encode(role, forKey: PropertyKey.roleKey)
        aCoder.encode(userId, forKey: PropertyKey.idKey)
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        if let userId = aDecoder.decodeObject(forKey: PropertyKey.idKey) as? String,
            let role = aDecoder.decodeObject(forKey: PropertyKey.roleKey) as? String {
            self.init(role: role, userId: userId)
        } else {
            return nil
        }
    }
    
}
