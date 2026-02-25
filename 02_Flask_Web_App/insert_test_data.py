"""
Insert Test Data for Examination System
Run this script to populate database with test users and data
"""

import sqlite3
from werkzeug.security import generate_password_hash

# Connect to database
conn = sqlite3.connect('exam_system.db')
cursor = conn.cursor()

print("=" * 50)
print("Adding Test Data to Database...")
print("=" * 50)




# Clear existing test users
cursor.execute("DELETE FROM user")
cursor.execute("DELETE FROM training_manager")
cursor.execute("DELETE FROM instructor")
cursor.execute("DELETE FROM student")
conn.commit()

# 1. CREATE ADMIN USER

print("\n[1/11] Creating admin user...")

cursor.execute("""
    INSERT INTO user (username, password_hash, role, is_active)
    VALUES (?, ?, 'admin', 1)
""", ('admin', generate_password_hash('admin123')))

print("✓ Admin created: username='admin', password='admin123'")

# 2. CREATE TRAINING MANAGER


cursor.execute("SELECT * FROM user WHERE username = ?", ('manager1',))
if not cursor.fetchone():
    cursor.execute("""
        INSERT INTO user (username, password_hash, role, is_active)
        VALUES (?, ?, 'manager', 1)
    """, ('manager1', generate_password_hash('manager123')))
    manager_user_id = cursor.lastrowid
else:
    cursor.execute("SELECT user_id FROM user WHERE username = ?", ('manager1',))
    manager_user_id = cursor.fetchone()[0]

# Update training manager name/email/phone
cursor.execute("""
    INSERT OR REPLACE INTO training_manager (user_id, manager_name, manager_email, manager_phone)
    VALUES (?, 'Mahmoud Ouf', 'mahmoud.ouf@iti.gov.eg', '01098765432')
""", (manager_user_id,))
print("✓ Training Manager created/updated: Mahmoud Ouf")

# 3. CREATE INSTRUCTORS

print("\n[3/11] Creating instructors...")

# Instructor 1
cursor.execute("""
    INSERT INTO user (username, password_hash, role, is_active)
    VALUES (?, ?, 'instructor', 1)
""", ('instructor1', generate_password_hash('instructor123')))

instructor1_user_id = cursor.lastrowid

cursor.execute("""
    INSERT INTO instructor (user_id, instructor_name, instructor_email, instructor_phone, hire_date, salary)
    VALUES (?, 'eng/alyaa', 'alyaa.khaled@iti.gov.eg', '0118659595', '2020-09-01', 15000.00)
""", (instructor1_user_id,))

instructor1_id = cursor.lastrowid

# Instructor 2
cursor.execute("""
    INSERT INTO user (username, password_hash, role, is_active)
    VALUES (?, ?, 'instructor', 1)
""", ('instructor2', generate_password_hash('instructor123')))

instructor2_user_id = cursor.lastrowid

cursor.execute("""
    INSERT INTO instructor (user_id, instructor_name, instructor_email, instructor_phone, hire_date, salary)
    VALUES (?, 'Eng. omar saqer', 'omar.saqer@iti.gov.eg', '01222222222', '2021-02-01', 14000.00)
""", (instructor2_user_id,))

instructor2_id = cursor.lastrowid

print("✓ Instructor 1 created: username='instructor1', password='instructor123'")
print("✓ Instructor 2 created: username='instructor2', password='instructor123'")

# Create students
students = [
    ('adhm', 'adhm123', 'Adham Ahmed', 'adham@gmail.com', '01016807360', 'Intake 45'),
    ('hager', 'hager123', 'Hager Mohamed', 'hager@gmail.com', '01011112222', 'Intake 45'),
    ('mohamedalaa', '123', 'Mohamed Alaa', 'mohamedalaa@gmail.com', '01033334444', 'Intake 45'),
    ('abdo', 'abdo123', 'Abdo Khaled', 'abdo@gmail.com', '01055556666', 'Intake 45')
]

