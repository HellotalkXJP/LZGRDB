//
//  Player.swift
//  DatabaseDemo
//
//  Created by Mac on 2020/8/13.
//  Copyright © 2020 Mac. All rights reserved.
//

import Foundation
import GRDB

struct Player: Codable {
    static let tableName = "player"
    
    /// 名字
    var name: String?
    /// 分数
    var score: String?
    
    /// 设置行名
    private enum Columns: String, CodingKey, ColumnExpression {
        /// 名字
        case name = "NAME"
        /// 分数
        case score = "SCORE"
    }
}
