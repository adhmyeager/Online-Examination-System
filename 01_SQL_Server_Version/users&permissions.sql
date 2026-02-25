/*
=============================================================================
  EXAMINATION SYSTEM DATABASE
  File: permissions.sql
  Description: Creates SQL Server logins, users, roles, and grants
               role-based permissions for all stored procedures (sp.sql)
               and views (view.sql) in the EX_SYS database.

  4 Roles:
    - AdminRole           ? db_owner (full access)
    - TrainingManagerRole ? manages users, branches, tracks, intakes, students
    - InstructorRole      ? manages questions, exams, grading
    - StudentRole         ? takes exams, views own results

  Run this AFTER:
    1. creation_table.sql  (creates the database and tables)
    2. sp.sql              (creates the stored procedures)
    3. view.sql            (creates the views)
=============================================================================
*/

-- ============================================================================
-- STEP 1: CREATE SQL SERVER LOGINS (run in master context)
-- ============================================================================
USE master;
GO

IF EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'ExamAdmin')
    DROP LOGIN ExamAdmin;
IF EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'ExamTrainingManager')
    DROP LOGIN ExamTrainingManager;
IF EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'ExamInstructor')
    DROP LOGIN ExamInstructor;
IF EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'ExamStudent')
    DROP LOGIN ExamStudent;
GO

CREATE LOGIN ExamAdmin           WITH PASSWORD = 'Admin@123!Secure';
CREATE LOGIN ExamTrainingManager WITH PASSWORD = 'Manager@123!Secure';
CREATE LOGIN ExamInstructor      WITH PASSWORD = 'Instructor@123!Secure';
CREATE LOGIN ExamStudent         WITH PASSWORD = 'Student@123!Secure';
GO

-- ============================================================================
-- STEP 2: CREATE DATABASE USERS
-- ============================================================================
USE EX_SYS;
GO

IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'ExamAdminUser')
    DROP USER ExamAdminUser;
IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'ExamTrainingManagerUser')
    DROP USER ExamTrainingManagerUser;
IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'ExamInstructorUser')
    DROP USER ExamInstructorUser;
IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'ExamStudentUser')
    DROP USER ExamStudentUser;
GO

CREATE USER ExamAdminUser           FOR LOGIN ExamAdmin;
CREATE USER ExamTrainingManagerUser FOR LOGIN ExamTrainingManager;
CREATE USER ExamInstructorUser      FOR LOGIN ExamInstructor;
CREATE USER ExamStudentUser         FOR LOGIN ExamStudent;
GO

-- ============================================================================
-- STEP 3: CREATE DATABASE ROLES
-- ============================================================================

IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'AdminRole' AND type = 'R')
    DROP ROLE AdminRole;
IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'TrainingManagerRole' AND type = 'R')
    DROP ROLE TrainingManagerRole;
IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'InstructorRole' AND type = 'R')
    DROP ROLE InstructorRole;
IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'StudentRole' AND type = 'R')
    DROP ROLE StudentRole;
GO

CREATE ROLE AdminRole;
CREATE ROLE TrainingManagerRole;
CREATE ROLE InstructorRole;
CREATE ROLE StudentRole;
GO

-- Add users to their roles
ALTER ROLE AdminRole           ADD MEMBER ExamAdminUser;
ALTER ROLE TrainingManagerRole ADD MEMBER ExamTrainingManagerUser;
ALTER ROLE InstructorRole      ADD MEMBER ExamInstructorUser;
ALTER ROLE StudentRole         ADD MEMBER ExamStudentUser;
GO

-- Admin gets full database ownership
ALTER ROLE db_owner ADD MEMBER ExamAdminUser;
GO

-- ============================================================================
-- STEP 4: TRAINING MANAGER ROLE PERMISSIONS
-- Who: Training Manager
-- Can: Manage branches, tracks, intakes, students, training managers
--      Read-only on exam/question data for reporting
-- ============================================================================

