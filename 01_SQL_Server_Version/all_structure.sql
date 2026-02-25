-- Create database with custom filegroups
CREATE DATABASE EX_SYS
ON PRIMARY
(
    NAME = 'Ex_sys_main',
    FILENAME = 'D:\ITI campaign\ITI content\Database_fundamentals\final_project\database\demo\f_group MAIN\Ex_sys_main.mdf',
    SIZE = 100MB,
    MAXSIZE = UNLIMITED,
    FILEGROWTH = 50MB
),
FILEGROUP FG_usrs
(
    NAME = 'Ex_sys_usrs',
    FILENAME = 'D:\ITI campaign\ITI content\Database_fundamentals\final_project\database\demo\f_group users\Ex_sys_usrs.ndf',
    SIZE = 50MB,
    MAXSIZE = 500MB,
    FILEGROWTH = 50MB
),
FILEGROUP FG_Exams
(
    NAME = 'Ex_sys_exams',
    FILENAME = 'D:\ITI campaign\ITI content\Database_fundamentals\final_project\database\demo\f_group exams\Ex_sys_exams.ndf',
    SIZE = 100MB,
    MAXSIZE = 1GB,
    FILEGROWTH = 50MB
)
LOG ON
(
    NAME = 'Ex_sys_logs',
    FILENAME = 'E:\f_group logs\Ex_sys_logs.ldf',
    SIZE = 50MB,
    MAXSIZE = 500MB,
    FILEGROWTH = 25MB
);
GO




--creation of the table and the constraints
USE EX_SYS;
GO

--1

CREATE TABLE [user] --between square bracket because user defined in dbms
(

usr_id  INT  IDENTITY (1,1) PRIMARY KEY,
usr_name  nvarchar(50) NOT NULL UNIQUE,
pass_hash nvarchar(max),
Role varchar(50) NOT NULL CHECK (Role IN  ('admin','student','training manager','instructor')),
is_active  BIT NOT NULL DEFAULT 1,
created_date DATETIME DEFAULT GETDATE()

) ON FG_usrs


--2

CREATE TABLE track 
(

TR_ID INT  IDENTITY (1,1) PRIMARY KEY,
TR_NAME varchar(100) NOT NULL,
TR_DES varchar(100)
) ON [PRIMARY]



CREATE TABLE branch 
(
BR_ID INT IDENTITY (1,1) PRIMARY KEY,
BR_NAME varchar(100) NOT NULL,
BR_LOC varchar(100)
) ON [PRIMARY]





CREATE TABLE branch_track 
(
BR_ID INT NOT NULL, 
TR_ID INT NOT NULL,
ST_DATE DATE,
CONSTRAINT p1_BRANCH_TRACK PRIMARY KEY (BR_ID,TR_ID),
CONSTRAINT C1_BRANCH FOREIGN KEY (BR_ID) REFERENCES branch (BR_ID),
CONSTRAINT C1_TRACK FOREIGN KEY (TR_ID) REFERENCES track (TR_ID)
)ON [PRIMARY]





CREATE TABLE intake
(

IN_ID INT IDENTITY (1,1) PRIMARY KEY,
IN_NAME varchar(50) NOT NULL,
IN_year INT,
BR_ID INT NOT NULL, 
TR_ID INT NOT NULL,
CONSTRAINT FK_Intake_BranchTrack
        FOREIGN KEY (BR_ID, TR_ID)
        REFERENCES branch_Track(BR_ID, TR_ID)
)ON [PRIMARY]



--3
CREATE TABLE student
(
STD_ID INT IDENTITY (1,1) PRIMARY KEY,
USR_ID INT NOT NULL UNIQUE FOREIGN KEY (USR_ID) REFERENCES [user](USR_ID),
STD_NAME VARCHAR(100) NOT NULL,
STD_EMAIL VARCHAR(100) NOT NULL UNIQUE,
STD_PHONE VARCHAR(20),
STD_ADD VARCHAR(200),
DOB DATE,
IN_ID INT NOT NULL FOREIGN KEY (IN_ID) REFERENCES intake(IN_ID)
)ON FG_usrs



CREATE TABLE instructor
(
INS_ID INT IDENTITY(1,1) PRIMARY KEY,
Usr_ID INT NOT NULL UNIQUE FOREIGN KEY (usr_ID) REFERENCES [user](usr_ID),
INS_NAME VARCHAR(100) NOT NULL,
INS_EMAIL VARCHAR(100) NOT NULL UNIQUE,
INS_PHONE VARCHAR(20) ,
Hire_Date DATE ,
Salary DECIMAL(10,2) 
) ON FG_usrs





CREATE TABLE training_manager
(
MGR_ID INT IDENTITY(1,1) PRIMARY KEY,
Usr_ID INT NOT NULL UNIQUE FOREIGN KEY (Usr_ID) REFERENCES [user](usr_ID),
MGR_NAME VARCHAR(100) NOT NULL,
MGR_EMAIL VARCHAR(100) UNIQUE,
MGR_PHONE VARCHAR(20) NULL
) ON FG_usrs


--4

CREATE TABLE course
(

CRS_ID INT IDENTITY(1,1) PRIMARY KEY,
CRS_NAME VARCHAR(100) NOT NULL,
CRS_DESC VARCHAR(500) ,
Max_Degree INT NOT NULL,
Min_Degree INT NOT NULL,
CONSTRAINT CHK_Course_Degrees CHECK (Min_Degree < Max_Degree)
)ON [PRIMARY]




