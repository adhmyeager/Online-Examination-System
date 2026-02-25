-- 1. ADD BRANCH
-- Who: Training Manager
-- what: Add a new branch to the system


CREATE OR ALTER PROCEDURE sp_AddBranch
    @BranchName VARCHAR(100),
    @BranchLocation VARCHAR(100) = NULL,
    @NewBranchID INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON; --to clear the 'n' row affected 
    
    -- Validation: Check if branch already exists
    IF EXISTS (SELECT 1 FROM branch WHERE BR_NAME = @BranchName)
    BEGIN
        RAISERROR('Branch name already exists!', 16, 1);--16 is the level and 1 is the state to print the exact error i want
        RETURN;
    END
    
    -- Insert new branch
    INSERT INTO branch (BR_NAME, BR_LOC)
    VALUES (@BranchName, @BranchLocation);
    -- Get the new ID
    SET @NewBranchID = SCOPE_IDENTITY();
END
GO


















--verfication
DECLARE @BranchID INT;
EXEC sp_AddBranch 
    @BranchName = 'Cairo Branch',
    @BranchLocation = '123 Main St, Cairo',
    @NewBranchID = @BranchID OUTPUT;
SELECT @BranchID;








-- 2. ADD TRACK
-- who: Training Manager
-- what: Add a new  track
GO
CREATE OR ALTER PROCEDURE sp_AddTrack
    @TrackName VARCHAR(100),
    @TrackDescription VARCHAR(100) = NULL,
    @NewTrackID INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Validation: Check if track already exists
    IF EXISTS (SELECT 1 FROM track WHERE TR_NAME = @TrackName)
    BEGIN
        RAISERROR('Track name already exists!', 16, 1);
        RETURN;
    END
    
    -- Insert new track
    INSERT INTO track (TR_NAME, TR_DES)
    VALUES (@TrackName, @TrackDescription);
    SET @NewTrackID = SCOPE_IDENTITY();
    
END
GO



--verfication
DECLARE @TrackID INT;
EXEC sp_AddTrack 
    @TrackName = 'php',
    @TrackDescription = '  ',
    @NewTrackID = @TrackID OUTPUT;









--3. ASSIGN TRACK TO BRANCH
-- who: Training Manager
-- what: link the track to specific branch as the T.M. wants
GO
CREATE OR ALTER PROCEDURE sp_AssignTrackToBranch
    @BranchID INT,
    @TrackID INT,
    @StartDate DATE = NULL
AS
BEGIN
    --
    SET NOCOUNT ON;
    
    -- Validation: Check if branch exists
    IF NOT EXISTS (SELECT 1 FROM branch WHERE BR_ID = @BranchID)
    BEGIN
        RAISERROR('Branch ID does not exist!', 16, 1);
        RETURN;
    END
    
    -- Validation: Check if track exists
    IF NOT EXISTS (SELECT 1 FROM track WHERE TR_ID = @TrackID)
    BEGIN
        RAISERROR('Track ID does not exist!', 16, 1);
        RETURN;
    END
    
    -- Validation: Check if already assigned
    IF EXISTS (SELECT 1 FROM branch_track 
               WHERE BR_ID = @BranchID AND TR_ID = @TrackID)
    BEGIN
        RAISERROR('This track is already assigned to this branch!', 16, 1);
        RETURN;
    END
    
    -- Insert assignment
    INSERT INTO branch_track (BR_ID, TR_ID, ST_DATE)
    VALUES (@BranchID, @TrackID, ISNULL(@StartDate, GETDATE()));    
END
GO









EXEC sp_AssignTrackToBranch 
    @BranchID = ,--enter the branch id
    @TrackID = ,--enter the track_id
    @StartDate = '2027-01-01';--enter the the strart date















-- 4. ADD INTAKE
-- who: Training Manager
-- what: add intake
GO
CREATE OR ALTER PROCEDURE sp_AddIntake
    @IntakeName VARCHAR(50),
    @IntakeYear INT,
    @BranchID INT,
    @TrackID INT,
    @NewIntakeID INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Validation: Check if Branch-Track combination exists
    IF NOT EXISTS (SELECT 1 FROM branch_track 
                   WHERE BR_ID = @BranchID AND TR_ID = @TrackID)
    BEGIN
        RAISERROR('This Track is not available at this Branch! Please assign the track first.', 16, 1);
        RETURN;
    END
    
    -- Validation: Check if intake name already exists
    IF EXISTS (SELECT 1 FROM intake WHERE IN_NAME = @IntakeName)
    BEGIN
        RAISERROR('Intake with this name already exists!', 16, 1);
        RETURN;
    END
    
    -- Insert new intake
    INSERT INTO intake (IN_NAME, IN_YEAR, BR_ID, TR_ID)
    VALUES (@IntakeName, @IntakeYear, @BranchID, @TrackID);
    SET @NewIntakeID = SCOPE_IDENTITY();
    
END










--verfication

DECLARE @IntakeID INT;
EXEC sp_AddIntake 
    @IntakeName = 'Intake 45',--put the intake name
    @IntakeYear = 2024,--year
    @BranchID = ,--br_id
    @TrackID = ,--track_id
    @NewIntakeID = @IntakeID OUTPUT;















-- 5. ADD STUDENT (with User Account)
-- who: Training Manager
-- what: Register a new student in the system
-- Note: Creates User account first, then Student record
GO
CREATE OR ALTER PROCEDURE sp_AddStudent
    @Username NVARCHAR(50),
    @Password NVARCHAR(50),  -- Will be hashed
    @StudentName NVARCHAR(100),
    @Email NVARCHAR(100),
    @Phone NVARCHAR(20) = NULL,
    @Address NVARCHAR(200) = NULL,
    @DateOfBirth DATE = NULL,
    @IntakeID INT,
    @NewStudentID INT OUTPUT
