//
//  DataMessage.swift
//  DatabaseDemo
//
//  Created by Mac on 2020/8/12.
//  Copyright © 2020 Mac. All rights reserved.
//

import Foundation

public enum DatabaseConnectType {
    case normal     // 正常读取连接
    case low        // 低优先级的读写连接，队列的优先级都是low
    case high       // 高优先级的读写连接，队列的优先级都是high
}

public enum DatabaseOperationType {
    case insert
    case delete
    case update
    case query
    case batchQuery   // 批量查询
}

public enum DatabaseLogicType {
    case null
    case insertUser
    case updateUser
    case deleteUser
    case queryUser
}

public class DataMessage: NSObject {
    // 是否已经返回数据库执行结果
    public var responded = false
    
    // 是否是同步
    public var sync = false
    
    // 数据库操作sql语句
    public var sqlBuffer: SQLBuffer?
    
    // 数据库批量操作sql语句
    public var mutableSqlBuffer: MutableSQLBuffer?
    
    // 业务逻辑类型
    public var logicType: DatabaseLogicType = .null
    
    // 数据库操作类型
    public var operationType: DatabaseOperationType = .query
    
    // 数据库连接类型
    public var databaseConnectType: DatabaseConnectType = .normal
    
    // 数据库操作结果
    public var resultSet: DataBaseResultSet?
    
    // 消息唯一标识
    public var identifier: String = ""
    
    // 是否批量操作
    private var batch = false
    
    public init(withSQLBuffer sqlBuffer: SQLBuffer) {
        self.sqlBuffer = sqlBuffer
        
        if sqlBuffer.sql.hasPrefix("INSERT") {
            operationType = .insert
        } else if sqlBuffer.sql.hasPrefix("DELETE") {
            operationType = .delete
        } else if sqlBuffer.sql.hasPrefix("UPDATE") || sqlBuffer.sql.hasPrefix("REPLACE") {
            operationType = .update
        } else if sqlBuffer.sql.hasPrefix("SELECT") {
            operationType = .query
        } else {
            operationType = .query
        }
        
        super.init()
    }
    
    public init(withMutalbeSQLBuffer mutableSQLBuffer: MutableSQLBuffer) {
        self.mutableSqlBuffer = mutableSQLBuffer
        self.batch = true
        if let sqlBuffer = mutableSQLBuffer.batchSqlBuffers.last {
            if sqlBuffer.sql.hasPrefix("INSERT") {
                operationType = .insert
            } else if sqlBuffer.sql.hasPrefix("DELETE") {
                operationType = .delete
            } else if sqlBuffer.sql.hasPrefix("UPDATE") || sqlBuffer.sql.hasPrefix("REPLACE") {
                operationType = .update
            } else if sqlBuffer.sql.hasPrefix("SELECT") {
                operationType = .query
            } else {
                operationType = .query
            }
        }
        
        super.init()
    }
    
    func batchSqls() -> [String]? {
        if batch {
            return mutableSqlBuffer?.batchSqls
        } else {
            return [sqlBuffer?.sql ?? ""]
        }
    }
    
    func batchSqlBuffers() -> [SQLBuffer]? {
        if batch {
            return mutableSqlBuffer?.batchSqlBuffers
        } else {
            if let sqlBuffer = sqlBuffer {
                return [sqlBuffer]
            }
        }
        
        return nil
    }
}
