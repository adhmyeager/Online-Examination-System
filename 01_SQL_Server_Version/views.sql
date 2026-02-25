/* =====================================================
   View 1: Complete Course Information (Optimized)
   Description:
   - Lists all courses with their description, max/min degrees.
   - Calculates total number of questions per course.
   - Calculates total number of exams per course.
===================================================== */
CREATE OR ALTER VIEW VW_CourseDetails
AS
SELECT 
    C.CRS_ID, 
    C.CRS_NAME, 
    C.CRS_DESC, 
    C.Max_Degree, 
    C.Min_Degree,
    (SELECT COUNT(*) FROM question Q WHERE Q.CRS_ID = C.CRS_ID) AS TotalQuestions,
    (SELECT COUNT(*) FROM exam E WHERE E.CRS_ID = C.CRS_ID) AS TotalExams
FROM course C;
GO

/* =====================================================
   View 2: Instructor Complete Information (Optimized)
   Description:
   - Lists all instructors with contact info.
   - Shows total courses assigned.
   - Shows total exams conducted.
===================================================== */
CREATE OR ALTER VIEW VW_InstructorInfo
AS
SELECT 
    I.INS_ID, 
    I.INS_NAME AS FullName,
    I.INS_EMAIL, 
    I.INS_PHONE, 
    I.Hire_Date,
    (SELECT COUNT(*) FROM instructor_Course IC WHERE IC.INS_ID = I.INS_ID) AS TotalCourses,
    (SELECT COUNT(*) FROM exam E WHERE E.INS_ID = I.INS_ID) AS TotalExams
FROM instructor I;
GO

/* =====================================================
   View 3: Student Complete Information (Optimized)
   Description:
   - Shows all students with personal info and intake details.
   - Calculates total exams taken.
   - Computes average degree across exams.
===================================================== */
CREATE OR ALTER VIEW VW_StudentInfo
AS
SELECT 
    S.STD_ID, 
    S.STD_NAME,
    S.STD_EMAIL, 
    S.STD_PHONE,
    S.DOB,
    INTAKE.IN_NAME AS IntakeName,
    BRANCH.BR_NAME AS BranchName,
    TRACK.TR_NAME AS TrackName,
    COUNT(DISTINCT SE.EX_ID) AS TotalExamsTaken,
    CAST(ISNULL(AVG(SE.Total_Score),0) AS DECIMAL(6,2)) AS AverageDegree
FROM student S
LEFT JOIN intake INTAKE ON S.IN_ID = INTAKE.IN_ID
LEFT JOIN branch BRANCH ON INTAKE.BR_ID = BRANCH.BR_ID
LEFT JOIN track TRACK ON INTAKE.TR_ID = TRACK.TR_ID
LEFT JOIN Student_Exam SE ON S.STD_ID = SE.STD_ID
GROUP BY 
    S.STD_ID, S.STD_NAME, S.STD_EMAIL, S.STD_PHONE, S.DOB,
    INTAKE.IN_NAME, BRANCH.BR_NAME, TRACK.TR_NAME;
GO

/* =====================================================
   View 4: Exam Summary
   Description:
   - Provides overview of each exam.
   - Shows course, instructor, intake, branch, track info.
   - Includes total questions, total possible score, and students count.
===================================================== */
CREATE OR ALTER VIEW VW_ExamSummary
AS
SELECT 
    E.EX_ID, 
    C.CRS_NAME, 
    I.INS_NAME AS InstructorName,
    E.Year, 
    E.EX_TYPE, 
    E.Start_Time, 
    E.End_Time, 
    E.Total_Time,
    INTAKE.IN_NAME AS IntakeName,
    BRANCH.BR_NAME AS BranchName,
    TRACK.TR_NAME AS TrackName,
    (SELECT COUNT(*) FROM Exam_Question EQ WHERE EQ.EX_ID = E.EX_ID) AS TotalQuestions,
    ISNULL((SELECT SUM(Q_DEGREE) FROM Exam_Question EQ WHERE EQ.EX_ID = E.EX_ID),0) AS TotalDegree,
    (SELECT COUNT(DISTINCT STD_ID) FROM Student_Exam SE WHERE SE.EX_ID = E.EX_ID) AS TotalStudents
FROM exam E
INNER JOIN course C ON E.CRS_ID = C.CRS_ID
INNER JOIN instructor I ON E.INS_ID = I.INS_ID
INNER JOIN intake INTAKE ON E.IN_ID = INTAKE.IN_ID
INNER JOIN branch BRANCH ON INTAKE.BR_ID = BRANCH.BR_ID
INNER JOIN track TRACK ON INTAKE.TR_ID = TRACK.TR_ID;
GO

/* =====================================================
   View 5: Student Exam Results
   Description:
   - Shows student's exam score and status.
   - Computes percentage based on max degree.
   - Shows 'Pass', 'Fail', or 'Not Submitted'.
===================================================== */
CREATE OR ALTER VIEW VW_StudentExamResults
AS
SELECT 
    S.STD_ID, 
    S.STD_NAME AS StudentName,
    C.CRS_NAME, 
    E.EX_TYPE, 
    E.Year,
    SE.Total_Score, 
    C.Max_Degree, 
    C.Min_Degree,
    SE.Actual_End_Time AS SubmitTime,
    CASE 
        WHEN SE.Total_Score IS NULL THEN 'Not Submitted'
        WHEN SE.Total_Score >= C.Min_Degree THEN 'Pass'
        ELSE 'Fail'
    END AS Status,
    CASE 
        WHEN SE.Total_Score IS NOT NULL 
        THEN CAST((SE.Total_Score * 100.0 / NULLIF(C.Max_Degree,0)) AS DECIMAL(6,2))
        ELSE NULL
    END AS Percentage