AS
BEGIN
    
    SET NOCOUNT ON;
    BEGIN TRANSACTION;
    
    BEGIN TRY
        -- Validation: Check if username already exists
        IF EXISTS (SELECT 1 FROM [user] WHERE usr_name = @Username)
        BEGIN
            RAISERROR('Username already exists!', 16, 1);
            RETURN;
        END
        
        -- Validation: Check if email already exists
        IF EXISTS (SELECT 1 FROM student WHERE STD_EMAIL = @Email)
        BEGIN
            RAISERROR('Email already registered!', 16, 1);
            RETURN;
        END
        
        -- Validation: Check if intake exists
        IF NOT EXISTS (SELECT 1 FROM intake WHERE IN_ID = @IntakeID)
        BEGIN
            RAISERROR('Intake ID does not exist!', 16, 1);
            RETURN;
        END
        
        -- Step 1: Create User account
        DECLARE @NewUserID INT;
        DECLARE @PasswordHash NVARCHAR(256);
        
        -- Simple hash 
        SET @PasswordHash = CONVERT(NVARCHAR(256), HASHBYTES('SHA2_256', @Password), 2);
        
        INSERT INTO [user] (usr_name, pass_hash, Role, is_active)
        VALUES (@Username, @PasswordHash, 'student', 1);
        
        SET @NewUserID = SCOPE_IDENTITY();
        
        -- Step 2: Create Student record
        INSERT INTO student (USR_ID, STD_NAME, STD_EMAIL, STD_PHONE, STD_ADD, DOB, IN_ID)
        VALUES (@NewUserID, @StudentName, @Email, @Phone, @Address, @DateOfBirth, @IntakeID);
        SET @NewStudentID = SCOPE_IDENTITY();
        COMMIT TRANSACTION;    
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO











--verfiaction
DECLARE @StudentID INT;
EXEC sp_AddStudent 
    @Username = 'adhm ahmed 123',--add the username
    @Password = 'pass_123',--add the pass
    @StudentName = 'adhm_ahmed',--add the student name
    @Email = '   ',
    @Phone = ' ',
    @Address = ' ',
    @DateOfBirth = '2001-11-30',
    @IntakeID = ,--put his intake --important
    @NewStudentID = @StudentID OUTPUT;






















-- 6. ADD TRAINING MANAGER (with User Account)
-- who: Admin 
-- what: Register a new training manager in the system



GO
CREATE OR ALTER PROCEDURE sp_AddTrainingManager
    @Username NVARCHAR(50),
    @Password NVARCHAR(50),
    @ManagerName VARCHAR(100),
    @Email VARCHAR(100),
    @Phone VARCHAR(20) = NULL,
    @NewManagerID INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRANSACTION;
    
    BEGIN TRY
        -- Validation: Check if username exists
        IF EXISTS (SELECT 1 FROM [user] WHERE usr_name = @Username)
        BEGIN
            RAISERROR('Username already exists!', 16, 1);
            RETURN;
        END
        
        -- Validation: Check if email exists
        IF EXISTS (SELECT 1 FROM training_manger WHERE MGR_EMAIL = @Email)
        BEGIN
            RAISERROR('Email already registered!', 16, 1);
            RETURN;
        END
        
        -- Step 1: Create User account
        DECLARE @NewUserID INT;
        DECLARE @PasswordHash NVARCHAR(256);
        --
        SET @PasswordHash = CONVERT(NVARCHAR(256), HASHBYTES('SHA2_256', @Password), 2);
        
        INSERT INTO [user] (usr_name, pass_hash, Role, is_active)
        VALUES (@Username, @PasswordHash, 'training manager', 1);
        
        SET @NewUserID = SCOPE_IDENTITY();
        
        -- Step 2: Create Manager record
        INSERT INTO training_manager (Usr_ID, MGR_NAME, MGR_EMAIL, MGR_PHONE)
        VALUES (@NewUserID, @ManagerName, @Email, @Phone);
        
        SET @NewManagerID = SCOPE_IDENTITY();
        
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO

















--verfication
DECLARE @ManagerID INT;
EXEC sp_AddTrainingManager 
    @Username = 'mahmoud_ouf',--name
    @Password = 'ouf_123',--pass
    @ManagerName = 'mahmoud ouf',--mang_name
    @Email = 'ouf@gamil.com',--email
    @Phone = '  ',
    @NewManagerID = @ManagerID OUTPUT;

































-- 7. ADD QUESTION
-- who: Instructor
-- what: Add a new question to the question pool
-- Note: After adding MCQ, (we will use sp_AddQuestionChoice to add options)
GO
CREATE OR ALTER PROCEDURE sp_AddQuestion
    @QuestionText VARCHAR(MAX),
    @QuestionType VARCHAR(20),  -- 'MCQ', 'TrueFalse', 'Text'
    @CorrectAnswer VARCHAR(MAX) = NULL,
    @CourseID INT,
    @InstructorID INT,
    @NewQuestionID INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Validation: Check question type
    IF @QuestionType NOT IN ('MCQ', 'TrueFalse', 'Text')
    BEGIN
        RAISERROR('Invalid Question Type! Must be MCQ, TrueFalse, or Text', 16, 1);
        RETURN;
    END
    
    -- Validation: Check course exists
    IF NOT EXISTS (SELECT 1 FROM course WHERE CRS_ID = @CourseID)
    BEGIN
        RAISERROR('Course ID does not exist!', 16, 1);
        RETURN;
    END
    
    -- Validation: Check instructor exists
    IF NOT EXISTS (SELECT 1 FROM instructor WHERE INS_ID = @InstructorID)
    BEGIN
        RAISERROR('Instructor ID does not exist!', 16, 1);
        RETURN;
    END
    
    -- Validation: Check if instructor teaches this course
    IF NOT EXISTS (SELECT 1 FROM Instructor_Course 
                   WHERE INS_ID = @InstructorID AND CRS_ID = @CourseID)
    BEGIN
        RAISERROR('You are not assigned to teach this course!', 16, 1);
        RETURN;
    END
    
    -- Insert question
    INSERT INTO question (Q_TEXT, Q_TYPE, Correct_Answer, CRS_ID, Created_By, Created_Date)
    VALUES (@QuestionText, @QuestionType, @CorrectAnswer, @CourseID, @InstructorID, GETDATE());
    
    SET @NewQuestionID = SCOPE_IDENTITY();
        
    IF @QuestionType = 'MCQ'
    BEGIN
        PRINT 'Remember to add choices using sp_AddQuestionChoice!';
    END
