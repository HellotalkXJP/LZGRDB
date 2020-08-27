//
//  DatabaseInterface.swift
//  LZGRDB
//
//  Created by Mac on 2020/8/24.
//  Copyright © 2020 Mac. All rights reserved.
//

import Foundation

public class DatabaseInterface: NSObject {
    public static let sharedInterface = DatabaseInterface()
    
    var dbName: String = "default.sqlite"
    var dbPath: String = NSHomeDirectory() + "/Documents/"
    
    public var interfaceDelegate: DatabaseInterfaceDelegate?
    
    public override init() {
        super.init()
    }
    
    // 设置数据库路径以及数据库名字
    public func setDatabase(dbName: String = "default.sqlite", dbPath: String = NSHomeDirectory() + "/Documents/") {
        self.dbName = dbName
        self.dbPath = dbPath
    }
    
    public func executeDataMessage(_ message: inout DataMessage) {
        manager.executeDataMessage(&message)
    }
    
    lazy var manager: GRDBManager = {
        return GRDBManager(dbName: dbName, path: dbPath, deletegate: self)
    }()
}

extension DatabaseInterface: DatabaseInterfaceDelegate {
    public func executeFinishWithDataMessage(_ message: DataMessage) {
        if interfaceDelegate != nil {
            interfaceDelegate?.executeFinishWithDataMessage(message)
        }
    }
}

public protocol DatabaseInterfaceDelegate {
    func executeFinishWithDataMessage(_ message: DataMessage)
}

extension DatabaseInterfaceDelegate {
    func executeFinishWithDataMessage(_ message: DataMessage) {
        print("executeFinishWithDataMessage in extension")
    }
}