-- Tables: Full CRUD on structural/user tables
GRANT SELECT, INSERT, UPDATE, DELETE ON branch           TO TrainingManagerRole;
GRANT SELECT, INSERT, UPDATE, DELETE ON track            TO TrainingManagerRole;
GRANT SELECT, INSERT, UPDATE, DELETE ON branch_track     TO TrainingManagerRole;
GRANT SELECT, INSERT, UPDATE, DELETE ON intake           TO TrainingManagerRole;
GRANT SELECT, INSERT, UPDATE, DELETE ON [user]           TO TrainingManagerRole;
GRANT SELECT, INSERT, UPDATE, DELETE ON student          TO TrainingManagerRole;
GRANT SELECT, INSERT, UPDATE, DELETE ON instructor       TO TrainingManagerRole;
GRANT SELECT, INSERT, UPDATE, DELETE ON training_manager TO TrainingManagerRole;
GRANT SELECT, INSERT, UPDATE, DELETE ON course           TO TrainingManagerRole;
GRANT SELECT, INSERT, UPDATE, DELETE ON instructor_Course TO TrainingManagerRole;

-- Tables: Read-only on exam/question tables (for reporting)
GRANT SELECT ON exam             TO TrainingManagerRole;
GRANT SELECT ON question         TO TrainingManagerRole;
GRANT SELECT ON Question_Choices TO TrainingManagerRole;
GRANT SELECT ON Exam_Question    TO TrainingManagerRole;
GRANT SELECT ON Student_Exam     TO TrainingManagerRole;
GRANT SELECT ON Student_Answer   TO TrainingManagerRole;

-- Stored Procedures
GRANT EXECUTE ON sp_AddBranch           TO TrainingManagerRole;
GRANT EXECUTE ON sp_AddTrack            TO TrainingManagerRole;
GRANT EXECUTE ON sp_AssignTrackToBranch TO TrainingManagerRole;
GRANT EXECUTE ON sp_AddIntake           TO TrainingManagerRole;
GRANT EXECUTE ON sp_AddStudent          TO TrainingManagerRole;
GRANT EXECUTE ON sp_AddTrainingManager  TO TrainingManagerRole;

-- Views
GRANT SELECT ON VW_CourseDetails              TO TrainingManagerRole;
GRANT SELECT ON VW_InstructorInfo             TO TrainingManagerRole;
GRANT SELECT ON VW_StudentInfo                TO TrainingManagerRole;
GRANT SELECT ON VW_ExamSummary                TO TrainingManagerRole;
GRANT SELECT ON VW_StudentExamResults         TO TrainingManagerRole;
GRANT SELECT ON VW_QuestionPool               TO TrainingManagerRole;
GRANT SELECT ON VW_InstructorCourseAssignment TO TrainingManagerRole;
GRANT SELECT ON VW_StudentAnswerDetails       TO TrainingManagerRole;
GRANT SELECT ON VW_TrackBranchSummary         TO TrainingManagerRole;
GRANT SELECT ON VW_IntakeSummary              TO TrainingManagerRole;
GO

-- ============================================================================
-- STEP 5: INSTRUCTOR ROLE PERMISSIONS
-- Who: Instructor
-- Can: Manage questions, create/manage exams, grade text answers
--      Read-only on student/user/lookup data
-- ============================================================================

-- Tables: Read-only on lookup and user tables
GRANT SELECT ON branch           TO InstructorRole;
GRANT SELECT ON track            TO InstructorRole;
GRANT SELECT ON branch_track     TO InstructorRole;
GRANT SELECT ON intake           TO InstructorRole;
GRANT SELECT ON [user]           TO InstructorRole;
GRANT SELECT ON student          TO InstructorRole;
GRANT SELECT ON instructor       TO InstructorRole;
GRANT SELECT ON training_manager TO InstructorRole;
GRANT SELECT ON course           TO InstructorRole;
GRANT SELECT ON instructor_Course TO InstructorRole;

-- Tables: Full CRUD on questions and exam management
GRANT SELECT, INSERT, UPDATE         ON question         TO InstructorRole;
GRANT SELECT, INSERT, UPDATE, DELETE ON Question_Choices TO InstructorRole;
GRANT SELECT, INSERT, UPDATE         ON exam             TO InstructorRole;
GRANT SELECT, INSERT, UPDATE, DELETE ON Exam_Question    TO InstructorRole;
GRANT SELECT, INSERT, UPDATE         ON Student_Exam     TO InstructorRole;
GRANT SELECT, UPDATE                 ON Student_Answer   TO InstructorRole;

