-- Examination System Database - SQLite3 Schema


-- Note: SQLite doesn't support:
-- - Multiple filegroups
-- - CHECK constraints on table level (use triggers)
-- - Some SQL Server specific types

-- 1. USER AUTHENTICATION

CREATE TABLE IF NOT EXISTS user (
    user_id INTEGER PRIMARY KEY AUTOINCREMENT,
    username TEXT NOT NULL UNIQUE,
    password_hash TEXT NOT NULL,
    role TEXT NOT NULL CHECK(role IN ('student', 'instructor', 'manager', 'admin')),
    is_active INTEGER DEFAULT 1,
    created_date DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- 2. ORGANIZATIONAL STRUCTURE

CREATE TABLE IF NOT EXISTS branch (
    branch_id INTEGER PRIMARY KEY AUTOINCREMENT,
    branch_name TEXT NOT NULL,
    branch_location TEXT
);

CREATE TABLE IF NOT EXISTS track (
    track_id INTEGER PRIMARY KEY AUTOINCREMENT,
    track_name TEXT NOT NULL,
    track_description TEXT
);

CREATE TABLE IF NOT EXISTS branch_track (
    branch_id INTEGER NOT NULL,
    track_id INTEGER NOT NULL,
    start_date DATE,
    PRIMARY KEY (branch_id, track_id),
    FOREIGN KEY (branch_id) REFERENCES branch(branch_id),
    FOREIGN KEY (track_id) REFERENCES track(track_id)
);

CREATE TABLE IF NOT EXISTS intake (
    intake_id INTEGER PRIMARY KEY AUTOINCREMENT,
    intake_name TEXT NOT NULL,
    intake_year INTEGER NOT NULL,
    branch_id INTEGER NOT NULL,
    track_id INTEGER NOT NULL,
    FOREIGN KEY (branch_id) REFERENCES branch(branch_id),
    FOREIGN KEY (track_id) REFERENCES track(track_id),
    FOREIGN KEY (branch_id, track_id) REFERENCES branch_track(branch_id, track_id)
);

-- 3. PEOPLE (Users)

CREATE TABLE IF NOT EXISTS training_manager (
    manager_id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL UNIQUE,
    manager_name TEXT NOT NULL,
    manager_email TEXT NOT NULL UNIQUE,
    manager_phone TEXT,
    FOREIGN KEY (user_id) REFERENCES user(user_id)
);

CREATE TABLE IF NOT EXISTS instructor (
    instructor_id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL UNIQUE,
    instructor_name TEXT NOT NULL,
    instructor_email TEXT NOT NULL UNIQUE,
    instructor_phone TEXT,
    hire_date DATE,
    salary REAL,
    FOREIGN KEY (user_id) REFERENCES user(user_id)
);

CREATE TABLE IF NOT EXISTS student (
    student_id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL UNIQUE,
    student_name TEXT NOT NULL,
    student_email TEXT NOT NULL UNIQUE,
    student_phone TEXT,
    student_address TEXT,
    date_of_birth DATE,
    intake_id INTEGER NOT NULL,
    FOREIGN KEY (user_id) REFERENCES user(user_id),
    FOREIGN KEY (intake_id) REFERENCES intake(intake_id)
);

-- 4. ACADEMIC CONTENT

CREATE TABLE IF NOT EXISTS course (
    course_id INTEGER PRIMARY KEY AUTOINCREMENT,
    course_name TEXT NOT NULL,
    course_description TEXT,
    max_degree INTEGER NOT NULL,
    min_degree INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS instructor_course (
    instructor_id INTEGER NOT NULL,
    course_id INTEGER NOT NULL,
    intake_id INTEGER NOT NULL,
    PRIMARY KEY (instructor_id, course_id, intake_id),
    FOREIGN KEY (instructor_id) REFERENCES instructor(instructor_id),
    FOREIGN KEY (course_id) REFERENCES course(course_id),
    FOREIGN KEY (intake_id) REFERENCES intake(intake_id)
);

-- 5. QUESTION POOL

CREATE TABLE IF NOT EXISTS question (
    question_id INTEGER PRIMARY KEY AUTOINCREMENT,
    question_text TEXT NOT NULL,
    question_type TEXT NOT NULL CHECK(question_type IN ('MCQ', 'TrueFalse', 'Text')),
    correct_answer TEXT,
    course_id INTEGER NOT NULL,
    difficulty_level TEXT CHECK(difficulty_level IN ('Easy', 'Medium', 'Hard')),
    created_by INTEGER NOT NULL,
    created_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (course_id) REFERENCES course(course_id),
    FOREIGN KEY (created_by) REFERENCES instructor(instructor_id)
);

CREATE TABLE IF NOT EXISTS question_choices (
    choice_id INTEGER PRIMARY KEY AUTOINCREMENT,
    question_id INTEGER NOT NULL,
    choice_text TEXT NOT NULL,
    choice_order TEXT NOT NULL,
    FOREIGN KEY (question_id) REFERENCES question(question_id) ON DELETE CASCADE,
    UNIQUE(question_id, choice_order)
);

-- 6. EXAM SYSTEM

CREATE TABLE IF NOT EXISTS exam (
    exam_id INTEGER PRIMARY KEY AUTOINCREMENT,
    exam_type TEXT NOT NULL CHECK(exam_type IN ('Exam', 'Corrective')),
    course_id INTEGER NOT NULL,
    instructor_id INTEGER NOT NULL,
    intake_id INTEGER NOT NULL,
    exam_date DATE NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    total_time INTEGER NOT NULL,
    total_degree INTEGER NOT NULL,
    year INTEGER NOT NULL,
    allowance_options TEXT,
    FOREIGN KEY (course_id) REFERENCES course(course_id),
    FOREIGN KEY (instructor_id) REFERENCES instructor(instructor_id),
    FOREIGN KEY (intake_id) REFERENCES intake(intake_id)
);

CREATE TABLE IF NOT EXISTS exam_question (
    exam_id INTEGER NOT NULL,
    question_id INTEGER NOT NULL,
    question_degree INTEGER NOT NULL,
    PRIMARY KEY (exam_id, question_id),
    FOREIGN KEY (exam_id) REFERENCES exam(exam_id) ON DELETE CASCADE,
    FOREIGN KEY (question_id) REFERENCES question(question_id)
);

-- 7. STUDENT PERFORMANCE

CREATE TABLE IF NOT EXISTS student_exam (
    student_id INTEGER NOT NULL,
    exam_id INTEGER NOT NULL,
    actual_start_time DATETIME,
    actual_end_time DATETIME,
    total_score REAL,
    obtained_degree REAL,
    PRIMARY KEY (student_id, exam_id),
    FOREIGN KEY (student_id) REFERENCES student(student_id),
    FOREIGN KEY (exam_id) REFERENCES exam(exam_id)
);

CREATE TABLE IF NOT EXISTS student_answer (
    answer_id INTEGER PRIMARY KEY AUTOINCREMENT,
    student_id INTEGER NOT NULL,
    exam_id INTEGER NOT NULL,
    question_id INTEGER NOT NULL,
    student_answer TEXT,
    is_correct INTEGER,
    obtained_marks REAL,
    answered_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (student_id) REFERENCES student(student_id),
    FOREIGN KEY (exam_id) REFERENCES exam(exam_id),
    FOREIGN KEY (question_id) REFERENCES question(question_id),
    FOREIGN KEY (student_id, exam_id) REFERENCES student_exam(student_id, exam_id),
    UNIQUE(student_id, exam_id, question_id)
);

-- 8. INDEXES (for performance)

CREATE INDEX IF NOT EXISTS idx_user_username ON user(username);
CREATE INDEX IF NOT EXISTS idx_student_email ON student(student_email);
CREATE INDEX IF NOT EXISTS idx_student_intake ON student(intake_id);
CREATE INDEX IF NOT EXISTS idx_question_course_type ON question(course_id, question_type);
CREATE INDEX IF NOT EXISTS idx_exam_course ON exam(course_id);
CREATE INDEX IF NOT EXISTS idx_exam_intake ON exam(intake_id);
CREATE INDEX IF NOT EXISTS idx_student_exam_student ON student_exam(student_id);
CREATE INDEX IF NOT EXISTS idx_student_answer_exam ON student_answer(student_id, exam_id);

-- 9. INSERT SAMPLE DATA (for testing)

-- Admin user
INSERT INTO user (username, password_hash, role)
VALUES ('admin', 'scrypt:32768:8:1$VHq8RJLqgE0q3Xwd$a7b4d5c6e8f1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b3c4d5e6f7a8b9', 'admin');

-- Sample Branch
INSERT INTO branch (branch_name, branch_location) VALUES ('Cairo Branch', 'Nasr City, Cairo');

-- Sample Track
INSERT INTO track (track_name, track_description) VALUES ('Web Development', 'Full-stack web development');

-- Link Branch-Track
INSERT INTO branch_track (branch_id, track_id, start_date) VALUES (1, 1, '2024-01-01');

-- Sample Intake
INSERT INTO intake (intake_name, intake_year, branch_id, track_id) VALUES ('Intake 45', 2024, 1, 1);

-- Sample Course
INSERT INTO course (course_name, course_description, max_degree, min_degree)
VALUES ('SQL Fundamentals', 'Database design and SQL queries', 100, 50);

PRAGMA foreign_keys = ON;