for username, password, name, email, phone, intake_name in students:
    cursor.execute("SELECT * FROM user WHERE username = ?", (username,))
    if not cursor.fetchone():
        cursor.execute("""
            INSERT INTO user (username, password_hash, role, is_active)
            VALUES (?, ?, 'student', 1)
        """, (username, generate_password_hash(password)))
        user_id = cursor.lastrowid
    else:
        cursor.execute("SELECT user_id FROM user WHERE username = ?", (username,))
        user_id = cursor.fetchone()[0]

    # Insert into student table
    cursor.execute("""
        INSERT OR IGNORE INTO student (user_id, student_name, student_email, student_phone, intake_id)
        SELECT ?, ?, ?, ?, intake_id
        FROM intake
        WHERE intake_name = ?
    """, (user_id, name, email, phone, intake_name))

    print(f"✓ Student created/updated: {name} ({username})")












# 4. FIX EXISTING INTAKE (Add Year)
print("\n[4/11] Fixing intake year...")

cursor.execute("""
    UPDATE intake
    SET intake_year = 2024
    WHERE intake_name = 'Intake 45' AND intake_year IS NULL
""")

print("✓ Intake year updated to 2024")

# 5. CREATE COURSES
print("\n[5/11] Creating courses...")

courses = [
    ('SQL Server Fundamentals', 'Database design, SQL queries, stored procedures', 100, 50),
    ('HTML & CSS', 'Web page structure and styling', 100, 60),
    ('JavaScript Basics', 'Programming fundamentals with JavaScript', 100, 50),
    ('Python Programming', 'Python syntax, data structures, OOP', 100, 50)
]

course_ids = {}
for course in courses:
    cursor.execute("""
        INSERT INTO course (course_name, course_description, max_degree, min_degree)
        VALUES (?, ?, ?, ?)
    """, course)
    course_ids[course[0]] = cursor.lastrowid
    print(f"✓ Course created: {course[0]}")

# 6. ASSIGN INSTRUCTORS TO COURSES
print("\n[6/11] Assigning instructors to courses...")

# Get intake_id
cursor.execute("SELECT intake_id FROM intake WHERE intake_name = 'Intake 45'")
intake_id = cursor.fetchone()[0]

# eng/alyaa teaches SQL and Python
cursor.execute("""
    INSERT INTO instructor_course (instructor_id, course_id, intake_id)
    VALUES (?, ?, ?)
""", (instructor1_id, course_ids['SQL Server Fundamentals'], intake_id))

cursor.execute("""
    INSERT INTO instructor_course (instructor_id, course_id, intake_id)
    VALUES (?, ?, ?)
""", (instructor1_id, course_ids['Python Programming'], intake_id))

# Eng. omar saqer teaches HTML & JavaScript
cursor.execute("""
    INSERT INTO instructor_course (instructor_id, course_id, intake_id)
    VALUES (?, ?, ?)
""", (instructor2_id, course_ids['HTML & CSS'], intake_id))

cursor.execute("""
    INSERT INTO instructor_course (instructor_id, course_id, intake_id)
    VALUES (?, ?, ?)
""", (instructor2_id, course_ids['JavaScript Basics'], intake_id))

print("✓ Instructors assigned to courses")



# 7. CREATE QUESTIONS FOR SQL COURSE
print("\n[7/11] Creating questions for SQL course...")

sql_questions = []

# MCQ Question 1
cursor.execute("""
    INSERT INTO question (question_text, question_type, correct_answer, course_id, created_by)
    VALUES (?, 'MCQ', 'A', ?, ?)
""", ('What does SQL stand for?', course_ids['SQL Server Fundamentals'], instructor1_id))
q1_id = cursor.lastrowid
sql_questions.append(q1_id)

# Add choices
choices_q1 = [
    ('Structured Query Language', 'A'),
    ('Simple Question Language', 'B'),
    ('System Query Language', 'C'),
    ('Server Question Language', 'D')
]
for choice_text, choice_order in choices_q1:
    cursor.execute("""
        INSERT INTO question_choices (question_id, choice_text, choice_order)
        VALUES (?, ?, ?)
    """, (q1_id, choice_text, choice_order))

