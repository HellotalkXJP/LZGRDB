//
//  DatabaseInterface.swift
//  LZGRDB
//
//  Created by Mac on 2020/8/24.
//  Copyright © 2020 Mac. All rights reserved.
//

import Foundation

class DatabaseInterface: NSObject {
    static let sharedInterface = DatabaseInterface()
    
    var dbName: String = "default.sqlite"
    var dbPath: String = NSHomeDirectory() + "/Documents/"
    
    var interfaceDelegate: DatabaseInterfaceDelegate?
    
    override init() {
        super.init()
    }
    
    // 设置数据库路径以及数据库名字
    func setDatabase(dbName: String = "default.sqlite", dbPath: String = NSHomeDirectory() + "/Documents/") {
        self.dbName = dbName
        self.dbPath = dbPath
    }
    
    func executeDataMessage(_ message: inout DataMessage) {
        manager.executeDataMessage(&message)
    }
    
    lazy var manager: GRDBManager = {
        return GRDBManager(dbName: dbName, path: dbPath, deletegate: self)
    }()
}

extension DatabaseInterface: DatabaseInterfaceDelegate {
    func executeFinishWithDataMessage(_ message: DataMessage) {
        if interfaceDelegate != nil {
            interfaceDelegate?.executeFinishWithDataMessage(message)
        }
    }
}

protocol DatabaseInterfaceDelegate {
    func executeFinishWithDataMessage(_ message: DataMessage)
}

extension DatabaseInterfaceDelegate {
    func executeFinishWithDataMessage(_ message: DataMessage) {
        print("executeFinishWithDataMessage in extension")
    }
}
