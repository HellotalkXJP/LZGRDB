//
//  DatabaseService.swift
//  DatabaseDemo
//
//  Created by Mac on 2020/8/12.
//  Copyright © 2020 Mac. All rights reserved.
//

import Foundation
import GRDB

typealias DatabaseCompleteBlock = (_ result: DataBaseResultSet) -> Void

class DatabaseService: NSObject {
    let dbPath: String
    
    init(dbPath: String) {
        self.dbPath = dbPath
        super.init()
    }
    
    func readWithDataMessage(_ dataMessage: DataMessage, _ completionBlock: DatabaseCompleteBlock) {
        if dataMessage.databaseConnectType == .low {
            lowConnect.readWithDataMessage(dataMessage, completionBlock)
        } else if dataMessage.databaseConnectType == .high {
            highConnect.readWithDataMessage(dataMessage, completionBlock)
        } else {
            normalConnect.readWithDataMessage(dataMessage, completionBlock)
        }
    }
    
    func writeWithDataMessage(_ dataMessage: DataMessage, _ completionBlock: DatabaseCompleteBlock) {
        normalConnect.writeWithDataMessage(dataMessage, completionBlock)
    }
    
    func asyncReadWithDataMessage(_ dataMessage: DataMessage, _ completionBlock: @escaping DatabaseCompleteBlock) {
        
        if dataMessage.databaseConnectType == .low {
            lowConnect.asyncReadWithDataMessage(dataMessage, completionBlock)
        } else if dataMessage.databaseConnectType == .high {
            highConnect.asyncReadWithDataMessage(dataMessage, completionBlock)
        } else {
            normalConnect.asyncReadWithDataMessage(dataMessage, completionBlock)
        }
    }
    
    func asyncWriteWithDataMessage(_ dataMessage: DataMessage, _ completionBlock: @escaping DatabaseCompleteBlock) {
        normalConnect.asyncWriteWithDataMessage(dataMessage, completionBlock)
    }
    
    
    lazy var normalConnect: DatabaseConnect = {
        let connect = DatabaseConnect(dbPath:dbPath, connectType: .normal)
        return connect
    }()
    
    lazy var lowConnect: DatabaseConnect = {
        let connect = DatabaseConnect(dbPath:dbPath, connectType: .low)
        return connect
    }()
    
    lazy var highConnect: DatabaseConnect = {
        let connect = DatabaseConnect(dbPath:dbPath, connectType: .high)
        return connect
    }()
    
    private static var defaultConfiguration: Configuration = {
        var config = Configuration()
        // 超时时间
        config.busyMode = Database.BusyMode.timeout(5.0)
        // 试图访问锁着的数据
        //configuration.busyMode = Database.BusyMode.immediateError
        config.qos = .default
        return config
    }()
    
    private static var lowConfiguration: Configuration = {
        var config = Configuration()
        // 超时时间
        config.busyMode = Database.BusyMode.timeout(5.0)
        // 试图访问锁着的数据
        //configuration.busyMode = Database.BusyMode.immediateError
        config.qos = .utility
        return config
    }()
    
    private static var highConfiguration: Configuration = {
        var config = Configuration()
        // 超时时间
        config.busyMode = Database.BusyMode.timeout(5.0)
        // 试图访问锁着的数据
        //configuration.busyMode = Database.BusyMode.immediateError
        config.qos = .userInteractive
        
        return config
    }()
}
