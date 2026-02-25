

USE EX_SYS;
GO

PRINT '============================================================';
PRINT '  EX_SYS - STORED PROCEDURE & PERMISSION TESTS';
PRINT '============================================================';
PRINT '';
GO

-- ============================================================================
-- SECTION 1: TRAINING MANAGER STORED PROCEDURES
-- ============================================================================
PRINT '------------------------------------------------------------';
PRINT 'SECTION 1: TRAINING MANAGER SPs';
PRINT '------------------------------------------------------------';
GO

-- 1.1 sp_AddBranch
PRINT '>> TEST: sp_AddBranch (add new branch)';
DECLARE @NewBranchID INT;
EXEC sp_AddBranch
    @BranchName     = 'Test Branch',
    @BranchLocation = 'Test City',
    @NewBranchID    = @NewBranchID OUTPUT;
PRINT '   Result: New Branch ID = ' + CAST(@NewBranchID AS VARCHAR);
GO

-- 1.2 sp_AddBranch duplicate (should fail gracefully)
PRINT '>> TEST: sp_AddBranch duplicate (expect: Branch name already exists!)';
DECLARE @DupBranchID INT;
EXEC sp_AddBranch
    @BranchName     = 'Test Branch',
    @BranchLocation = 'Anywhere',
    @NewBranchID    = @DupBranchID OUTPUT;
GO

-- 1.3 sp_AddTrack
PRINT '>> TEST: sp_AddTrack (add new track)';
DECLARE @NewTrackID INT;
EXEC sp_AddTrack
    @TrackName        = 'Test Track',
    @TrackDescription = 'Testing track',
    @NewTrackID       = @NewTrackID OUTPUT;
PRINT '   Result: New Track ID = ' + CAST(@NewTrackID AS VARCHAR);
GO

-- 1.4 sp_AssignTrackToBranch
PRINT '>> TEST: sp_AssignTrackToBranch (assign track 1 to branch 1)';
-- Use existing data: branch 1 = Cairo Branch, track 1 = Web Development
-- This may already exist, so we expect either success or "already assigned"
EXEC sp_AssignTrackToBranch
    @BranchID  = 1,
    @TrackID   = 1,
    @StartDate = '2024-01-01';
GO

-- 1.5 sp_AddIntake
PRINT '>> TEST: sp_AddIntake (add new intake)';
DECLARE @NewIntakeID INT;
EXEC sp_AddIntake
    @IntakeName  = 'Test Intake 99',
    @IntakeYear  = 2024,
    @BranchID    = 1,
    @TrackID     = 1,
    @NewIntakeID = @NewIntakeID OUTPUT;
PRINT '   Result: New Intake ID = ' + CAST(@NewIntakeID AS VARCHAR);
GO

-- 1.6 sp_AddTrainingManager
PRINT '>> TEST: sp_AddTrainingManager (add new manager)';
DECLARE @NewMgrID INT;
EXEC sp_AddTrainingManager
    @Username     = 'test_mgr_99',
    @Password     = 'Pass@123',
    @ManagerName  = 'Test Manager',
    @Email        = 'testmgr99@iti.gov.eg',
    @Phone        = '01099999999',
    @NewManagerID = @NewMgrID OUTPUT;
PRINT '   Result: New Manager ID = ' + CAST(@NewMgrID AS VARCHAR);
GO

-- 1.7 sp_AddStudent
PRINT '>> TEST: sp_AddStudent (add new student)';
DECLARE @NewStdID INT;
EXEC sp_AddStudent
    @Username      = 'test_std_99',
    @Password      = 'Pass@123',
    @StudentName   = 'Test Student',
    @Email         = 'teststd99@gmail.com',
    @Phone         = '01088888888',
    @Address       = '99 Test St, Cairo',
    @DateOfBirth   = '2000-01-01',
    @IntakeID      = 1,
    @NewStudentID  = @NewStdID OUTPUT;
PRINT '   Result: New Student ID = ' + CAST(@NewStdID AS VARCHAR);
GO

PRINT '';
PRINT '------------------------------------------------------------';
PRINT 'SECTION 2: INSTRUCTOR STORED PROCEDURES';
PRINT '------------------------------------------------------------';
GO

-- 2.1 sp_AddQuestion (MCQ)
PRINT '>> TEST: sp_AddQuestion - MCQ (instructor 7 teaches course 1)';
DECLARE @NewQID INT;
EXEC sp_AddQuestion
    @QuestionText  = 'What does HTML stand for?',
    @QuestionType  = 'MCQ',
    @CorrectAnswer = 'b',
    @CourseID      = 1,
    @InstructorID  = 7,
    @NewQuestionID = @NewQID OUTPUT;