-- Stored Procedures
GRANT EXECUTE ON sp_AddQuestion              TO InstructorRole;
GRANT EXECUTE ON sp_AddQuestionChoice        TO InstructorRole;
GRANT EXECUTE ON sp_CreateExam               TO InstructorRole;
GRANT EXECUTE ON sp_AddQuestionToExam        TO InstructorRole;
GRANT EXECUTE ON sp_AddRandomQuestionsToExam TO InstructorRole;
GRANT EXECUTE ON sp_AssignStudentsToExam     TO InstructorRole;
GRANT EXECUTE ON sp_GradeTextAnswer          TO InstructorRole;
GRANT EXECUTE ON sp_RecalculateExamScore     TO InstructorRole;
GRANT EXECUTE ON sp_ViewExamResults          TO InstructorRole;
GRANT EXECUTE ON sp_AutoGradeAllAnswers      TO InstructorRole;

-- Views
GRANT SELECT ON VW_CourseDetails              TO InstructorRole;
GRANT SELECT ON VW_InstructorInfo             TO InstructorRole;
GRANT SELECT ON VW_StudentInfo                TO InstructorRole;
GRANT SELECT ON VW_ExamSummary                TO InstructorRole;
GRANT SELECT ON VW_StudentExamResults         TO InstructorRole;
GRANT SELECT ON VW_QuestionPool               TO InstructorRole;
GRANT SELECT ON VW_InstructorCourseAssignment TO InstructorRole;
GRANT SELECT ON VW_StudentAnswerDetails       TO InstructorRole;
GRANT SELECT ON VW_TrackBranchSummary         TO InstructorRole;
GRANT SELECT ON VW_IntakeSummary              TO InstructorRole;
GO

-- ============================================================================
-- STEP 6: STUDENT ROLE PERMISSIONS
-- Who: Student
-- Can: Start exam, submit answers, submit exam, view own results
-- ============================================================================

-- Tables: Read-only on limited tables
GRANT SELECT ON [user]           TO StudentRole;
GRANT SELECT ON student          TO StudentRole;
GRANT SELECT ON course           TO StudentRole;
GRANT SELECT ON intake           TO StudentRole;
GRANT SELECT ON branch           TO StudentRole;
GRANT SELECT ON track            TO StudentRole;

-- Tables: Read exam data
GRANT SELECT ON exam             TO StudentRole;
GRANT SELECT ON Exam_Question    TO StudentRole;
GRANT SELECT ON question         TO StudentRole;
GRANT SELECT ON Question_Choices TO StudentRole;

-- Tables: Read own exam records + submit answers
GRANT SELECT                 ON Student_Exam   TO StudentRole;
GRANT SELECT, INSERT, UPDATE ON Student_Answer TO StudentRole;

-- Stored Procedures
GRANT EXECUTE ON sp_StartExam        TO StudentRole;
GRANT EXECUTE ON sp_GetExamQuestions TO StudentRole;
GRANT EXECUTE ON sp_SubmitAnswer     TO StudentRole;
GRANT EXECUTE ON sp_SubmitExam       TO StudentRole;
GRANT EXECUTE ON sp_ViewExamResults  TO StudentRole;
GRANT EXECUTE ON sp_ViewMyExams      TO StudentRole;

-- Views
GRANT SELECT ON VW_StudentExamResults TO StudentRole;
GRANT SELECT ON VW_StudentInfo        TO StudentRole;
GRANT SELECT ON VW_IntakeSummary      TO StudentRole;
GO

-- ============================================================================
-- VERIFICATION
-- ============================================================================
PRINT '=== Permissions applied successfully! ===';
PRINT '';
PRINT 'Login Credentials:';
PRINT '  Admin:            ExamAdmin           / Admin@123!Secure';
PRINT '  Training Manager: ExamTrainingManager / Manager@123!Secure';
PRINT '  Instructor:       ExamInstructor      / Instructor@123!Secure';
PRINT '  Student:          ExamStudent         / Student@123!Secure';
PRINT '';
PRINT 'Roles:';
PRINT '  AdminRole           : db_owner (full access)';
PRINT '  TrainingManagerRole : branch/track/intake/student management';
PRINT '  InstructorRole      : question/exam management + grading';
PRINT '  StudentRole         : start/submit exam + view own results';
GO


-- Run this to verify all grants:
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
ORDER BY dp.name, o.name, p.permission_name;
