//
//  AppDelegate.swift
//  LZGRDB
//
//  Created by Mac on 2020/8/20.
//  Copyright © 2020 Mac. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
//        testSqlBuffer()
        
        return true
    }

    func testSqlBuffer() {
            let insert = SQLBuffer().INSERT("student").SET("name", "insert1").SET("nick_name", "test1111").SET("age", 10.1).SET("gender", 0)
            debugPrint("insert sql1: \(insert.description)")
            
            let replace = SQLBuffer().REPLACE("student").SET("id", 26).SET("name", "replace").SET("nick_name", "replace2").SET("age", 10.5).SET("gender", 1)
            debugPrint("replace sql1: \(replace.description)")

            let delete = SQLBuffer().DELETE("student").WHERE("name = 'test'").OR("nick_name = 'test1111'")
            debugPrint("delete sql: \(delete.description)")

            let update = SQLBuffer().UPDATE("student").SET("nick_name", "update_nick_name").SET("age", 1000).WHERE("name = 'insert1'").OR("nick_name = 'update'")
            debugPrint("update sql1: \(update.description)")

            let select = SQLBuffer().SELECT("name, age").FROM("student").WHERE("name = 'xxxxx'").AND("nick_name = 'xxxxx'").OR("xxx = 'xxx'").GROUPBY("name,age").LIMIT(5).OFFSET(3).ORDERBY("age", "ASC")
            debugPrint("select sql: \(select.description)")

            let userId = "test"
            let dbPath: String = FilePath.userPathWith(userId: userId)
            let interface = DatabaseInterface.sharedInterface
            // 初始化数据库
            interface.setDatabase(dbName: userId + ".sqlite", dbPath: dbPath)
            
            var insertMessage = DataMessage.init(withSQLBuffer: insert)
            insertMessage.responded = false
            insertMessage.operationType = .insert
            insertMessage.logicType = .insertUser
            insertMessage.sync = true
            insertMessage.databaseConnectType = .high
            interface.executeDataMessage(&insertMessage)
            print(">>>>>>>>>>>========<<<<<<<<<< \n同步插入数据结果: \(insertMessage.responded) \ncode:\(insertMessage.resultSet?.resultCode ?? DatabaseResult.failed)")
            
            var replaceMessage = DataMessage.init(withSQLBuffer: replace)
            replaceMessage.responded = false
            replaceMessage.operationType = .insert
            replaceMessage.sync = true
            replaceMessage.databaseConnectType = .high
            interface.executeDataMessage(&replaceMessage)
            
            var updateMessage = DataMessage.init(withSQLBuffer: update)
            updateMessage.responded = false
            updateMessage.operationType = .update
            insertMessage.logicType = .updateUser
            updateMessage.sync = true
            updateMessage.databaseConnectType = .high
    //        interface.executeDataMessage(&updateMessage)
            
            var deleteMessage = DataMessage.init(withSQLBuffer: delete)
            deleteMessage.responded = false
            deleteMessage.operationType = .delete
            insertMessage.logicType = .deleteUser
            deleteMessage.sync = true
            deleteMessage.databaseConnectType = .high
    //        interface.executeDataMessage(&deleteMessage)
            
            let sqlBuffer = SQLBuffer(sql: "SELECT * FROM student")
            let sqlBuffer2 = SQLBuffer(sql: "SELECT * FROM student")
            let sqlBuffer3 = SQLBuffer(sql: "SELECT * FROM student")
            let sqlBuffer4 = SQLBuffer(sql: "SELECT * FROM student")
            let sqlBuffer5 = SQLBuffer().SELECT("*").FROM("student")
            debugPrint("update sql1: \(sqlBuffer5.description)")
            
            let sqlBuffers = MutableSQLBuffer()
            sqlBuffers.addBuffer(sqlBuffer)
            sqlBuffers.addBuffer(sqlBuffer2)
            sqlBuffers.addBuffer(sqlBuffer3)
            sqlBuffers.addBuffer(sqlBuffer4)

            var message = DataMessage.init(withSQLBuffer: sqlBuffer5)
            message.responded = false
            message.operationType = .query
            message.logicType = .queryUser
            message.sync = false
            message.databaseConnectType = .high
            // 异步操作需要设置代理,回调数据（这里不采用block方式是因为每次操作都需要在block里逻辑处理，这样的话会不叫不方便，使用代理的话，所有的操作在代理方法里面统一处理，只需要判断操作的业务类型）
            interface.interfaceDelegate = self
            interface.executeDataMessage(&message)
            
            print(">>>>>>>>>>>========<<<<<<<<<< \n查询结果1: \(message.resultSet?.resultCode ?? DatabaseResult.failed) \n\(Thread.current) \n\(message.resultSet?.resultArray ?? ["无数据"])")
            
            insert.useArguments = true
            debugPrint("insert sql2: \(insert.description)")

            update.useArguments = true
            debugPrint("update sql2: \(update.description)")

            replace.useArguments = true
            debugPrint("replace sql2: \(replace.description)")
        }
        
        func testSql() {
            let userId = "test"
            let dbPath: String = FilePath.userPathWith(userId: userId)
            let interface = DatabaseInterface.sharedInterface
            interface.setDatabase(dbName: userId + ".sqlite", dbPath: dbPath)
            let insert = SQLBuffer(sql: "INSERT into student(name, nick_name, age, gender) VALUES('测试1111', '测试昵称221', 22, 1)")
            
    //        insert = SQLBuffer(sql: "UPDATE student set name = 'xxxx', nick_name = 'bbbbb' where name like '%测试%'")
            
            var insertMessage = DataMessage.init(withSQLBuffer: insert)
            insertMessage.responded = false
            insertMessage.operationType = .insert
            insertMessage.sync = true
            insertMessage.databaseConnectType = .high
            interface.executeDataMessage(&insertMessage)
            
            
            let sqlBuffer = SQLBuffer(sql: "SELECT * FROM student")
            let sqlBuffer2 = SQLBuffer(sql: "SELECT * FROM student")
            let sqlBuffer3 = SQLBuffer(sql: "SELECT * FROM student")
            let sqlBuffer4 = SQLBuffer(sql: "SELECT * FROM student")
            let sqlBuffers = MutableSQLBuffer()
            sqlBuffers.addBuffer(sqlBuffer)
            sqlBuffers.addBuffer(sqlBuffer2)
            sqlBuffers.addBuffer(sqlBuffer3)
            sqlBuffers.addBuffer(sqlBuffer4)

            var message = DataMessage.init(withSQLBuffer: sqlBuffer)
    //        message = DataMessage.init(withMutalbeSQLBuffer: sqlBuffers)
    //        message.operationType = .batchQuery
            
            message.responded = false
            message.operationType = .query
            message.sync = true
            message.databaseConnectType = .high
            
            interface.executeDataMessage(&message)

            debugPrint("查询结果1: \(message.resultSet?.resultCode ?? DatabaseResult.failed) \n\(Thread.current) \n\(message.resultSet?.resultArray ?? ["无数据"])")
            
            let delete = SQLBuffer(sql: "DELETE from student where name like '%xxxx%'")

            var deleteMessage = DataMessage.init(withSQLBuffer: delete)
            deleteMessage.responded = false
            deleteMessage.operationType = .delete
            deleteMessage.sync = true
            deleteMessage.databaseConnectType = .high
            interface.executeDataMessage(&deleteMessage)
            
            debugPrint(">>>>>>>>======<<<<<<<<")
            interface.executeDataMessage(&message)
            
            debugPrint("查询结果2: \(message.resultSet?.resultCode ?? DatabaseResult.failed) \n\(Thread.current) \n\(message.resultSet?.resultArray ?? ["无数据"])")
        }
    
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
}

extension AppDelegate: DatabaseInterfaceDelegate {
    func executeFinishWithDataMessage(_ message: DataMessage) {
        print("DatabaseInterface >>>\n\(Thread.current) \ncode: \(message.resultSet?.resultCode ?? DatabaseResult.failed) \nresult:\(message.resultSet?.resultArray ?? ["无数据"])")
        
        let logicType = message.logicType
        let code = message.resultSet?.resultCode ?? DatabaseResult.failed
        
        if message.responded && code == .success {
            switch logicType {
            case .insertUser:
                print("插入数据成功")
            case .deleteUser:
                print("删除数据成功")
            case .updateUser:
                print("更新数据成功")
            case .queryUser:
                print("查询数据成功")
            default:
                print("未知操作")
            }
        }
    }
}

class FilePath: NSObject {
    
    static func documentPath() -> String {
        let documentPaths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documnetPath = documentPaths[0]
        
        return documnetPath
    }
    
    static func userPathWith(userId: String) -> String {
        let path = FilePath.documentPath() + "/" + userId
        
        if !FileManager.default.fileExists(atPath: path) {
            try? FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
        }
        
        return path
    }
}