PRINT '   Result: New Question ID = ' + CAST(@NewQID AS VARCHAR);
GO

-- 2.2 sp_AddQuestionChoice
PRINT '>> TEST: sp_AddQuestionChoice (add choices to last MCQ question)';
DECLARE @LastQID INT;
SELECT @LastQID = MAX(Q_ID) FROM question WHERE Q_TYPE = 'MCQ' AND CRS_ID = 1;
EXEC sp_AddQuestionChoice @QuestionID = @LastQID, @ChoiceText = 'Hyper Text Markup Language', @ChoiceOrder = 'a';
EXEC sp_AddQuestionChoice @QuestionID = @LastQID, @ChoiceText = 'High Tech Modern Language',  @ChoiceOrder = 'b';
EXEC sp_AddQuestionChoice @QuestionID = @LastQID, @ChoiceText = 'Hyper Transfer Markup Logic', @ChoiceOrder = 'c';
EXEC sp_AddQuestionChoice @QuestionID = @LastQID, @ChoiceText = 'None of the above',           @ChoiceOrder = 'd';
PRINT '   Result: 4 choices added to Question ID ' + CAST(@LastQID AS VARCHAR);
GO

-- 2.3 sp_AddQuestion (TrueFalse)
PRINT '>> TEST: sp_AddQuestion - TrueFalse';
DECLARE @NewTFQID INT;
EXEC sp_AddQuestion
    @QuestionText  = 'CSS stands for Cascading Style Sheets.',
    @QuestionType  = 'TrueFalse',
    @CorrectAnswer = 'a',
    @CourseID      = 1,
    @InstructorID  = 7,
    @NewQuestionID = @NewTFQID OUTPUT;
PRINT '   Result: New TrueFalse Question ID = ' + CAST(@NewTFQID AS VARCHAR);
GO

-- 2.4 sp_CreateExam
PRINT '>> TEST: sp_CreateExam (instructor 7, course 1, intake 1)';
DECLARE @NewExamID INT;
EXEC sp_CreateExam
    @ExamType      = 'Exam',
    @CourseID      = 1,
    @InstructorID  = 7,
    @IntakeID      = 1,
    @ExamDate      = '2024-06-01',
    @StartTime     = '09:00:00',
    @EndTime       = '11:00:00',
    @TotalTime     = 120,
    @TotalDegree   = 100,
    @Year          = 2024,
    @NewExamID     = @NewExamID OUTPUT;
PRINT '   Result: New Exam ID = ' + CAST(@NewExamID AS VARCHAR);
GO

-- 2.5 sp_AddQuestionToExam
PRINT '>> TEST: sp_AddQuestionToExam (add questions to new exam)';
DECLARE @TestExamID INT;
SELECT @TestExamID = MAX(EX_ID) FROM exam WHERE CRS_ID = 1 AND INS_ID = 7;
-- Add 5 existing questions from course 1
EXEC sp_AddQuestionToExam @ExamID = @TestExamID, @QuestionID = 1,  @QuestionDegree = 20;
EXEC sp_AddQuestionToExam @ExamID = @TestExamID, @QuestionID = 2,  @QuestionDegree = 20;
EXEC sp_AddQuestionToExam @ExamID = @TestExamID, @QuestionID = 3,  @QuestionDegree = 20;
EXEC sp_AddQuestionToExam @ExamID = @TestExamID, @QuestionID = 6,  @QuestionDegree = 20;
EXEC sp_AddQuestionToExam @ExamID = @TestExamID, @QuestionID = 7,  @QuestionDegree = 20;
PRINT '   Result: 5 questions added to Exam ID ' + CAST(@TestExamID AS VARCHAR);
GO

-- 2.6 sp_AssignStudentsToExam
PRINT '>> TEST: sp_AssignStudentsToExam (assign students 1,6,9 to new exam)';
DECLARE @TestExamID2 INT;
SELECT @TestExamID2 = MAX(EX_ID) FROM exam WHERE CRS_ID = 1 AND INS_ID = 7;
-- sp_AssignStudentsToExam assigns ALL students from the exam's intake (no @StudentID param)
EXEC sp_AssignStudentsToExam @ExamID = @TestExamID2;
PRINT '   Result: All intake students assigned to Exam ID ' + CAST(@TestExamID2 AS VARCHAR);
GO

PRINT '';
PRINT '------------------------------------------------------------';
PRINT 'SECTION 3: STUDENT STORED PROCEDURES';
PRINT '------------------------------------------------------------';
GO