END
GO














-- MCQ Question
DECLARE @QuestionID INT;
EXEC sp_AddQuestion 
    @QuestionText = 'What does SQL stand for?',
    @QuestionType = 'MCQ',
    @CorrectAnswer = 'A',  -- The correct choice
    @CourseID = 1,
    @InstructorID = 1,
    @NewQuestionID = @QuestionID OUTPUT;

-- True/False Question
EXEC sp_AddQuestion 
    @QuestionText = 'SQL is a programming language.',
    @QuestionType = 'TrueFalse',
    @CorrectAnswer = 'False',
    @CourseID = 1,
    @InstructorID = 1,
    @NewQuestionID = @QuestionID OUTPUT;

-- Text Question
EXEC sp_AddQuestion 
    @QuestionText = 'Write a query to select all students.',
    @QuestionType = 'Text',
    @CorrectAnswer = 'SELECT * FROM student',
    @CourseID = 1,
    @InstructorID = 1,
    @NewQuestionID = @QuestionID OUTPUT;











--9. ADD QUESTION CHOICE (for MCQ only)
-- what: Add answer options for multiple choice questions
-- who: Instructor (after creating MCQ question)
GO
CREATE OR ALTER PROCEDURE sp_AddQuestionChoice
    @QuestionID INT,
    @ChoiceText VARCHAR(500),
    @ChoiceOrder CHAR(1)  -- 'A', 'B', 'C', 'D'
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Validation: Check question exists
    IF NOT EXISTS (SELECT 1 FROM question WHERE Q_ID = @QuestionID)
    BEGIN
        RAISERROR('Question ID does not exist!', 16, 1);
        RETURN;
    END
    
    -- Validation: Check question is MCQ
    IF NOT EXISTS (SELECT 1 FROM question WHERE Q_ID = @QuestionID AND Q_TYPE = 'MCQ')
    BEGIN
        RAISERROR('This question is not an MCQ! Choices are only for MCQ questions.', 16, 1);
        RETURN;
    END
    
    -- Validation: Check choice order is valid
    IF @ChoiceOrder NOT IN ('A', 'B', 'C', 'D', 'E', 'F')
    BEGIN
        RAISERROR('Choice order must be A, B, C, D, E, or F', 16, 1);
        RETURN;
    END
    
    -- Insert choice
    INSERT INTO Question_Choices (Q_ID, Choice_Text, Choice_Order)
    VALUES (@QuestionID, @ChoiceText, @ChoiceOrder);
    
END
GO




--verfication
-- After creating MCQ question with ID = 1
EXEC sp_AddQuestionChoice @QuestionID = 1, @ChoiceText = 'Structured Query Language', @ChoiceOrder = 'A';
EXEC sp_AddQuestionChoice @QuestionID = 1, @ChoiceText = 'Simple Question Language', @ChoiceOrder = 'B';
EXEC sp_AddQuestionChoice @QuestionID = 1, @ChoiceText = 'Server Query Language', @ChoiceOrder = 'C';
EXEC sp_AddQuestionChoice @QuestionID = 1, @ChoiceText = 'System Quality Language', @ChoiceOrder = 'D';






-- 10. CREATE EXAM
-- what: Create a new exam (without questions yet)
-- who: Instructor
-- Note: Use sp_AddQuestionToExam to add questions after
GO
CREATE OR ALTER PROCEDURE sp_CreateExam
    @ExamType VARCHAR(20),  -- 'Exam' or 'Corrective'
    @CourseID INT,
    @InstructorID INT,
    @IntakeID INT,
    @ExamDate DATE,
    @StartTime TIME,
    @EndTime TIME,
    @TotalTime INT,  -- in minutes
    @TotalDegree INT,
    @Year INT,
    @AllowanceOptions NVARCHAR(200) = NULL,
    @NewExamID INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Validation: Check exam type
    IF @ExamType NOT IN ('Exam', 'Corrective')
    BEGIN
        RAISERROR('Invalid Exam Type! Must be Exam or Corrective', 16, 1);
        RETURN;
    END
    
    -- Validation: Check course exists
    IF NOT EXISTS (SELECT 1 FROM course WHERE CRS_ID = @CourseID)
    BEGIN
        RAISERROR('Course ID does not exist!', 16, 1);
        RETURN;
    END
    
    -- Validation: Check instructor teaches this course
    IF NOT EXISTS (SELECT 1 FROM Instructor_Course 
                   WHERE INS_ID = @InstructorID AND CRS_ID = @CourseID)
    BEGIN
        RAISERROR('You are not assigned to teach this course!', 16, 1);
        RETURN;
    END
    
    -- Validation: Check intake exists
    IF NOT EXISTS (SELECT 1 FROM intake WHERE IN_ID = @IntakeID)
    BEGIN
        RAISERROR('Intake ID does not exist!', 16, 1);
        RETURN;
    END
    
    -- Validation: Check total degree doesn't exceed course max
    DECLARE @CourseMaxDegree INT;
    SELECT @CourseMaxDegree = Max_Degree FROM course WHERE CRS_ID = @CourseID;
    
    IF @TotalDegree > @CourseMaxDegree
    BEGIN
        RAISERROR('Exam total degree cannot exceed course max degree!', 16, 1);
        RETURN;
    END
    
    -- Insert exam
    INSERT INTO exam (EX_TYPE, CRS_ID, INS_ID, IN_ID, EX_DATE, Start_Time, End_Time, 
                      Total_Time, Total_Degree, Year, Allowance_Options)
    VALUES (@ExamType, @CourseID, @InstructorID, @IntakeID, @ExamDate, @StartTime, @EndTime,
            @TotalTime, @TotalDegree, @Year, @AllowanceOptions);
    
    SET @NewExamID = SCOPE_IDENTITY();
