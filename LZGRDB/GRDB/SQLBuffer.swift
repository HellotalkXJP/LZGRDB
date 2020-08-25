//
//  SQLBuffer.swift
//  DatabaseDemo
//
//  Created by Mac on 2020/8/11.
//  Copyright © 2020 Mac. All rights reserved.
//

import Foundation
import GRDB

typealias SQLBufferBlockV = () -> SQLBuffer
typealias SQLBufferBlockS = (_ string: String) -> SQLBuffer
typealias SQLBufferBlockSS = (_ string1: String, _ string2: String) -> SQLBuffer
typealias SQLBufferBlockU = (_ value: UInt) -> SQLBuffer
typealias SQLBufferBlockKV = (_ key: String, _ value: DatabaseValueConvertible) -> SQLBuffer

// 多参数
typealias SQLBufferBlockVaList = (_ params: String...) -> SQLBuffer

/// sql语句构造类
class SQLBuffer: NSObject {
    // 使用参数化（避免构造sql语句时，某些特殊字符导致sql语句异常，执行sql失败）
    var useArguments = false
    var distinct = false
    
    private var insert: String?
    private var delete: String?
    private var update: String?
    private var replace: String?
    
    private var sqlString: String
    private var sqlBindingString = ""
    private var set = Dictionary<String, DatabaseValueConvertible?>()
    private var set2 = Dictionary<String, DatabaseValueConvertible?>()
    
    private var select = ""
    private var from = ""
    private var whereStr = ""
    private var groupby = ""
    private var orderby = ""
    private var limit: UInt?
    private var offset: UInt?
    
    // MARK: readonly，暴露给外部使用
    var sql: String {
        if sqlString.count > 0 {
            return sqlString
        }
        
        if let _ = insert {
            return insertString()
        } else if let _ = replace {
            return replaceString()
        } else if let _ = delete {
            return deleteString()
        } else if let _ = update {
            return updateString()
        } else {
            return selectString()
        }
    }
    
    var sql2: String {
        if sqlBindingString.count > 0 {
            return sqlBindingString
        }
        
        if let _ = insert {
            return insertBindingString()
        } else if let _ = replace {
            return replaceBindingString()
        } else if let _ = update {
            return updateBindingString()
        } else {
            return ""
        }
    }
    
    var parameterDictionary: Dictionary<String, DatabaseValueConvertible?> {
        let dict = set2
        return dict
    }
    
    var INSERT: SQLBufferBlockS {
        let block = { (_ string: String) -> SQLBuffer in
            self.insert = string.uppercased()
            return self
        }
        return block
    }
    
    var DELETE: SQLBufferBlockS {
        let block = { (_ string: String) -> SQLBuffer in
            self.delete = string.uppercased()
            return self
        }
        return block
    }
    
    var UPDATE: SQLBufferBlockS {
        let block = { (_ string: String) -> SQLBuffer in
            self.update = string.uppercased()
            return self
        }
        return block
    }
    
    var REPLACE: SQLBufferBlockS {
        let block = { (_ string: String) -> SQLBuffer in
            self.replace = string.uppercased()
            return self
        }
        return block
    }
    
    var SELECT: SQLBufferBlockS {
        let block = { (_ string: String) -> SQLBuffer in
            self.select.append(string)
            return self
        }
        return block
    }
    
    var SELECT_S: SQLBufferBlockVaList {
        let block = { (_ params: String...) -> SQLBuffer in
            var array = [String]()

            params.forEach { (string) in
                array.append(string)
            }
            
            self.select.append(array.joined(separator: ","))
            return self
        }
        return block
    }
    
    var FROM: SQLBufferBlockS {
        let block = { (_ string: String) -> SQLBuffer in
            self.from.append(string)
            return self
        }
        return block
    }
    
    var FROM_S: SQLBufferBlockVaList {
        let block = { (_ params: String...) -> SQLBuffer in
            var array = [String]()

            params.forEach { (string) in
                array.append(string)
            }
            
            self.from.append(array.joined(separator: ","))
            return self
        }
        return block
    }
    
