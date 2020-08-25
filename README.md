# LZGRDB
基于sql在GRDB的基础上封装一层以及自定义构造SQL语句的buffer，直接操作sql，目前只支持在swift项目中使用，支持OC后期在完善。

## 安装LZGRDB
**Cocoapods**
```
1. 在 Podfile 中添加 `pod 'LZGRDB'`
2. 执行 `pod install` 或 `pod update`
```

**手动安装**
```
1. 下载 LZGRDB/GRDB 文件夹内的所有内容。
2. 将 LZGRDB文件夹添加(拖放)到你的工程。
```
## 使用方法

#### 创建数据库

##### `DatabaseInterface`
* func setDatabase(dbName: String = "default.sqlite", dbPath: String = NSHomeDirectory() + "/Documents/")
设置数据库路径以及数据库名字

`dbName` 数据库的名称 如: @"Users.sqlite", 如果dbName = nil,则默认dbName=@"default.sqlite"
`dbPath` 数据库的路径, 如果dbPath = nil, 则路径默认NSHomeDirectory() + "/Documents/"

```
// 初始化数据库
let interface = DatabaseInterface.sharedInterface
interface.setDatabase()
或
let interface = DatabaseInterface.sharedInterface
interface.setDatabase(dbName: "user.sqlite", dbPath: FilePath.userPathWith(userId: userId))
注意：如果自定义路径下有中间路径的话，则需要先创建中间路径
```
##### `GRDBManager`
* init(dbName: String, path: String)
在初始化方法中，会先判断是否有数据库，没有的话，则会默认找到资源文件中的defaultSql.sql文件，然后执行里面的sql语句。

* private static var defaultConfiguration: Configuration
数据库的基础配置

* lazy var dbQueue: DatabaseQueue
数据库用于多线程事务处理

* private var migrator: DatabaseMigrator
数据库数据升级/迁移处理

* func executeDataMessage(_ message: inout DataMessage) --提供外部调用的方法
通过外部传过来的message对象，来执行sql语句。判断sync进行同步/异步操作。执行数据库操作之后的结果写入message对象中。

##### `DatabaseService`
主要是根据message对象中的连接类型判断放在不同优先级的队列中

##### `DatabaseConnect`
连接数据库，在不同的队列中执行SQL语句操作

##### `SQLBuffer`
sql语句构造类
* convenience init(sql: String)
直接传入sql语句

* override init()
另一种懒人方式构造sql，先初始化，然后通过链式语法的方式构造sql
```
let insert = SQLBuffer().INSERT("student").SET("name", "insert1").SET("nick_name", "test1111").SET("age", 10.1).SET("gender", 0)
debugPrint("insert sql1: \(insert.description)")
// "insert sql1: INSERT INTO STUDENT (gender, nick_name, name, age) VALUES (0, \'test1111\', \'insert1\', 10.1)"

let replace = SQLBuffer().REPLACE("student").SET("id", 26).SET("name", "replace").SET("nick_name", "replace2").SET("age", 10.5).SET("gender", 1)
debugPrint("replace sql1: \(replace.description)")
// "replace sql1: REPLACE INTO STUDENT (gender, name, nick_name, id, age) VALUES (1, \'replace\', \'replace2\', 26, 10.5)"

let delete = SQLBuffer().DELETE("student").WHERE("name = 'test'").OR("nick_name = 'test1111'")
debugPrint("delete sql: \(delete.description)")
// "delete sql: DELETE FROM STUDENT WHERE name = \'test\' OR nick_name = \'test1111\'"

let update = SQLBuffer().UPDATE("student").SET("nick_name", "update_nick_name").SET("age", 1000).WHERE("name = 'insert1'").OR("nick_name = 'update'")
debugPrint("update sql1: \(update.description)")
// "update sql1: UPDATE STUDENT SET nick_name = \'update_nick_name\', age = 1000 WHERE name = \'insert1\' OR nick_name = \'update\'"

let select = SQLBuffer().SELECT("name, age").FROM("student").WHERE("name = 'xxxxx'").AND("nick_name = 'xxxxx'").OR("xxx = 'xxx'").GROUPBY("name,age").LIMIT(5).OFFSET(3).ORDERBY("age", "ASC")
debugPrint("select sql: \(select.description)")
// "select sql: SELECT name, age FROM student WHERE name = \'xxxxx\' AND nick_name = \'xxxxx\' OR xxx = \'xxx\' GROUP BY name,age ORDER BY age ASC LIMIT 3, 5"

insert.useArguments = true
debugPrint("insert sql2: \(insert.description)")
// "insert sql2: INSERT INTO STUDENT (gender, nick_name, name, age) VALUES (:gender, :nick_name, :name, :age)"

```
#### `DataMessage`
该类是贯穿全文的一个类，以下是该类中的一些成员变量的说明
```
// 是否已经返回数据库执行结果
var responded = false

// 是否是同步
var sync = false

// 数据库操作sql语句
var sqlBuffer: SQLBuffer?

// 数据库批量操作sql语句
var mutableSqlBuffer: MutableSQLBuffer?

// 业务逻辑类型
var logicType: DatabaseLogicType = .null

// 数据库操作类型
var operationType: DatabaseOperationType = .query

// 数据库连接类型
var databaseConnectType: DatabaseConnectType = .normal

// 数据库操作结果
var resultSet: DataBaseResultSet?

// 消息唯一标识
var identifier: String = ""

// 是否批量操作
private var batch = false

```
* init(withSQLBuffer sqlBuffer: SQLBuffer)
初始化方法
* init(withMutalbeSQLBuffer mutableSQLBuffer: MutableSQLBuffer)
批量sql初始化方法

#### 使用
具体使用方法放在了`SceneDelegate.swift`中，大家可以看下。

#### Thanks
--- 
LZGRDB都已经放在了[我的GitHub](https://github.com/HellotalkXJP/LZGRDB)上，我这里只用到了GRDB部分小功能，代码写的比较简单，容易看的懂。其实GRDB里面的功能是很强大的，可以直接对象操作，具体的可以看[GRDB官方文档](https://github.com/groue/GRDB.swift)的使用说明。
