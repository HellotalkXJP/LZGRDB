CREATE TABLE player (
id integer  NOT NULL PRIMARY KEY AUTOINCREMENT DEFAULT 0,
name TEXT NOT NULL,
score INT);

CREATE TABLE student (
id integer  NOT NULL PRIMARY KEY AUTOINCREMENT DEFAULT 0,
name TEXT NOT NULL,
nick_name TEXT,
age INT,
gender INT);