# MCQ Question 2
cursor.execute("""
    INSERT INTO question (question_text, question_type, correct_answer, course_id, created_by)
    VALUES (?, 'MCQ', 'B', ?, ?)
""", ('Which keyword is used to retrieve data from a database?', course_ids['SQL Server Fundamentals'], instructor1_id))
q2_id = cursor.lastrowid
sql_questions.append(q2_id)

choices_q2 = [
    ('GET', 'A'),
    ('SELECT', 'B'),
    ('FETCH', 'C'),
    ('RETRIEVE', 'D')
]
for choice_text, choice_order in choices_q2:
    cursor.execute("""
        INSERT INTO question_choices (question_id, choice_text, choice_order)
        VALUES (?, ?, ?)
    """, (q2_id, choice_text, choice_order))

# True/False Question 1
cursor.execute("""
    INSERT INTO question (question_text, question_type, correct_answer, course_id, created_by)
    VALUES (?, 'TrueFalse', 'True', ?, ?)
""", ('SELECT statement is used to retrieve data from database.', course_ids['SQL Server Fundamentals'], instructor1_id))
sql_questions.append(cursor.lastrowid)

# True/False Question 2
cursor.execute("""
    INSERT INTO question (question_text, question_type, correct_answer, course_id, created_by)
    VALUES (?, 'TrueFalse', 'False', ?, ?)
""", ('DELETE command always requires a WHERE clause.', course_ids['SQL Server Fundamentals'], instructor1_id))
sql_questions.append(cursor.lastrowid)

# Text Question
cursor.execute("""
    INSERT INTO question (question_text, question_type, correct_answer, course_id, created_by)
    VALUES (?, 'Text', 'SELECT * FROM student', ?, ?)
""", ('Write a SQL query to select all records from the student table.', course_ids['SQL Server Fundamentals'], instructor1_id))
sql_questions.append(cursor.lastrowid)

print(f"✓ Created {len(sql_questions)} questions for SQL course")

# 8. CREATE QUESTIONS FOR HTML COURSE
print("\n[8/11] Creating questions for HTML course...")

cursor.execute("""
    INSERT INTO question (question_text, question_type, correct_answer, course_id, created_by)
    VALUES (?, 'MCQ', 'A', ?, ?)
""", ('What does HTML stand for?', course_ids['HTML & CSS'], instructor2_id))
html_q1_id = cursor.lastrowid

choices_html = [
    ('HyperText Markup Language', 'A'),
    ('HighText Machine Language', 'B'),
    ('HyperText Machine Language', 'C'),
    ('Home Tool Markup Language', 'D')
]
for choice_text, choice_order in choices_html:
    cursor.execute("""
        INSERT INTO question_choices (question_id, choice_text, choice_order)
        VALUES (?, ?, ?)
    """, (html_q1_id, choice_text, choice_order))

cursor.execute("""
    INSERT INTO question (question_text, question_type, correct_answer, course_id, created_by)
    VALUES (?, 'TrueFalse', 'True', ?, ?)
""", ('The <br> tag is used for line break.', course_ids['HTML & CSS'], instructor2_id))

print("✓ Created 2 questions for HTML course")

# 9. CREATE AN EXAM
print("\n[9/11] Creating SQL exam...")

cursor.execute("""
    INSERT INTO exam (exam_type, course_id, instructor_id, intake_id, exam_date,
                     start_time, end_time, total_time, total_degree, year, allowance_options)
    VALUES ('Exam', ?, ?, ?, '2024-12-25', '09:00:00', '11:00:00', 120, 50, 2024, 'Calculator allowed')
""", (course_ids['SQL Server Fundamentals'], instructor1_id, intake_id))

exam_id = cursor.lastrowid

print(f"✓ Exam created (ID: {exam_id})")

# 10. ADD QUESTIONS TO EXAM
print("\n[10/11] Adding questions to exam...")

