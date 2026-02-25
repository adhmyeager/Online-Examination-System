--1. trigger: Validate Exam Total Degree
-- what: Ensure exam degree doesn't exceed course max
-- when: BEFORE INSERT or UPDATE on exam table
-- =====================================================

CREATE OR ALTER TRIGGER trg_ValidateExamDegree
ON exam
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Check if any inserted/updated exam exceeds course max
    IF EXISTS (
        SELECT 1 
        FROM inserted i
        JOIN course c ON i.CRS_ID = c.CRS_ID
        WHERE i.Total_Degree > c.Max_Degree
    )
    BEGIN
        RAISERROR('Exam total degree cannot exceed course maximum degree!', 16, 1);  ------„Â„ «ÊÌ Õ Â 1Ê16
        ROLLBACK TRANSACTION;
        RETURN;
    END
    
    PRINT 'Exam degree validated successfully.';
END
GO










-- 2. TRIGGER: Prevent Duplicate Student Answers
-- what: Ensure student doesn't answer same question twice
-- when: BEFORE INSERT on Student_Answer
-- Note: This is already handled by UNIQUE constraint, 
--       but trigger provides better error message
-- =====================================================

CREATE OR ALTER TRIGGER trg_PreventDuplicateAnswers
ON Student_Answer
INSTEAD OF INSERT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Check for duplicates
    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN Student_Answer sa ON i.STD_ID = sa.STD_ID 
                                AND i.EX_ID = sa.EX_ID 
                                AND i.Q_ID = sa.Q_ID
    )
    BEGIN
        RAISERROR('You have already answered this question! Use UPDATE instead.', 16, 1);
        RETURN;
    END
    
    -- If no duplicates, perform the insert
    INSERT INTO Student_Answer (STD_ID, EX_ID, Q_ID, Student_Answer, Is_Correct, Obtained_Marks, ANS_At)
    SELECT STD_ID, EX_ID, Q_ID, Student_Answer, Is_Correct, Obtained_Marks, ANS_At
    FROM inserted;
END
GO








-- 3. TRIGGER: Prevent Exam Deletion If Students Took It
-- what: Protect data integrity - don't delete exams with submissions
-- when: INSTEAD OF DELETE on exam
-- =====================================================

CREATE OR ALTER TRIGGER trg_PreventExamDeletion
ON exam
INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Check if any students have started the exam
    IF EXISTS (
        SELECT 1
        FROM deleted d
        JOIN Student_Exam se ON d.EX_ID = se.EX_ID
        WHERE se.Actual_Start_Time IS NOT NULL
    )
    BEGIN
        RAISERROR('Cannot delete exam - students have already taken it!', 16, 1);
        RETURN;
    END
    
    -- If no students started, allow deletion
    -- First delete related records (cascade)
    DELETE FROM Student_Exam WHERE EX_ID IN (SELECT EX_ID FROM deleted);
    DELETE FROM Exam_Question WHERE EX_ID IN (SELECT EX_ID FROM deleted);
    DELETE FROM exam WHERE EX_ID IN (SELECT EX_ID FROM deleted);
    
    PRINT 'Exam deleted successfully.';
END
GO








-- 5. TRIGGER: Auto-Set Question Created Date
-- what: Ensure created_date is always set
-- when: BEFORE INSERT on question
-- Note: Already has DEFAULT constraint, but this ensures it's never NULL
-- =====================================================

CREATE OR ALTER TRIGGER trg_SetQuestionCreatedDate
ON question
INSTEAD OF INSERT
AS
BEGIN
    SET NOCOUNT ON;
    
    INSERT INTO question (Q_TEXT, Q_TYPE, Correct_Answer, CRS_ID, Created_By, Created_Date)
    SELECT 
        Q_TEXT, 
        Q_TYPE, 
        Correct_Answer, 
        CRS_ID, 
        Created_By,
        ISNULL(Created_Date, GETDATE())  -- Use provided date or current date
    FROM inserted;
END
GO






-- 5. TRIGGER: Validate Student Answer Belongs to Assigned Exam
-- what: Ensure student can only answer exams they're assigned to
-- when: AFTER INSERT on Student_Answer
-- =====================================================

CREATE OR ALTER TRIGGER trg_ValidateStudentExamAssignment
ON Student_Answer
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Check if student is assigned to the exam
    IF EXISTS (
        SELECT 1
        FROM inserted i
        WHERE NOT EXISTS (
            SELECT 1 
            FROM Student_Exam se
            WHERE se.STD_ID = i.STD_ID AND se.EX_ID = i.EX_ID
        )
    )
    BEGIN
        RAISERROR('Student is not assigned to this exam!', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END
END
GO






















-- 6. TRIGGER: Prevent Question Deletion If Used in Exam
-- what: Protect questions that are already in exams
-- when: INSTEAD OF DELETE on question
-- =====================================================

CREATE OR ALTER TRIGGER trg_PreventQuestionDeletion
ON question
INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Check if question is used in any exam
    IF EXISTS (
        SELECT 1
        FROM deleted d
        JOIN Exam_Question eq ON d.Q_ID = eq.Q_ID
    )
    BEGIN
        RAISERROR('Cannot delete question - it is used in one or more exams!', 16, 1);
        RETURN;
    END
    
    -- If not used, allow deletion
    -- Cascade delete choices first
    DELETE FROM Question_Choices WHERE Q_ID IN (SELECT Q_ID FROM deleted);
    DELETE FROM question WHERE Q_ID IN (SELECT Q_ID FROM deleted);
    
    PRINT 'Question deleted successfully.';
END
GO





















--student  number phone must be 11 or will be error

create trigger stu_numberphone 
on student 
after update 
as

begin 
begin try 
         if exists ( select *  from inserted    where  len(STD_PHONE) = 11)
begin 
print ' succeed '
end
end try
begin catch 
print ' must be 11 numbers  '
end catch
end

















--student must login with gmail
GO
create trigger tri_student_gmail  
on student 
after update 
as

begin 
begin try 
         if exists ( select *  from inserted    where STD_EMAIL   LIKE '%@gmail.com')
begin 
print ' well done '
end
end try
begin catch 
print ' must be inserted gmail '
end catch
end 












/*


--to prevent student to login   because he was refused .....ex: m0hamed adel



-- pevent him  to insert because he refused
 ----------------------- 
create trigger t7
on INTAKE
instead of   insert 
as
if  exists
(   select * from inserted 
where IN_NAME = 'mohamed adel '

)
print  ' refused '
rollback transaction ; 

3


*/








--student cant  insert and solve the exam if the date of the exam was missed    
GO
create  trigger t6
on exam 
after insert ,  update
as 

BEGIN
    IF EXISTS (
        SELECT 1
        FROM inserted
        WHERE EX_DATE < CAST(GETDATE() AS DATE)
    )
    BEGIN
        RAISERROR('Not available', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END
END;









GO

--cant delete any branch
create trigger t12
on branch 
instead of  delete 
as

print ' forbidden'