END
GO







--verfiaction

DECLARE @ExamID INT;
EXEC sp_CreateExam 
    @ExamType = 'Exam',
    @CourseID = 1,
    @InstructorID = 1,
    @IntakeID = 1,
    @ExamDate = '2027-12-15',
    @StartTime = '09:00',
    @EndTime = '11:00',
    @TotalTime = 120,  -- 120 minutes
    @TotalDegree = 50,
    @Year = 2027,
    @AllowanceOptions = 'Calculator allowed',
    @NewExamID = @ExamID OUTPUT;















-- 11. ADD QUESTION TO EXAM (Manual Selection)
-- what: Manually add a specific question to an exam
-- who: Instructor
GO
CREATE OR ALTER PROCEDURE sp_AddQuestionToExam
    @ExamID INT,
    @QuestionID INT,
    @QuestionDegree INT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Validation: Check exam exists
    IF NOT EXISTS (SELECT 1 FROM exam WHERE EX_ID = @ExamID)
    BEGIN
        RAISERROR('Exam ID does not exist!', 16, 1);
        RETURN;
    END
    
    -- Validation: Check question exists
    IF NOT EXISTS (SELECT 1 FROM question WHERE Q_ID = @QuestionID)
    BEGIN
        RAISERROR('Question ID does not exist!', 16, 1);
        RETURN;
    END
    
    -- Validation: Check question already in exam
    IF EXISTS (SELECT 1 FROM Exam_Question WHERE EX_ID = @ExamID AND Q_ID = @QuestionID)
    BEGIN
        RAISERROR('This question is already added to this exam!', 16, 1);
        RETURN;
    END
    
    -- Validation: Check if question belongs to same course as exam
    DECLARE @ExamCourseID INT, @QuestionCourseID INT;
    SELECT @ExamCourseID = CRS_ID FROM exam WHERE EX_ID = @ExamID;
    SELECT @QuestionCourseID = CRS_ID FROM question WHERE Q_ID = @QuestionID;
    
    IF @ExamCourseID != @QuestionCourseID
    BEGIN
        RAISERROR('Question must belong to the same course as the exam!', 16, 1);
        RETURN;
    END
    
    -- Validation: Check total degrees won't exceed exam total
    DECLARE @CurrentTotal INT, @ExamTotal INT;
    SELECT @CurrentTotal = ISNULL(SUM(Q_DEGREE), 0) 
    FROM Exam_Question 
    WHERE EX_ID = @ExamID;
    
    SELECT @ExamTotal = Total_Degree FROM exam WHERE EX_ID = @ExamID;
    
    IF (@CurrentTotal + @QuestionDegree) > @ExamTotal
    BEGIN
        RAISERROR('Adding this question exceeds the exam total degree!', 16, 1);
        RETURN;
    END
    
    -- Insert question to exam
    INSERT INTO Exam_Question (EX_ID, Q_ID, Q_DEGREE)
    VALUES (@ExamID, @QuestionID, @QuestionDegree);
    
END
GO














--verfication

EXEC sp_AddQuestionToExam 
    @ExamID = 1,
    @QuestionID = 5,
    @QuestionDegree = 10;

