    var WHERE: SQLBufferBlockS {
        let block = { (_ string: String) -> SQLBuffer in
            if self.whereStr.count > 0 {
                self.whereStr.append(" AND \(string)")
            } else {
                self.whereStr.append(string)
            }
            
            return self
        }
        return block
    }
    
    var AND: SQLBufferBlockS {
        let block = { (_ string: String) -> SQLBuffer in
            if self.whereStr.count > 0 {
                self.whereStr.append(" AND \(string)")
            } else {
                self.whereStr.append(" \(string)")
            }
            
            return self
        }
        return block
    }
    
    var OR: SQLBufferBlockS {
        let block = { (_ string: String) -> SQLBuffer in
            if self.whereStr.count > 0 {
                self.whereStr.append(" OR \(string)")
            } else {
                self.whereStr.append(" \(string)")
            }
            
            return self
        }
        return block
    }
    
    var SET: SQLBufferBlockKV {
        let block = { (_ key: String, _ value: DatabaseValueConvertible) -> SQLBuffer in
            let storage = value.databaseValue.storage
                
            switch storage {
            case .null:
                self.set[key] = ""
            case .int64(let int64):
                self.set[key] = "\(int64)"
            case .double(let double):
                self.set[key] = "\(double)"
            case .string(let string):
                self.set[key] = "'\(string)'"
            case .blob(let data):
                self.set[key] = data
            }
        
            self.set2[key] = value
            
            return self
        }
        
        return block
    }
    
    var GROUPBY: SQLBufferBlockS {
        let block = { (_ string: String) -> SQLBuffer in
            self.groupby.append(string)
            return self
        }
        return block
    }
    
    var ORDERBY: SQLBufferBlockSS {
        let block = { (_ string1: String, _ string2: String) -> SQLBuffer in
            self.orderby.append(String(format: "%@ %@", string1, string2))
            return self
        }
        
        return block
    }
    
    var LIMIT: SQLBufferBlockU {
        let block = { (_ value: UInt) -> SQLBuffer in
            self.limit = value
            return self
        }
        return block
    }
    
    var OFFSET: SQLBufferBlockU {
        let block = { (_ value: UInt) -> SQLBuffer in
            self.offset = value
            return self
        }
        return block
    }
    
    override init() {
        sqlString = ""
        super.init()
    }
    
    convenience init(sql: String) {
        self.init()
        sqlString = sql
    }
    
    private func insertString() -> String {
        var sql = ""
        if let insert = insert {
            let set = self.set
            sql.append("INSERT INTO \(insert) ")
            
            var keys = "("
            var values = "VALUES ("
            var index = 0
            
            for (key, value) in set {
                if index == 0 {
                    keys.append(key)
                    values = values.appendingFormat("%@", value as? CVarArg ?? "")
                } else {
                    keys.append(", " + key)
                    values = values.appendingFormat(", %@", value as? CVarArg ?? "")
                }
                
                index += 1
            }
            
            keys.append(")")
            values.append(")")
            
            sql.append(keys + " " + values)
        }
        
        return sql
    }
    
    private func replaceString() -> String {
        var sql = ""
        if let replace = replace {
            let set = self.set
            sql.append("REPLACE INTO \(replace) ")
            
            var keys = "("
            var values = "VALUES ("
            var index = 0
            
            for (key, value) in set {
                if index == 0 {
                    keys.append(key)
                    values = values.appendingFormat("%@", value as? CVarArg ?? "")
                } else {
                    keys.append(", " + key)
                    values = values.appendingFormat(", %@", value as? CVarArg ?? "")
                }
                
                index += 1
            }
            
            keys.append(")")
            values.append(")")
            
            sql.append(keys + " " + values)
        }
        
        return sql
    }
    
    private func deleteString() -> String {
        var sql = ""
        if let delete = delete {
            let deleteSql = "DELETE FROM \(delete)"
            if self.whereStr.count <= 0 {
                debugPrint("删除表\(delete) 没有条件")
                
                return deleteSql
            }
            
            sql.append(deleteSql)
            
            sql.append(" WHERE \(self.whereStr)")
        }
        return sql
    }
    