CREATE TABLE instructor_Course
(
INS_ID INT NOT NULL FOREIGN KEY (INS_ID) REFERENCES Instructor(INS_ID),
CRS_ID INT NOT NULL FOREIGN KEY (CRS_ID) REFERENCES Course(CRS_ID),
IN_ID INT NOT NULL FOREIGN KEY (IN_ID) REFERENCES Intake(IN_ID),
CONSTRAINT PK_Instructor_Course PRIMARY KEY (INS_ID, CRS_ID, IN_ID)
) ON [PRIMARY]



--5





CREATE TABLE exam
(
EX_ID INT IDENTITY(1,1) PRIMARY KEY,
EX_TYPE VARCHAR(20) NOT NULL CHECK (EX_TYPE IN ('Exam', 'Corrective')),
CRS_ID INT NOT NULL FOREIGN KEY (CRS_ID) REFERENCES Course(CRS_ID),
INS_ID INT NOT NULL FOREIGN KEY (INS_ID) REFERENCES instructor(INS_ID),
IN_ID INT NOT NULL FOREIGN KEY (IN_ID) REFERENCES Intake(IN_ID),
EX_DATE DATE NOT NULL,
Start_Time TIME NOT NULL,
End_Time TIME NOT NULL,
Total_Time INT NOT NULL, --will get it into minuts
Total_Degree INT NOT NULL,
Year INT NOT NULL,
Allowance_Options VARCHAR(200) NULL,
CHECK (End_Time > Start_Time)
) ON FG_Exams;



CREATE TABLE question
(
Q_ID INT IDENTITY(1,1) PRIMARY KEY,
Q_TEXT VARCHAR(MAX) NOT NULL,
Q_TYPE VARCHAR(20) NOT NULL CHECK (Q_TYPE IN ('MCQ', 'TrueFalse', 'Text')),
Correct_Answer VARCHAR(MAX) ,
CRS_ID INT NOT NULL FOREIGN KEY (CRS_ID) REFERENCES course(CRS_ID),
Created_By INT NOT NULL FOREIGN KEY (Created_By) REFERENCES instructor(INS_ID),
Created_Date DATETIME NOT NULL DEFAULT GETDATE()
) ON [PRIMARY];


CREATE TABLE Exam_Question
(
EX_ID INT NOT NULL FOREIGN KEY (EX_ID) 
    REFERENCES exam(EX_ID) ON DELETE CASCADE,
Q_ID INT NOT NULL FOREIGN KEY (Q_ID) 
    REFERENCES question(Q_ID),
Q_DEGREE INT NOT NULL,
CONSTRAINT PK_Exam_Question PRIMARY KEY (EX_ID, Q_ID)
) ON FG_Exams;


--6







CREATE TABLE Question_Choices
(
    CH_ID INT IDENTITY(1,1) PRIMARY KEY,
    Q_ID INT NOT NULL FOREIGN KEY (Q_ID) 
        REFERENCES Question(Q_ID) ON DELETE CASCADE,
    Choice_Text VARCHAR(500) NOT NULL,
    Choice_Order CHAR(1) NOT NULL,
    CONSTRAINT UQ_Question_Choice UNIQUE (Q_ID, Choice_Order)
) ON [PRIMARY];







--7
CREATE TABLE Student_Exam
(
STD_ID INT NOT NULL FOREIGN KEY (STD_ID) REFERENCES Student(STD_ID),
EX_ID INT NOT NULL FOREIGN KEY (EX_ID) REFERENCES Exam(EX_ID),
Actual_Start_Time DATETIME ,
Actual_End_Time DATETIME ,
Total_Score DECIMAL(5,2) ,
Obtained_Degree DECIMAL(5,2) ,
CONSTRAINT PK_Student_Exam PRIMARY KEY (STD_ID, EX_ID)
) ON FG_Exams;


CREATE TABLE Student_Answer
(
    ANS_ID INT IDENTITY(1,1) PRIMARY KEY,
    STD_ID INT NOT NULL FOREIGN KEY (STD_ID) REFERENCES student(STD_ID),
    EX_ID INT NOT NULL FOREIGN KEY (EX_ID) REFERENCES exam(EX_ID),
    Q_ID INT NOT NULL FOREIGN KEY (Q_ID) REFERENCES question(Q_ID),
    Student_Answer VARCHAR(MAX) ,
    Is_Correct BIT , -- NULL for text questions
    Obtained_Marks DECIMAL(5,2) ,
    ANS_At DATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_StudentAnswer_StudentExam FOREIGN KEY (STD_ID, EX_ID) 
        REFERENCES Student_Exam(STD_ID, EX_ID),
    CONSTRAINT UQ_StudentExamQuestion UNIQUE (STD_ID, EX_ID, Q_ID) -- Prevent duplicate answers of the same student same exam same qquestion single answer
) ON FG_Exams;



--VERFICATION
SELECT 
    TABLE_SCHEMA,
    TABLE_NAME,
    TABLE_TYPE
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE'
ORDER BY TABLE_NAME;
GO

PRINT 'Database structure created successfully!'; --those will appear in messages window ;)
PRINT 'Total tables created: 16';