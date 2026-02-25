/*
all the tables have clustered indexes that has been created previously
by their primary key.
*/

-- if you want to show all indexes in a certain table 

sp_helpindex Student;--table name





--now we want to add some indexes to speed up some operations (search) but not over it
--so we choose the most frequent data reterival operations
USE EX_SYS;
GO

-- login :when the user login it searches the input user name to compare it with the stored to database
--(default creation of indexes will be the non clustered type)
CREATE INDEX Indx_Username 
    ON [user](usr_name);




--verfication
SELECT usr_id, pass_hash, role
FROM [user]
WHERE usr_name = 'ahmed';




--i can drop them if i want :
DROP INDEX Indx_Username ON [user];




-- for Show all questions created by the instructor query
CREATE INDEX Indx_Q_CreatedBy 
    ON question(Created_By);






--verfication
SELECT Q_ID, Q_TEXT, Q_TYPE
FROM question
WHERE Created_By = 5;



-- for Show all students enrolled in exam by the instructor query
CREATE INDEX IX_StudentExam_Exam 
    ON Student_Exam(EX_ID);



--verfication
SELECT s.STD_ID, s.STD_NAME
FROM Student_Exam se
JOIN Student s 
    ON se.STD_ID = s.STD_ID
WHERE se.EX_ID = 10;






-- for What courses does this instructor teach? query
CREATE INDEX IX_InstructorCourse_Instructor 
    ON Instructor_Course(INS_ID);



--verfication
SELECT c.CRS_NAME
FROM Instructor_Course ic
JOIN Course c 
    ON ic.CRS_ID = c.CRS_ID
WHERE ic.INS_ID = 3;




-- for Show all exams for this course query
CREATE INDEX IX_Exam_Course 
    ON exam(CRS_ID);



--verfication
SELECT *
FROM exam
WHERE CRS_ID = 5
SET STATISTICS TIME ON