# Add 2 MCQ questions (10 marks each) = 20 marks
cursor.execute("""
    INSERT INTO exam_question (exam_id, question_id, question_degree)
    VALUES (?, ?, 10)
""", (exam_id, sql_questions[0]))

cursor.execute("""
    INSERT INTO exam_question (exam_id, question_id, question_degree)
    VALUES (?, ?, 10)
""", (exam_id, sql_questions[1]))

# Add 2 True/False (5 marks each) = 10 marks
cursor.execute("""
    INSERT INTO exam_question (exam_id, question_id, question_degree)
    VALUES (?, ?, 5)
""", (exam_id, sql_questions[2]))

cursor.execute("""
    INSERT INTO exam_question (exam_id, question_id, question_degree)
    VALUES (?, ?, 5)
""", (exam_id, sql_questions[3]))

# Add 1 Text question (20 marks) = 20 marks
# Total = 50 marks
cursor.execute("""
    INSERT INTO exam_question (exam_id, question_id, question_degree)
    VALUES (?, ?, 20)
""", (exam_id, sql_questions[4]))

print("✓ Added 5 questions to exam (Total: 50 marks)")

# 11. ASSIGN YOUR STUDENT TO EXAM
print("\n[11/11] Assigning student to exam...")

cursor.execute("""
    SELECT student_id FROM student WHERE student_email = 'student1@gmail.com'
""")
result = cursor.fetchone()

if result:
    student_id = result[0]
    cursor.execute("""
        INSERT INTO student_exam (student_id, exam_id)
        VALUES (?, ?)
    """, (student_id, exam_id))
    print(f"✓ Student assigned to exam")
else:
    print("⚠ Student not found (will need to register first)")

# COMMIT ALL CHANGES
conn.commit()

print("\n" + "=" * 50)
print("✓✓✓ TEST DATA INSERTED SUCCESSFULLY! ✓✓✓")
print("=" * 50)

# =====================================================
# SHOW SUMMARY
# =====================================================
print("\n📋 SUMMARY:")
print("-" * 50)

cursor.execute("SELECT username, role FROM user")
users = cursor.fetchall()
print(f"\n👥 Users Created ({len(users)}):")
for username, role in users:
    print(f"   • {username:15} ({role})")

cursor.execute("SELECT course_name FROM course")
courses_list = cursor.fetchall()
print(f"\n📚 Courses ({len(courses_list)}):")
for (course_name,) in courses_list:
    print(f"   • {course_name}")

cursor.execute("SELECT COUNT(*) FROM question")
question_count = cursor.fetchone()[0]
print(f"\n❓ Questions: {question_count}")

cursor.execute("SELECT COUNT(*) FROM exam")
exam_count = cursor.fetchone()[0]
print(f"\n📝 Exams: {exam_count}")

cursor.execute("""
    SELECT s.student_name, COUNT(se.exam_id)
    FROM student s
    LEFT JOIN student_exam se ON s.student_id = se.student_id
    GROUP BY s.student_id
""")
student_exams = cursor.fetchall()
print(f"\n🎓 Student Exam Assignments:")
for name, exam_count in student_exams:
    print(f"   • {name}: {exam_count} exam(s)")

print("\n" + "=" * 50)
print("🔑 LOGIN CREDENTIALS:")
print("=" * 50)
print("\n1. ADMIN:")
print("   Username: admin")
print("   Password: admin123")
print("\n2. TRAINING MANAGER:")
print("   Username: manager1")
print("   Password: manager123")
print("\n3. INSTRUCTOR (eng/alyaa):")
print("   Username: instructor1")
print("   Password: instructor123")
print("\n4. INSTRUCTOR (Eng. omar saqer):")
print("   Username: instructor2")
print("   Password: instructor123")
print("\n5. STUDENT:")
print("   Username: adhm (or your registered username)")
print("   Password: (your password)")
print("\n" + "=" * 50)

conn.close()

print("\n✅ You can now login and test all features!")
print("Run: flask run")