    private func updateString() -> String {
        var sql = ""
        if let update = update {
            let set = self.set
            sql.append("UPDATE \(update) SET ")
            
            var index = 0
            
            for (key, value) in set {
                if index == 0 {
                    sql = sql.appendingFormat("%@ = %@", key, value as? CVarArg ?? "")
                } else {
                    sql = sql.appendingFormat(", %@ = %@", key, value as? CVarArg ?? "")
                }
                
                index += 1
            }
            
            if self.whereStr.count > 0 {
                sql.append(" WHERE \(self.whereStr)")
            }
        }
        
        return sql
    }
    
    private func selectString() -> String {
        var sql = ""
        if distinct {
            sql.append("SELECT DISTINCT ")
        } else {
            sql.append("SELECT ")
        }
        
        sql.append(select)
        sql.append(" FROM ")
        sql.append(from)
        
        if whereStr.count > 0 {
            sql.append(" WHERE \(whereStr)")
        }
        
        if groupby.count > 0 {
            sql.append(" GROUP BY \(groupby)")
        }
        
        if orderby.count > 0 {
            sql.append(" ORDER BY \(orderby)")
        }
        
        if let limit = limit {
            if let offset = offset {
                sql.append(" LIMIT \(offset), \(limit)")
            } else {
                sql.append(" LIMIT \(limit)")
            }
        }
        
        return sql
    }
    
    private func insertBindingString() -> String {
        var sql = ""
        
        if let insert = insert {
            let set = self.set
            sql.append("INSERT INTO \(insert) ")
            
            var keys = "("
            var values = "VALUES ("
            var index = 0
            
            for (key, _) in set {
                if index == 0 {
                    keys.append(key)
                    values = values.appendingFormat(":%@", key)
                } else {
                    keys.append(", " + key)
                    values = values.appendingFormat(", :%@", key)
                }
                
                index += 1
            }
            
            keys.append(")")
            values.append(")")
            
            sql.append(keys + " " + values)
        }
        
        return sql
    }
    
    private func updateBindingString() -> String {
        var sql = ""
        if let update = update {
            let set = self.set
            sql.append("UPDATE \(update) SET ")
            
            var index = 0
            
            for (key, _) in set {
                if index == 0 {
                    sql = sql.appendingFormat("%@ = :%@", key, key)
                } else {
                    sql = sql.appendingFormat(", %@ = :%@", key, key)
                }
                
                index += 1
            }
            
            if self.whereStr.count > 0 {
                sql.append(" WHERE \(self.whereStr)")
            }
        }
        
        return sql
    }
    
    private func replaceBindingString() -> String {
        var sql = ""
        if let replace = replace {
            let set = self.set
            sql.append("REPLACE INTO \(replace) ")
            
            var keys = "("
            var values = "VALUES ("
            var index = 0
            
            for (key, _) in set {
                if index == 0 {
                    keys.append(key)
                    values = values.appendingFormat(":%@", key)
                } else {
                    keys.append(", " + key)
                    values = values.appendingFormat(", :%@", key)
                }
                
                index += 1
            }
            
            keys.append(")")
            values.append(")")
            
            sql.append(keys + " " + values)
        }
        
        return sql
    }
    
    override var description: String {
        if useArguments {
            return sql2
        } else {
            return sql
        }
    }
}

extension SQLBuffer {
    func SQLFieldEqual(_ field1: String, _ value: Any) -> String {
        return "\(field1)=\(value)"
    }

    func SQLStringEqual(_ field: String, _ value: String) -> String {
        return "\(field)='\(value)'"
    }

    func SQLFieldNotEqual(_ field: String, _ value: Any) -> String {
        return "\(field)!=\(value)"
    }

    func SQLNumberEqual(_ field: String, _ value: Any) -> String {
        return "\(field)=\(value)"
    }
}