-- 12. ADD RANDOM QUESTIONS TO EXAM (!!!!!!!! addtion ;) )
-- who: Instructor
-- what: Automatically select random questions from pool
-- Parameters: Specify how many of each type to add
-- 
GO
CREATE OR ALTER PROCEDURE sp_AddRandomQuestionsToExam
    @ExamID INT,
    @NumMCQ INT = 0,
    @NumTrueFalse INT = 0,
    @NumText INT = 0,
    @DegreesPerMCQ INT = 1,
    @DegreesPerTrueFalse INT = 1,
    @DegreesPerText INT = 5
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRANSACTION;
    
    BEGIN TRY
        -- Get exam info
        DECLARE @CourseID INT, @ExamTotal INT, @CurrentTotal INT;
        SELECT @CourseID = CRS_ID, @ExamTotal = Total_Degree 
        FROM exam WHERE EX_ID = @ExamID;
        
        SELECT @CurrentTotal = ISNULL(SUM(Q_DEGREE), 0)
        FROM Exam_Question WHERE EX_ID = @ExamID;
        
        -- Calculate total degrees needed
        DECLARE @NeededDegrees INT;
        SET @NeededDegrees = (@NumMCQ * @DegreesPerMCQ) + 
                             (@NumTrueFalse * @DegreesPerTrueFalse) + 
                             (@NumText * @DegreesPerText);
        
        -- Validation: Check if we have enough room
        IF (@CurrentTotal + @NeededDegrees) > @ExamTotal
        BEGIN
            RAISERROR('Total degrees would exceed exam limit!', 16, 1);
            RETURN;
        END
        
        -- Add MCQ questions
        IF @NumMCQ > 0
        BEGIN
            INSERT INTO Exam_Question (EX_ID, Q_ID, Q_DEGREE)
            SELECT TOP (@NumMCQ) @ExamID, Q_ID, @DegreesPerMCQ
            FROM question
            WHERE CRS_ID = @CourseID 
              AND Q_TYPE = 'MCQ'
              AND Q_ID NOT IN (SELECT Q_ID FROM Exam_Question WHERE EX_ID = @ExamID)
            ORDER BY NEWID();  -- Random order
        END
        
        -- Add True/False questions
        IF @NumTrueFalse > 0
        BEGIN
            INSERT INTO Exam_Question (EX_ID, Q_ID, Q_DEGREE)
            SELECT TOP (@NumTrueFalse) @ExamID, Q_ID, @DegreesPerTrueFalse
            FROM question
            WHERE CRS_ID = @CourseID 
              AND Q_TYPE = 'TrueFalse'
              AND Q_ID NOT IN (SELECT Q_ID FROM Exam_Question WHERE EX_ID = @ExamID)
            ORDER BY NEWID();
        END
        
        -- Add Text questions
        IF @NumText > 0
        BEGIN
            INSERT INTO Exam_Question (EX_ID, Q_ID, Q_DEGREE)
            SELECT TOP (@NumText) @ExamID, Q_ID, @DegreesPerText
            FROM question
            WHERE CRS_ID = @CourseID 
              AND Q_TYPE = 'Text'
              AND Q_ID NOT IN (SELECT Q_ID FROM Exam_Question WHERE EX_ID = @ExamID)
            ORDER BY NEWID();
        END
        
        COMMIT TRANSACTION; 
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO









--verfiaction

EXEC sp_AddRandomQuestionsToExam 
    @ExamID = 1,
    @NumMCQ = 10,              -- Add 10 MCQ questions
    @NumTrueFalse = 5,         -- Add 5 T/F questions
    @NumText = 2,              -- Add 2 text questions
    @DegreesPerMCQ = 2,        -- 2 points each
    @DegreesPerTrueFalse = 1,  -- 1 point each
    @DegreesPerText = 10;      -- 10 points each


































-- 13. ASSIGN STUDENTS TO EXAM
-- what: Enroll students to take a specific exam
-- who: Instructor
-- Note: Can assign all students in intake or specific students
GO
CREATE OR ALTER PROCEDURE sp_AssignStudentsToExam
    @ExamID INT,
    @IntakeID INT = NULL  -- If NULL, assigns all students from exam's intake
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Validation: Check exam exists
    IF NOT EXISTS (SELECT 1 FROM exam WHERE EX_ID = @ExamID)
    BEGIN
        RAISERROR('Exam ID does not exist!', 16, 1);
        RETURN;
    END
    
    -- If IntakeID not provided, get it from exam
    IF @IntakeID IS NULL
    BEGIN
        SELECT @IntakeID = IN_ID FROM exam WHERE EX_ID = @ExamID;
    END
    
    -- Insert all students from intake who aren't already assigned
    INSERT INTO Student_Exam (STD_ID, EX_ID)
    SELECT s.STD_ID, @ExamID
    FROM student s
    WHERE s.IN_ID = @IntakeID
      AND NOT EXISTS (SELECT 1 FROM Student_Exam 
                      WHERE STD_ID = s.STD_ID AND EX_ID = @ExamID);
    
    DECLARE @AssignedCount INT = @@ROWCOUNT;
    
    PRINT CAST(@AssignedCount AS VARCHAR) + ' student(s) assigned to exam successfully!';
END
GO














--verfication
-- Assign all students from the exam's intake
EXEC sp_AssignStudentsToExam @ExamID = 1;

-- Or assign from specific intake
EXEC sp_AssignStudentsToExam @ExamID = 1, @IntakeID = 1;
















































-- 14. GRADE TEXT ANSWER (Manual Grading)
-- what: Instructor manually grades text questions
-- who: Instructor
GO
CREATE OR ALTER PROCEDURE sp_GradeTextAnswer
    @AnswerID INT,
    @ObtainedMarks DECIMAL(5,2),
    @IsCorrect BIT = NULL  -- Optional: mark as correct/incorrect
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Validation: Check answer exists
    IF NOT EXISTS (SELECT 1 FROM Student_Answer WHERE ANS_ID = @AnswerID)
    BEGIN
        RAISERROR('Answer ID does not exist!', 16, 1);
        RETURN;
    END
    
    -- Validation: Check it's a text question
    DECLARE @QuestionType VARCHAR(20);
    SELECT @QuestionType = q.Q_TYPE
    FROM Student_Answer sa
    JOIN question q ON sa.Q_ID = q.Q_ID
    WHERE sa.ANS_ID = @AnswerID;
    
    IF @QuestionType != 'Text'
    BEGIN
        RAISERROR('This procedure is only for text questions!', 16, 1);
        RETURN;
    END
    
    -- Validation: Check marks don't exceed question degree
    DECLARE @MaxMarks DECIMAL(5,2);
    SELECT @MaxMarks = eq.Q_DEGREE
    FROM Student_Answer sa
    JOIN Exam_Question eq ON sa.EX_ID = eq.EX_ID AND sa.Q_ID = eq.Q_ID
    WHERE sa.ANS_ID = @AnswerID;
    
    IF @ObtainedMarks > @MaxMarks
    BEGIN
        RAISERROR('Obtained marks cannot exceed question degree!', 16, 1);
        RETURN;
    END
    
    -- Update answer
    UPDATE Student_Answer
    SET Obtained_Marks = @ObtainedMarks,
        Is_Correct = @IsCorrect
    WHERE ANS_ID = @AnswerID;
    
    PRINT 'Text answer graded successfully!';