FROM Student_Exam SE
INNER JOIN student S ON SE.STD_ID = S.STD_ID
INNER JOIN exam E ON SE.EX_ID = E.EX_ID
INNER JOIN course C ON E.CRS_ID = C.CRS_ID;
GO

/* =====================================================
   View 6: Question Pool
   Description:
   - Lists all questions along with course.
   - Includes MCQ choices and correct answer if applicable.
===================================================== */
CREATE OR ALTER VIEW VW_QuestionPool
AS
SELECT 
    Q.Q_ID, 
    Q.Q_TEXT, 
    Q.Q_TYPE,
    C.CRS_NAME, 
    C.CRS_ID,
    QC.Choice_Text AS MCQ_Choice, 
    QC.Choice_Order,
    Q.Correct_Answer AS MCQ_CorrectAnswer
FROM question Q
INNER JOIN course C 
    ON Q.CRS_ID = C.CRS_ID
LEFT JOIN Question_Choices QC 
    ON Q.Q_ID = QC.Q_ID;
GO

/* =====================================================
   View 7: Instructor Course Assignment
   Description:
   - Shows which instructor teaches which course.
   - Includes intake ID for academic planning.
===================================================== */
CREATE OR ALTER VIEW VW_InstructorCourseAssignment
AS
SELECT 
    IC.INS_ID, 
    I.INS_NAME AS InstructorName,
    C.CRS_ID,
    C.CRS_NAME, 
    IC.IN_ID AS IntakeID
FROM instructor_Course IC
INNER JOIN instructor I 
    ON IC.INS_ID = I.INS_ID
INNER JOIN course C 
    ON IC.CRS_ID = C.CRS_ID;
GO

/* =====================================================
   View 8: Student Answer Details
   Description:
   - Detailed answers submitted by students.
   - Shows question text, type, obtained marks, max degree.
===================================================== */
CREATE OR ALTER VIEW VW_StudentAnswerDetails
AS
SELECT 
    SA.ANS_ID, 
    SA.STD_ID,
    S.STD_NAME AS StudentName,
    SA.EX_ID,
    C.CRS_NAME, 
    E.EX_TYPE,
    Q.Q_ID,
    Q.Q_TEXT, 
    Q.Q_TYPE,
    SA.Student_Answer, 
    SA.Is_Correct, 
    SA.Obtained_Marks,
    EQ.Q_DEGREE AS MaxDegree
FROM Student_Answer SA
INNER JOIN Student_Exam SE 
    ON SA.STD_ID = SE.STD_ID 
    AND SA.EX_ID = SE.EX_ID
INNER JOIN student S 
    ON SE.STD_ID = S.STD_ID
INNER JOIN exam E 
    ON SE.EX_ID = E.EX_ID
INNER JOIN course C 
    ON E.CRS_ID = C.CRS_ID
INNER JOIN question Q 
    ON SA.Q_ID = Q.Q_ID
INNER JOIN Exam_Question EQ 
    ON E.EX_ID = EQ.EX_ID 
    AND Q.Q_ID = EQ.Q_ID;
GO

/* =====================================================
   View 9: Track & Branch Summary
   Description:
   - Shows all tracks in each branch.
   - Counts total students in each track per branch.
   - Useful for administrative planning.
===================================================== */
CREATE OR ALTER VIEW VW_TrackBranchSummary
AS
SELECT 
    B.BR_ID, 
    B.BR_NAME, 
    B.BR_LOC AS Location,
    T.TR_ID, 
    T.TR_NAME,
    COUNT(DISTINCT S.STD_ID) AS TotalStudents
FROM branch B
INNER JOIN branch_track BT 
    ON B.BR_ID = BT.BR_ID
INNER JOIN track T 
    ON BT.TR_ID = T.TR_ID
LEFT JOIN intake I 
    ON I.BR_ID = B.BR_ID 
    AND I.TR_ID = T.TR_ID
LEFT JOIN student S 
    ON S.IN_ID = I.IN_ID
GROUP BY 
    B.BR_ID, B.BR_NAME, B.BR_LOC, 
    T.TR_ID, T.TR_NAME;
GO

/* =====================================================
   View 10: Intake Summary
   Description:
   - Shows all intakes with total students.
   - Determines status: Upcoming, Active, Completed.
===================================================== */
CREATE OR ALTER VIEW VW_IntakeSummary
AS
SELECT 
    I.IN_ID, 
    I.IN_NAME, 
    I.IN_year,
    COUNT(DISTINCT S.STD_ID) AS TotalStudents,
    CASE 
        WHEN YEAR(GETDATE()) < I.IN_year THEN 'Upcoming'
        WHEN YEAR(GETDATE()) = I.IN_year THEN 'Active'
        ELSE 'Completed'
    END AS Status
FROM intake I
LEFT JOIN student S ON I.IN_ID = S.IN_ID
GROUP BY I.IN_ID, I.IN_NAME, I.IN_year;
GO

