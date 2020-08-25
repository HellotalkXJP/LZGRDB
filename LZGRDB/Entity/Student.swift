//
//  Student.swift
//  DatabaseDemo
//
//  Created by Mac on 2020/8/7.
//  Copyright © 2020 Mac. All rights reserved.
//

import Foundation
import GRDB

struct Student: Codable {
    static let tableName = "student"
    
    /// 自增ID
    var id: NSInteger?
    /// 名字
    var name: String?
    /// 昵称id
    var nick_name: String?
    /// 年龄
    var age: Int?
    /// 性别
    var gender: Int?
    
    /// 设置行名
    private enum Columns: String, CodingKey, ColumnExpression {
        case id
        /// 名字
        case name
        /// 昵称
        case nick_name
        /// 年龄
        case age
        /// 性别
        case gender
    }
}
 