-- 3.1 sp_StartExam
PRINT '>> TEST: sp_StartExam (student 1 starts the new exam)';
DECLARE @TestExamID3 INT;
SELECT @TestExamID3 = MAX(EX_ID) FROM exam WHERE CRS_ID = 1 AND INS_ID = 7;
EXEC sp_StartExam @StudentID = 1, @ExamID = @TestExamID3;
PRINT '   Result: Student 1 started Exam ID ' + CAST(@TestExamID3 AS VARCHAR);
GO

-- 3.2 sp_GetExamQuestions
PRINT '>> TEST: sp_GetExamQuestions (student 1 gets questions for new exam)';
DECLARE @TestExamID4 INT;
SELECT @TestExamID4 = MAX(EX_ID) FROM exam WHERE CRS_ID = 1 AND INS_ID = 7;
EXEC sp_GetExamQuestions @StudentID = 1, @ExamID = @TestExamID4;
GO

-- 3.3 sp_SubmitAnswer (answer 5 questions)
PRINT '>> TEST: sp_SubmitAnswer (student 1 submits answers)';
DECLARE @TestExamID5 INT;
SELECT @TestExamID5 = MAX(EX_ID) FROM exam WHERE CRS_ID = 1 AND INS_ID = 7;
EXEC sp_SubmitAnswer @StudentID = 1, @ExamID = @TestExamID5, @QuestionID = 1, @StudentAnswer = 'a';
EXEC sp_SubmitAnswer @StudentID = 1, @ExamID = @TestExamID5, @QuestionID = 2, @StudentAnswer = 'd';
EXEC sp_SubmitAnswer @StudentID = 1, @ExamID = @TestExamID5, @QuestionID = 3, @StudentAnswer = 'a';
EXEC sp_SubmitAnswer @StudentID = 1, @ExamID = @TestExamID5, @QuestionID = 6, @StudentAnswer = 'a';
EXEC sp_SubmitAnswer @StudentID = 1, @ExamID = @TestExamID5, @QuestionID = 7, @StudentAnswer = 'b';
PRINT '   Result: 5 answers submitted';
GO

-- 3.4 sp_SubmitExam
PRINT '>> TEST: sp_SubmitExam (student 1 submits exam)';
DECLARE @TestExamID6 INT;
SELECT @TestExamID6 = MAX(EX_ID) FROM exam WHERE CRS_ID = 1 AND INS_ID = 7;
EXEC sp_SubmitExam @StudentID = 1, @ExamID = @TestExamID6;
GO

-- 3.5 sp_ViewMyExams
PRINT '>> TEST: sp_ViewMyExams (student 1 views their exams)';
EXEC sp_ViewMyExams @StudentID = 1;
GO

-- 3.6 sp_ViewExamResults
PRINT '>> TEST: sp_ViewExamResults (student 1 views results for new exam)';
DECLARE @TestExamID7 INT;
SELECT @TestExamID7 = MAX(EX_ID) FROM exam WHERE CRS_ID = 1 AND INS_ID = 7;
EXEC sp_ViewExamResults @StudentID = 1, @ExamID = @TestExamID7;
GO

PRINT '';
PRINT '------------------------------------------------------------';
PRINT 'SECTION 4: INSTRUCTOR GRADING SPs';
PRINT '------------------------------------------------------------';
GO

-- 4.1 sp_AutoGradeAllAnswers
PRINT '>> TEST: sp_AutoGradeAllAnswers (auto-grade MCQ/TrueFalse for new exam)';
-- sp_AutoGradeAllAnswers takes no parameters - grades ALL pending answers in the DB
EXEC sp_AutoGradeAllAnswers;
GO

-- 4.2 sp_RecalculateExamScore
PRINT '>> TEST: sp_RecalculateExamScore (recalculate score for student 1)';
DECLARE @TestExamID9 INT;
SELECT @TestExamID9 = MAX(EX_ID) FROM exam WHERE CRS_ID = 1 AND INS_ID = 7;
EXEC sp_RecalculateExamScore @StudentID = 1, @ExamID = @TestExamID9;
GO

-- 4.3 sp_ViewExamResults (instructor view - all students)
PRINT '>> TEST: sp_ViewExamResults (view all results for new exam)';
DECLARE @TestExamID10 INT;
SELECT @TestExamID10 = MAX(EX_ID) FROM exam WHERE CRS_ID = 1 AND INS_ID = 7;
EXEC sp_ViewExamResults @StudentID = NULL, @ExamID = @TestExamID10;
GO