END
GO














--verfication
EXEC sp_GradeTextAnswer 
    @AnswerID = 123,
    @ObtainedMarks = 8.5,
    @IsCorrect = 1;




























-- 15. START EXAM (Student begins exam)
-- what: Record when student starts an exam
-- who: Student
-- Validates: Exam is active, student is enrolled, within time window
GO
CREATE OR ALTER PROCEDURE sp_StartExam
    @StudentID INT,
    @ExamID INT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Validation: Check if student is assigned to this exam
    IF NOT EXISTS (SELECT 1 FROM Student_Exam 
                   WHERE STD_ID = @StudentID AND EX_ID = @ExamID)
    BEGIN
        RAISERROR('You are not assigned to this exam!', 16, 1);
        RETURN;
    END
    
    -- Validation: Check if already started
    DECLARE @AlreadyStarted DATETIME;
    SELECT @AlreadyStarted = Actual_Start_Time 
    FROM Student_Exam 
    WHERE STD_ID = @StudentID AND EX_ID = @ExamID;
    
    IF @AlreadyStarted IS NOT NULL
    BEGIN
        RAISERROR('You have already started this exam!', 16, 1);
        RETURN;
    END
    
    -- Validation: Check if exam is currently open
    DECLARE @ExamDate DATE, @StartTime TIME, @EndTime TIME;
    SELECT @ExamDate = EX_DATE, @StartTime = Start_Time, @EndTime = End_Time
    FROM exam WHERE EX_ID = @ExamID;
    
    DECLARE @CurrentDateTime DATETIME = GETDATE();
    DECLARE @CurrentDate DATE = CAST(@CurrentDateTime AS DATE);
    DECLARE @CurrentTime TIME = CAST(@CurrentDateTime AS TIME);
    
    IF @CurrentDate != @ExamDate
    BEGIN
        RAISERROR('Exam is not scheduled for today!', 16, 1);
        RETURN;
    END
    
    IF @CurrentTime < @StartTime OR @CurrentTime >= @EndTime
    BEGIN
        RAISERROR('Exam is not currently open! Check exam schedule.', 16, 1);
        RETURN;
    END
    
    -- Record start time
    UPDATE Student_Exam
    SET Actual_Start_Time = GETDATE()
    WHERE STD_ID = @StudentID AND EX_ID = @ExamID;
    
    PRINT 'Exam started successfully! Good luck!';
    PRINT 'Start time: ' + CONVERT(VARCHAR, GETDATE(), 120);
END
GO








--verfication
EXEC sp_StartExam 
    @StudentID = 1,
    @ExamID = 1;




































-- 16. SUBMIT ANSWER
-- what: Student submits answer to a question
-- who: Student (during exam)
GO
CREATE OR ALTER PROCEDURE sp_SubmitAnswer
    @StudentID INT,
    @ExamID INT,
    @QuestionID INT,
    @StudentAnswer VARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRANSACTION;
    
    BEGIN TRY
        -- Validation: Check if student started exam
        DECLARE @StartTime DATETIME;
        SELECT @StartTime = Actual_Start_Time 
        FROM Student_Exam 
        WHERE STD_ID = @StudentID AND EX_ID = @ExamID;
        
        IF @StartTime IS NULL
        BEGIN
            RAISERROR('You must start the exam first!', 16, 1);
            RETURN;
        END
        
        -- Validation: Check if question is in this exam
        IF NOT EXISTS (SELECT 1 FROM Exam_Question 
                       WHERE EX_ID = @ExamID AND Q_ID = @QuestionID)
        BEGIN
            RAISERROR('This question is not part of this exam!', 16, 1);
            RETURN;
        END
        
        -- Get question info
        DECLARE @QuestionType VARCHAR(20), @CorrectAnswer VARCHAR(MAX);
        SELECT @QuestionType = Q_TYPE, @CorrectAnswer = Correct_Answer
        FROM question WHERE Q_ID = @QuestionID;
        
        -- Auto-grade MCQ and TrueFalse
        DECLARE @IsCorrect BIT = NULL;
        DECLARE @ObtainedMarks DECIMAL(5,2) = NULL;
        
        IF @QuestionType IN ('MCQ', 'TrueFalse')
        BEGIN
            -- Check if answer is correct (case-insensitive comparison)
            IF UPPER(LTRIM(RTRIM(@StudentAnswer))) = UPPER(LTRIM(RTRIM(@CorrectAnswer)))
            BEGIN
                SET @IsCorrect = 1;
                -- Get full marks for correct answer
                SELECT @ObtainedMarks = Q_DEGREE 
                FROM Exam_Question 
                WHERE EX_ID = @ExamID AND Q_ID = @QuestionID;
            END
            ELSE
            BEGIN
                SET @IsCorrect = 0;
                SET @ObtainedMarks = 0;
            END
        END
        -- Text questions: Leave NULL for manual grading
        
        -- Check if answer already exists (update) or new (insert)
        IF EXISTS (SELECT 1 FROM Student_Answer 
                   WHERE STD_ID = @StudentID AND EX_ID = @ExamID AND Q_ID = @QuestionID)
        BEGIN
            -- Update existing answer
            UPDATE Student_Answer
            SET Student_Answer = @StudentAnswer,
                Is_Correct = @IsCorrect,
                Obtained_Marks = @ObtainedMarks,
                ANS_At = GETDATE()
            WHERE STD_ID = @StudentID AND EX_ID = @ExamID AND Q_ID = @QuestionID;
        END
        ELSE
        BEGIN
            -- Insert new answer
            INSERT INTO Student_Answer (STD_ID, EX_ID, Q_ID, Student_Answer, Is_Correct, Obtained_Marks, ANS_At)
            VALUES (@StudentID, @ExamID, @QuestionID, @StudentAnswer, @IsCorrect, @ObtainedMarks, GETDATE());
        END
        
        COMMIT TRANSACTION;
        
        PRINT 'Answer submitted successfully!';
        
        IF @IsCorrect = 1
            PRINT 'Answer is CORRECT!';
        ELSE IF @IsCorrect = 0
            PRINT 'Answer is INCORRECT.';
        ELSE
            PRINT 'Answer will be graded by instructor.';
            
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO





