PRINT '';
PRINT '------------------------------------------------------------';
PRINT 'SECTION 5: VIEWS TEST';
PRINT '------------------------------------------------------------';
GO

PRINT '>> TEST: VW_CourseDetails';
SELECT TOP 5 * FROM VW_CourseDetails;
GO

PRINT '>> TEST: VW_InstructorInfo';
SELECT TOP 5 * FROM VW_InstructorInfo;
GO

PRINT '>> TEST: VW_StudentInfo';
SELECT TOP 5 * FROM VW_StudentInfo;
GO

PRINT '>> TEST: VW_ExamSummary';
SELECT TOP 5 * FROM VW_ExamSummary;
GO

PRINT '>> TEST: VW_StudentExamResults';
SELECT TOP 5 * FROM VW_StudentExamResults;
GO

PRINT '>> TEST: VW_QuestionPool';
SELECT TOP 5 * FROM VW_QuestionPool;
GO

PRINT '>> TEST: VW_InstructorCourseAssignment';
SELECT TOP 5 * FROM VW_InstructorCourseAssignment;
GO

PRINT '>> TEST: VW_TrackBranchSummary';
SELECT TOP 5 * FROM VW_TrackBranchSummary;
GO

PRINT '>> TEST: VW_IntakeSummary';
SELECT TOP 5 * FROM VW_IntakeSummary;
GO

PRINT '';
PRINT '------------------------------------------------------------';
PRINT 'SECTION 6: PERMISSION CHECKS';
PRINT '------------------------------------------------------------';
GO

-- Check what permissions each role has on SPs and views
PRINT '>> Permissions granted to each role:';
SELECT
    dp.name          AS RoleName,
    o.name           AS ObjectName,
    o.type_desc      AS ObjectType,
    p.permission_name,
    p.state_desc     AS GrantState
FROM sys.database_permissions p
JOIN sys.database_principals dp ON p.grantee_principal_id = dp.principal_id
JOIN sys.objects o              ON p.major_id = o.object_id
WHERE dp.name IN ('TrainingManagerRole', 'InstructorRole', 'StudentRole')
ORDER BY dp.name, o.type_desc, o.name, p.permission_name;
GO

-- Count permissions per role
PRINT '>> Permission count per role:';
SELECT
    dp.name AS RoleName,
    o.type_desc AS ObjectType,
    COUNT(*) AS PermissionCount
FROM sys.database_permissions p
JOIN sys.database_principals dp ON p.grantee_principal_id = dp.principal_id
JOIN sys.objects o              ON p.major_id = o.object_id
WHERE dp.name IN ('TrainingManagerRole', 'InstructorRole', 'StudentRole')
GROUP BY dp.name, o.type_desc
ORDER BY dp.name, o.type_desc;
GO

PRINT '';
PRINT '------------------------------------------------------------';
PRINT 'SECTION 7: DATA SANITY CHECK';
PRINT '------------------------------------------------------------';
GO

PRINT '>> Row counts per table:';
SELECT 'user'             AS TableName, COUNT(*) AS [RowCount] FROM [user]           UNION ALL
SELECT 'branch',                        COUNT(*)              FROM branch            UNION ALL
SELECT 'track',                         COUNT(*)              FROM track             UNION ALL
SELECT 'branch_track',                  COUNT(*)              FROM branch_track      UNION ALL
SELECT 'intake',                        COUNT(*)              FROM intake            UNION ALL
SELECT 'course',                        COUNT(*)              FROM course            UNION ALL
SELECT 'instructor',                    COUNT(*)              FROM instructor        UNION ALL
SELECT 'training_manager',              COUNT(*)              FROM training_manager  UNION ALL
SELECT 'student',                       COUNT(*)              FROM student           UNION ALL
SELECT 'instructor_Course',             COUNT(*)              FROM instructor_Course UNION ALL
SELECT 'exam',                          COUNT(*)              FROM exam              UNION ALL
SELECT 'question',                      COUNT(*)              FROM question          UNION ALL
SELECT 'Question_Choices',              COUNT(*)              FROM Question_Choices  UNION ALL
SELECT 'Exam_Question',                 COUNT(*)              FROM Exam_Question     UNION ALL
SELECT 'Student_Exam',                  COUNT(*)              FROM Student_Exam      UNION ALL
SELECT 'Student_Answer',                COUNT(*)              FROM Student_Answer;
GO

PRINT '';
PRINT '============================================================';
PRINT '  ALL TESTS COMPLETE';
PRINT '  Review any red error messages above for failures.';
PRINT '============================================================';
GO