--verfication
-- MCQ Answer
EXEC sp_SubmitAnswer 
    @StudentID = 1,
    @ExamID = 1,
    @QuestionID = 5,
    @StudentAnswer = 'A';

-- True/False Answer
EXEC sp_SubmitAnswer 
    @StudentID = 1,
    @ExamID = 1,
    @QuestionID = 8,
    @StudentAnswer = 'True';

-- Text Answer
EXEC sp_SubmitAnswer 
    @StudentID = 1,
    @ExamID = 1,
    @QuestionID = 12,
    @StudentAnswer = 'SELECT * FROM student WHERE STD_ID = 1';





















































-- 17. SUBMIT/FINISH EXAM
-- what: Student finishes exam and submits all answers
-- who: Student
-- Auto-calculates total score
GO
CREATE OR ALTER PROCEDURE sp_SubmitExam
    @StudentID INT,
    @ExamID INT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Validation: Check if student started exam
    DECLARE @StartTime DATETIME;
    SELECT @StartTime = Actual_Start_Time 
    FROM Student_Exam 
    WHERE STD_ID = @StudentID AND EX_ID = @ExamID;
    
    IF @StartTime IS NULL
    BEGIN
        RAISERROR('You have not started this exam!', 16, 1);
        RETURN;
    END
    
    -- Validation: Check if already submitted
    DECLARE @EndTime DATETIME;
    SELECT @EndTime = Actual_End_Time 
    FROM Student_Exam 
    WHERE STD_ID = @StudentID AND EX_ID = @ExamID;
    
    IF @EndTime IS NOT NULL
    BEGIN
        RAISERROR('You have already submitted this exam!', 16, 1);
        RETURN;
    END
    
    -- Calculate total score (sum of obtained marks)
    DECLARE @TotalScore DECIMAL(5,2);
    SELECT @TotalScore = ISNULL(SUM(Obtained_Marks), 0)
    FROM Student_Answer
    WHERE STD_ID = @StudentID AND EX_ID = @ExamID;
    
    -- Update Student_Exam
    UPDATE Student_Exam
    SET Actual_End_Time = GETDATE(),
        Total_Score = @TotalScore,
        Obtained_Degree = @TotalScore  -- Will be updated after text grading
    WHERE STD_ID = @StudentID AND EX_ID = @ExamID;
    
    PRINT 'Exam submitted successfully!';
    PRINT 'Your score: ' + CAST(@TotalScore AS VARCHAR);
    PRINT 'Note: Text questions will be graded by instructor.';
END
GO





--verfication
EXEC sp_SubmitExam 
    @StudentID = 1,
    @ExamID = 1;


























-- 18. RECALCULATE EXAM SCORE
-- what: Recalculate student's score after instructor grades text answers
-- who: System (automatically) or Instructor (manually)
GO
CREATE OR ALTER PROCEDURE sp_RecalculateExamScore
    @StudentID INT,
    @ExamID INT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Calculate new total
    DECLARE @NewTotal DECIMAL(5,2);
    SELECT @NewTotal = ISNULL(SUM(Obtained_Marks), 0)
    FROM Student_Answer
    WHERE STD_ID = @StudentID AND EX_ID = @ExamID;
    
    -- Update Student_Exam
    UPDATE Student_Exam
    SET Total_Score = @NewTotal,
        Obtained_Degree = @NewTotal
    WHERE STD_ID = @StudentID AND EX_ID = @ExamID;
    
    PRINT 'Score recalculated: ' + CAST(@NewTotal AS VARCHAR);
END
GO


















--verfication
EXEC sp_RecalculateExamScore 
    @StudentID = 1,
    @ExamID = 1;






























-- 19. VIEW STUDENT EXAM RESULTS
-- what: Get detailed results for a student's exam
--who: Student or Instructor
-- Returns: Score, answers, correct/incorrect breakdown
GO
CREATE OR ALTER PROCEDURE sp_ViewExamResults
    @StudentID INT,
    @ExamID INT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Exam summary
    SELECT 
        e.EX_ID AS ExamID,
        c.CRS_NAME AS CourseName,
        e.EX_DATE AS ExamDate,
        se.Actual_Start_Time AS StartTime,
        se.Actual_End_Time AS EndTime,
        se.Obtained_Degree AS FinalScore,
        e.Total_Degree AS MaxPossible,
        c.Min_Degree AS PassingScore,
        CASE 
            WHEN se.Obtained_Degree >= c.Min_Degree THEN 'PASS'
            ELSE 'FAIL'
        END AS Result
    FROM Student_Exam se
    JOIN exam e ON se.EX_ID = e.EX_ID
    JOIN course c ON e.CRS_ID = c.CRS_ID
    WHERE se.STD_ID = @StudentID AND se.EX_ID = @ExamID;
    
    -- Detailed answers
    SELECT 
        q.Q_ID AS QuestionID,
        q.Q_TEXT AS Question,
        q.Q_TYPE AS QuestionType,
        sa.Student_Answer AS YourAnswer,
        q.Correct_Answer AS CorrectAnswer,
        sa.Is_Correct AS IsCorrect,
        eq.Q_DEGREE AS MaxMarks,
        sa.Obtained_Marks AS MarksObtained
    FROM Student_Answer sa
    JOIN question q ON sa.Q_ID = q.Q_ID
    JOIN Exam_Question eq ON sa.EX_ID = eq.EX_ID AND sa.Q_ID = eq.Q_ID
    WHERE sa.STD_ID = @StudentID AND sa.EX_ID = @ExamID
    ORDER BY q.Q_ID;
    
    PRINT 'Exam results retrieved successfully!';
END
GO












--verfication
EXEC sp_ViewExamResults 
    @StudentID = 1,
    @ExamID = 1;





























-- 20. VIEW AVAILABLE EXAMS (for Student)
-- what: Show all exams assigned to a student
-- who: Student
GO
CREATE OR ALTER PROCEDURE sp_ViewMyExams
    @StudentID INT
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        e.EX_ID AS ExamID,
        c.CRS_NAME AS CourseName,
        e.EX_TYPE AS ExamType,
        e.EX_DATE AS ExamDate,
        e.Start_Time AS StartTime,
        e.End_Time AS EndTime,
        e.Total_Time AS DurationMinutes,
        e.Total_Degree AS TotalMarks,
        se.Actual_Start_Time AS MyStartTime,
        se.Actual_End_Time AS MyEndTime,
        se.Obtained_Degree AS MyScore,
        CASE 
            WHEN se.Actual_End_Time IS NOT NULL THEN 'Completed'
            WHEN se.Actual_Start_Time IS NOT NULL THEN 'In Progress'
            WHEN CAST(GETDATE() AS DATE) = e.EX_DATE 
                 AND CAST(GETDATE() AS TIME) BETWEEN e.Start_Time AND e.End_Time THEN 'Available Now'
            WHEN CAST(GETDATE() AS DATE) < e.EX_DATE THEN 'Upcoming'
            ELSE 'Expired'
        END AS Status
    FROM Student_Exam se
    JOIN exam e ON se.EX_ID = e.EX_ID
    JOIN course c ON e.CRS_ID = c.CRS_ID
    WHERE se.STD_ID = @StudentID
    ORDER BY e.EX_DATE DESC, e.Start_Time DESC;
    
    PRINT 'Your exams retrieved successfully!';
END
GO













--verfication
EXEC sp_ViewMyExams @StudentID = 1;
























-- 21. GET EXAM QUESTIONS (for Student taking exam)
-- what: Show all questions in an exam
-- who: Student (after starting exam)
-- Note: Does NOT show correct answers!
GO
CREATE OR ALTER PROCEDURE sp_GetExamQuestions
    @StudentID INT,
    @ExamID INT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Validation: Check if student started exam
    IF NOT EXISTS (SELECT 1 FROM Student_Exam 
                   WHERE STD_ID = @StudentID AND EX_ID = @ExamID 
                   AND Actual_Start_Time IS NOT NULL)
    BEGIN
        RAISERROR('You must start the exam first!', 16, 1);
        RETURN;
    END
    
    -- Get questions
    SELECT 
        q.Q_ID AS QuestionID,
        q.Q_TEXT AS Question,
        q.Q_TYPE AS QuestionType,
        eq.Q_DEGREE AS Marks,
        sa.Student_Answer AS YourAnswer  -- If already answered
    FROM Exam_Question eq
    JOIN question q ON eq.Q_ID = q.Q_ID
    LEFT JOIN Student_Answer sa ON sa.EX_ID = eq.EX_ID 
                                AND sa.Q_ID = eq.Q_ID 
                                AND sa.STD_ID = @StudentID
    WHERE eq.EX_ID = @ExamID
    ORDER BY q.Q_ID;
    
    -- For MCQ questions, get choices
    SELECT 
        qc.Q_ID AS QuestionID,
        qc.Choice_Order AS [option],
        qc.Choice_Text AS ChoiceText
    FROM Question_Choices qc
    WHERE qc.Q_ID IN (SELECT Q_ID FROM Exam_Question WHERE EX_ID = @ExamID)
    ORDER BY qc.Q_ID, qc.Choice_Order;
    
    PRINT 'Exam questions retrieved successfully!';
END
GO











--verfication
EXEC sp_GetExamQuestions 
    @StudentID = 1,
    @ExamID = 1;















































-- 22. AUTO-GRADE ALL EXAMS (System Procedure)
-- what: Automatically grade all MCQ and T/F questions
-- who: System (scheduled job) or Admin
-- Note: Already done in sp_SubmitAnswer, but this is a safety net
GO
CREATE OR ALTER PROCEDURE sp_AutoGradeAllAnswers
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Update all ungraded MCQ and TrueFalse answers
    UPDATE sa
    SET sa.Is_Correct = CASE 
                         WHEN UPPER(LTRIM(RTRIM(sa.Student_Answer))) = 
                              UPPER(LTRIM(RTRIM(q.Correct_Answer))) THEN 1
                         ELSE 0
                        END,
        sa.Obtained_Marks = CASE 
                             WHEN UPPER(LTRIM(RTRIM(sa.Student_Answer))) = 
                                  UPPER(LTRIM(RTRIM(q.Correct_Answer))) THEN eq.Q_DEGREE
                             ELSE 0
                            END
    FROM Student_Answer sa
    JOIN question q ON sa.Q_ID = q.Q_ID
    JOIN Exam_Question eq ON sa.EX_ID = eq.EX_ID AND sa.Q_ID = eq.Q_ID
    WHERE q.Q_TYPE IN ('MCQ', 'TrueFalse')
      AND sa.Is_Correct IS NULL;
    
    DECLARE @UpdatedCount INT = @@ROWCOUNT;
    
    PRINT CAST(@UpdatedCount AS VARCHAR) + ' answers auto-graded.';
END
GO













--verfication
EXEC sp_AutoGradeAllAnswers;













