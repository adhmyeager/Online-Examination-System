"""
Examination System - COMPLETE Flask Application
All routes for Admin, Training Manager, Instructor, and Student
"""

import os
from flask import Flask, render_template, request, redirect, session, flash, jsonify
from flask_session import Session
from werkzeug.security import check_password_hash, generate_password_hash
from helpers import *
from datetime import datetime
import sqlite3

app = Flask(__name__)
app.config["SESSION_PERMANENT"] = False
app.config["SESSION_TYPE"] = "filesystem"
app.secret_key = "your-secret-key-change-in-production"
Session(app)

DATABASE = 'exam_system.db'

def get_db():
    db = sqlite3.connect(DATABASE)
    db.row_factory = sqlite3.Row
    return db

def init_db():
    if not os.path.exists(DATABASE):
        with app.app_context():
            db = get_db()
            with open('schema.sql', 'r') as f:
                db.executescript(f.read())
            db.commit()
            print("Database initialized!")

@app.after_request
def after_request(response):
    response.headers["Cache-Control"] = "no-cache, no-store, must-revalidate"
    response.headers["Expires"] = 0
    response.headers["Pragma"] = "no-cache"
    return response

# =====================================================
# AUTHENTICATION ROUTES
# =====================================================

@app.route("/")
def index():
    if "user_id" not in session:
        return redirect("/login")

    role = session.get("role")
    if role == "student":
        return redirect("/student/dashboard")
    elif role == "instructor":
        return redirect("/instructor/dashboard")
    elif role == "manager":
        return redirect("/manager/dashboard")
    else:
        return redirect("/admin/dashboard")

@app.route("/login", methods=["GET", "POST"])
def login():
    session.clear()

    if request.method == "POST":
        username = request.form.get("username")
        password = request.form.get("password")

        if not username or not password:
            flash("Please provide username and password", "error")
            return render_template("login.html")

        db = get_db()
        user = db.execute("SELECT * FROM user WHERE username = ?", (username,)).fetchone()

        if user is None or not check_password_hash(user["password_hash"], password):
            flash("Invalid username and/or password", "error")
            return render_template("login.html")

        if not user["is_active"]:
            flash("Your account has been deactivated", "error")
            return render_template("login.html")

        session["user_id"] = user["user_id"]
        session["username"] = user["username"]
        session["role"] = user["role"]

        if user["role"] == "student":
            student = db.execute("SELECT student_id, student_name FROM student WHERE user_id = ?", (user["user_id"],)).fetchone()
            session["person_id"] = student["student_id"]
            session["person_name"] = student["student_name"]
        elif user["role"] == "instructor":
            instructor = db.execute("SELECT instructor_id, instructor_name FROM instructor WHERE user_id = ?", (user["user_id"],)).fetchone()
            session["person_id"] = instructor["instructor_id"]
            session["person_name"] = instructor["instructor_name"]
        elif user["role"] == "manager":
            manager = db.execute("SELECT manager_id, manager_name FROM training_manager WHERE user_id = ?", (user["user_id"],)).fetchone()
            session["person_id"] = manager["manager_id"]
            session["person_name"] = manager["manager_name"]
        else:
            session["person_name"] = "Administrator"

        flash(f"Welcome back, {session['person_name']}!", "success")
        return redirect("/")

    return render_template("login.html")

@app.route("/logout")
def logout():
    session.clear()
    flash("You have been logged out", "info")
    return redirect("/login")

@app.route("/register", methods=["GET", "POST"])
def register():
    if request.method == "POST":
        username = request.form.get("username")
        password = request.form.get("password")
        confirmation = request.form.get("confirmation")
        name = request.form.get("name")
        email = request.form.get("email")
        phone = request.form.get("phone")
        intake_id = request.form.get("intake_id")

        if not all([username, password, confirmation, name, email, intake_id]):
            flash("All required fields must be filled", "error")
            return redirect("/register")

        if password != confirmation:
            flash("Passwords do not match", "error")
            return redirect("/register")

        db = get_db()
        if db.execute("SELECT * FROM user WHERE username = ?", (username,)).fetchone():
            flash("Username already taken", "error")
            return redirect("/register")

        if db.execute("SELECT * FROM student WHERE student_email = ?", (email,)).fetchone():
            flash("Email already registered", "error")
            return redirect("/register")

        password_hash = generate_password_hash(password)
        cursor = db.execute("INSERT INTO user (username, password_hash, role) VALUES (?, ?, 'student')", (username, password_hash))
        user_id = cursor.lastrowid

        db.execute("INSERT INTO student (user_id, student_name, student_email, student_phone, intake_id) VALUES (?, ?, ?, ?, ?)",
                  (user_id, name, email, phone, intake_id))
        db.commit()

        flash("Registration successful! Please login.", "success")
        return redirect("/login")

    db = get_db()
    intakes = db.execute("""
        SELECT i.intake_id, i.intake_name, i.intake_year, b.branch_name, t.track_name
        FROM intake i
        JOIN branch b ON i.branch_id = b.branch_id
        JOIN track t ON i.track_id = t.track_id
        ORDER BY i.intake_year DESC, i.intake_name
    """).fetchall()

    return render_template("register.html", intakes=intakes)

# =====================================================
# ADMIN ROUTES
# =====================================================

@app.route("/admin/dashboard")
@login_required("admin")
def admin_dashboard():
    db = get_db()

    stats = {
        'total_users': db.execute("SELECT COUNT(*) as count FROM user").fetchone()['count'],
        'active_users': db.execute("SELECT COUNT(*) as count FROM user WHERE is_active = 1").fetchone()['count'],
        'total_students': db.execute("SELECT COUNT(*) as count FROM student").fetchone()['count'],
        'total_instructors': db.execute("SELECT COUNT(*) as count FROM instructor").fetchone()['count'],
        'total_managers': db.execute("SELECT COUNT(*) as count FROM training_manager").fetchone()['count'],
        'total_courses': db.execute("SELECT COUNT(*) as count FROM course").fetchone()['count'],
        'total_exams': db.execute("SELECT COUNT(*) as count FROM exam").fetchone()['count'],
        'total_questions': db.execute("SELECT COUNT(*) as count FROM question").fetchone()['count']
    }

    recent_users = db.execute("""
        SELECT username, role, created_date, is_active
        FROM user
        ORDER BY created_date DESC
        LIMIT 10
    """).fetchall()

    return render_template("admin_dashboard.html", stats=stats, recent_users=recent_users)

@app.route("/admin/users")
@login_required("admin")
def admin_users():
    db = get_db()
    users = db.execute("""
        SELECT u.*,
               CASE u.role
                   WHEN 'student' THEN s.student_name
                   WHEN 'instructor' THEN i.instructor_name
                   WHEN 'manager' THEN m.manager_name
                   ELSE 'Admin'
               END as full_name
        FROM user u
        LEFT JOIN student s ON u.user_id = s.user_id
        LEFT JOIN instructor i ON u.user_id = i.user_id
        LEFT JOIN training_manager m ON u.user_id = m.user_id
        ORDER BY u.created_date DESC
    """).fetchall()

    return render_template("admin_users.html", users=users)

@app.route("/admin/user/<int:user_id>/toggle", methods=["POST"])
@login_required("admin")
def admin_toggle_user(user_id):
    db = get_db()
    user = db.execute("SELECT * FROM user WHERE user_id = ?", (user_id,)).fetchone()

    if not user:
        flash("User not found", "error")
        return redirect("/admin/users")

    new_status = 0 if user["is_active"] else 1
    db.execute("UPDATE user SET is_active = ? WHERE user_id = ?", (new_status, user_id))
    db.commit()

    action = "activated" if new_status else "deactivated"
    flash(f"User {user['username']} has been {action}", "success")
    return redirect("/admin/users")

@app.route("/admin/logs")
@login_required("admin")
def admin_logs():
    # Placeholder for system logs
    logs = [
        {"timestamp": datetime.now(), "action": "User Login", "user": "admin", "details": "Successful login"},
        {"timestamp": datetime.now(), "action": "Exam Created", "user": "instructor1", "details": "SQL Fundamentals Exam"},
    ]
    return render_template("admin_logs.html", logs=logs)

# =====================================================
# STUDENT ROUTES
# =====================================================

@app.route("/student/dashboard")
@login_required("student")
def student_dashboard():
    db = get_db()
    student_id = session["person_id"]

    student_info = db.execute("""
        SELECT s.*, i.intake_name, i.intake_year, b.branch_name, t.track_name
        FROM student s
        JOIN intake i ON s.intake_id = i.intake_id
        JOIN branch b ON i.branch_id = b.branch_id
        JOIN track t ON i.track_id = t.track_id
        WHERE s.student_id = ?
    """, (student_id,)).fetchone()

    exams = db.execute("""
        SELECT e.exam_id, c.course_name, e.exam_type, e.exam_date,
        e.start_time, e.end_time, e.total_degree,
        se.actual_start_time, se.actual_end_time, se.obtained_degree, c.min_degree
        FROM student_exam se
        JOIN exam e ON se.exam_id = e.exam_id
        JOIN course c ON e.course_id = c.course_id
        WHERE se.student_id = ?
        ORDER BY e.exam_date DESC
    """, (student_id,)).fetchall()

    return render_template("student_dashboard.html", student=student_info, exams=exams)

@app.route("/student/exam/<int:exam_id>")
@login_required("student")
def take_exam(exam_id):
    db = get_db()
    student_id = session["person_id"]

    assignment = db.execute("SELECT * FROM student_exam WHERE student_id = ? AND exam_id = ?", (student_id, exam_id)).fetchone()

    if not assignment:
        flash("You are not assigned to this exam", "error")
        return redirect("/student/dashboard")

    if assignment["actual_end_time"]:
        flash("You have already completed this exam", "info")
        return redirect(f"/student/results/{exam_id}")

    exam = db.execute("SELECT e.*, c.course_name FROM exam e JOIN course c ON e.course_id = c.course_id WHERE e.exam_id = ?", (exam_id,)).fetchone()

    if not assignment["actual_start_time"]:
        db.execute("UPDATE student_exam SET actual_start_time = ? WHERE student_id = ? AND exam_id = ?",
                  (datetime.now(), student_id, exam_id))
        db.commit()

    questions = db.execute("""
        SELECT q.question_id, q.question_text, q.question_type, eq.question_degree
        FROM exam_question eq
        JOIN question q ON eq.question_id = q.question_id
        WHERE eq.exam_id = ?
        ORDER BY q.question_id
    """, (exam_id,)).fetchall()

    question_ids = [q["question_id"] for q in questions]
    choices = {}
    if question_ids:
        placeholders = ','.join('?' * len(question_ids))
        all_choices = db.execute(f"SELECT * FROM question_choices WHERE question_id IN ({placeholders}) ORDER BY choice_order", question_ids).fetchall()

        for choice in all_choices:
            qid = choice["question_id"]
            if qid not in choices:
                choices[qid] = []
            choices[qid].append(choice)

    existing_answers = {}
    answers = db.execute("SELECT question_id, student_answer FROM student_answer WHERE student_id = ? AND exam_id = ?", (student_id, exam_id)).fetchall()
    for ans in answers:
        existing_answers[ans["question_id"]] = ans["student_answer"]

    return render_template("take_exam.html", exam=exam, questions=questions, choices=choices, existing_answers=existing_answers)

@app.route("/student/submit_answer", methods=["POST"])
@login_required("student")
def submit_answer():
    data = request.get_json()
    student_id = session["person_id"]
    exam_id = data.get("exam_id")
    question_id = data.get("question_id")
    answer = data.get("answer")

    db = get_db()

    question = db.execute("""
        SELECT q.*, eq.question_degree FROM question q
        JOIN exam_question eq ON q.question_id = eq.question_id
        WHERE q.question_id = ? AND eq.exam_id = ?
    """, (question_id, exam_id)).fetchone()

    is_correct = None
    obtained_marks = None

    if question["question_type"] in ["MCQ", "TrueFalse"]:
        is_correct = 1 if answer.upper() == question["correct_answer"].upper() else 0
        obtained_marks = question["question_degree"] if is_correct else 0

    existing = db.execute("SELECT * FROM student_answer WHERE student_id = ? AND exam_id = ? AND question_id = ?",
                         (student_id, exam_id, question_id)).fetchone()

    if existing:
        db.execute("""
            UPDATE student_answer SET student_answer = ?, is_correct = ?, obtained_marks = ?, answered_at = ?
            WHERE student_id = ? AND exam_id = ? AND question_id = ?
        """, (answer, is_correct, obtained_marks, datetime.now(), student_id, exam_id, question_id))
    else:
        db.execute("""
            INSERT INTO student_answer (student_id, exam_id, question_id, student_answer, is_correct, obtained_marks)
            VALUES (?, ?, ?, ?, ?, ?)
        """, (student_id, exam_id, question_id, answer, is_correct, obtained_marks))

    db.commit()

    return jsonify({"success": True, "is_correct": is_correct})

@app.route("/student/submit_exam/<int:exam_id>", methods=["POST", "GET"])
@login_required("student")
def submit_exam(exam_id):
    db = get_db()
    student_id = session["person_id"]

    total_score = db.execute("SELECT SUM(obtained_marks) as total FROM student_answer WHERE student_id = ? AND exam_id = ?",
                            (student_id, exam_id)).fetchone()["total"] or 0

    db.execute("""
        UPDATE student_exam SET actual_end_time = ?, total_score = ?, obtained_degree = ?
        WHERE student_id = ? AND exam_id = ?
    """, (datetime.now(), total_score, total_score, student_id, exam_id))
    db.commit()

    flash("Exam submitted successfully!", "success")
    return redirect(f"/student/results/{exam_id}")

@app.route("/student/results/<int:exam_id>")
@login_required("student")
def view_results(exam_id):
    db = get_db()
    student_id = session["person_id"]

    exam_summary = db.execute("""
        SELECT e.*, c.course_name, c.min_degree, se.obtained_degree, se.actual_start_time, se.actual_end_time
        FROM student_exam se
        JOIN exam e ON se.exam_id = e.exam_id
        JOIN course c ON e.course_id = c.course_id
        WHERE se.student_id = ? AND se.exam_id = ?
    """, (student_id, exam_id)).fetchone()

    answers = db.execute("""
        SELECT q.question_text, q.question_type, q.correct_answer,
        sa.student_answer, sa.is_correct, sa.obtained_marks, eq.question_degree
        FROM student_answer sa
        JOIN question q ON sa.question_id = q.question_id
        JOIN exam_question eq ON sa.exam_id = eq.exam_id AND sa.question_id = eq.question_id
        WHERE sa.student_id = ? AND sa.exam_id = ?
        ORDER BY q.question_id
    """, (student_id, exam_id)).fetchall()

    return render_template("view_results.html", exam=exam_summary, answers=answers)

# =====================================================
# INSTRUCTOR ROUTES
# =====================================================

@app.route("/instructor/dashboard")
@login_required("instructor")
def instructor_dashboard():
    db = get_db()
    instructor_id = session["person_id"]

    courses = db.execute("""
        SELECT DISTINCT c.* FROM course c
        JOIN instructor_course ic ON c.course_id = ic.course_id
        WHERE ic.instructor_id = ?
    """, (instructor_id,)).fetchall()

    exams = db.execute("""
        SELECT e.*, c.course_name, i.intake_name,
        (SELECT COUNT(*) FROM student_exam WHERE exam_id = e.exam_id) as student_count
        FROM exam e
        JOIN course c ON e.course_id = c.course_id
        JOIN intake i ON e.intake_id = i.intake_id
        WHERE e.instructor_id = ?
        ORDER BY e.exam_date DESC
    """, (instructor_id,)).fetchall()

    return render_template("instructor_dashboard.html", courses=courses, exams=exams)

@app.route("/instructor/add-question", methods=["GET", "POST"])
@login_required("instructor")
def add_question():
    db = get_db()
    instructor_id = session["person_id"]

    if request.method == "POST":
        question_text = request.form.get("question_text")
        question_type = request.form.get("question_type")
        correct_answer = request.form.get("correct_answer")
        course_id = request.form.get("course_id")

        cursor = db.execute("""
            INSERT INTO question (question_text, question_type, correct_answer, course_id, created_by)
            VALUES (?, ?, ?, ?, ?)
        """, (question_text, question_type, correct_answer, course_id, instructor_id))

        question_id = cursor.lastrowid

        # Add choices for MCQ
        if question_type == "MCQ":
            for letter in ['A', 'B', 'C', 'D']:
                choice_text = request.form.get(f"choice_{letter}")
                if choice_text:
                    db.execute("""
                        INSERT INTO question_choices (question_id, choice_text, choice_order)
                        VALUES (?, ?, ?)
                    """, (question_id, choice_text, letter))

        db.commit()
        flash("Question added successfully!", "success")
        return redirect("/instructor/questions")

    courses = db.execute("""
        SELECT DISTINCT c.* FROM course c
        JOIN instructor_course ic ON c.course_id = ic.course_id
        WHERE ic.instructor_id = ?
    """, (instructor_id,)).fetchall()

    return render_template("add_question.html", courses=courses)

@app.route("/instructor/questions")
@login_required("instructor")
def view_questions():
    db = get_db()
    instructor_id = session["person_id"]

    questions = db.execute("""
        SELECT q.*, c.course_name,
        (SELECT COUNT(*) FROM exam_question WHERE question_id = q.question_id) as times_used
        FROM question q
        JOIN course c ON q.course_id = c.course_id
        WHERE q.created_by = ?
        ORDER BY q.created_date DESC
    """, (instructor_id,)).fetchall()

    return render_template("view_questions.html", questions=questions)

@app.route("/instructor/create-exam", methods=["GET", "POST"])
@login_required("instructor")
def create_exam():
    db = get_db()
    instructor_id = session["person_id"]

    if request.method == "POST":
        course_id = request.form.get("course_id")
        intake_id = request.form.get("intake_id")
        exam_type = request.form.get("exam_type")
        total_degree = request.form.get("total_degree")
        exam_date = request.form.get("exam_date")
        start_time = request.form.get("start_time")
        end_time = request.form.get("end_time")
        total_time = request.form.get("total_time")
        year = request.form.get("year")
        allowance_options = request.form.get("allowance_options")

        cursor = db.execute("""
            INSERT INTO exam (exam_type, course_id, instructor_id, intake_id, exam_date,
                             start_time, end_time, total_time, total_degree, year, allowance_options)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, (exam_type, course_id, instructor_id, intake_id, exam_date, start_time, end_time,
             total_time, total_degree, year, allowance_options))

        exam_id = cursor.lastrowid

        # Handle random question selection
        selection_method = request.form.get("selection_method")
        if selection_method == "random":
            num_mcq = int(request.form.get("num_mcq") or 0)
            mcq_degree = int(request.form.get("mcq_degree") or 0)
            num_tf = int(request.form.get("num_truefalse") or 0)
            tf_degree = int(request.form.get("tf_degree") or 0)
            num_text = int(request.form.get("num_text") or 0)
            text_degree = int(request.form.get("text_degree") or 0)

            # Add MCQ questions
            if num_mcq > 0:
                mcq_questions = db.execute("""
                    SELECT question_id FROM question
                    WHERE course_id = ? AND question_type = 'MCQ' AND created_by = ?
                    ORDER BY RANDOM() LIMIT ?
                """, (course_id, instructor_id, num_mcq)).fetchall()

                for q in mcq_questions:
                    db.execute("INSERT INTO exam_question (exam_id, question_id, question_degree) VALUES (?, ?, ?)",
                              (exam_id, q['question_id'], mcq_degree))

            # Add True/False questions
            if num_tf > 0:
                tf_questions = db.execute("""
                    SELECT question_id FROM question
                    WHERE course_id = ? AND question_type = 'TrueFalse' AND created_by = ?
                    ORDER BY RANDOM() LIMIT ?
                """, (course_id, instructor_id, num_tf)).fetchall()

                for q in tf_questions:
                    db.execute("INSERT INTO exam_question (exam_id, question_id, question_degree) VALUES (?, ?, ?)",
                              (exam_id, q['question_id'], tf_degree))

            # Add Text questions
            if num_text > 0:
                text_questions = db.execute("""
                    SELECT question_id FROM question
                    WHERE course_id = ? AND question_type = 'Text' AND created_by = ?
                    ORDER BY RANDOM() LIMIT ?
                """, (course_id, instructor_id, num_text)).fetchall()

                for q in text_questions:
                    db.execute("INSERT INTO exam_question (exam_id, question_id, question_degree) VALUES (?, ?, ?)",
                              (exam_id, q['question_id'], text_degree))

            # Auto-assign students from intake
            students = db.execute("SELECT student_id FROM student WHERE intake_id = ?", (intake_id,)).fetchall()
            for student in students:
                db.execute("INSERT INTO student_exam (student_id, exam_id) VALUES (?, ?)",
                          (student['student_id'], exam_id))

        db.commit()
        flash("Exam created successfully!", "success")
        return redirect("/instructor/dashboard")

    courses = db.execute("""
        SELECT c.* FROM course c
        JOIN instructor_course ic ON c.course_id = ic.course_id
        WHERE ic.instructor_id = ?
    """, (instructor_id,)).fetchall()

    intakes = db.execute("SELECT * FROM intake ORDER BY intake_year DESC").fetchall()

    return render_template("create_exam.html", courses=courses, intakes=intakes)

@app.route("/instructor/exam/<int:exam_id>/results")
@login_required("instructor")
def instructor_exam_results(exam_id):
    db = get_db()

    exam = db.execute("""
        SELECT e.*, c.course_name, i.intake_name
        FROM exam e
        JOIN course c ON e.course_id = c.course_id
        JOIN intake i ON e.intake_id = i.intake_id
        WHERE e.exam_id = ?
    """, (exam_id,)).fetchone()

    results = db.execute("""
        SELECT s.student_name, se.obtained_degree, e.total_degree, c.min_degree,
        CASE WHEN se.obtained_degree >= c.min_degree THEN 'PASS' ELSE 'FAIL' END as status
        FROM student_exam se
        JOIN student s ON se.student_id = s.student_id
        JOIN exam e ON se.exam_id = e.exam_id
        JOIN course c ON e.course_id = c.course_id
        WHERE se.exam_id = ? AND se.actual_end_time IS NOT NULL
        ORDER BY se.obtained_degree DESC
    """, (exam_id,)).fetchall()

    return render_template("instructor_exam_results.html", exam=exam, results=results)

@app.route("/instructor/grade/<int:exam_id>")
@login_required("instructor")
def grade_exam(exam_id):
    db = get_db()

    exam = db.execute("""
        SELECT e.*, c.course_name, i.intake_name
        FROM exam e
        JOIN course c ON e.course_id = c.course_id
        JOIN intake i ON e.intake_id = i.intake_id
        WHERE e.exam_id = ?
    """, (exam_id,)).fetchone()

    # Get ungraded text answers
    answers = db.execute("""
        SELECT sa.answer_id, sa.student_id, sa.question_id, sa.student_answer, sa.obtained_marks,
        s.student_name, q.question_text, q.correct_answer, eq.question_degree, sa.answered_at
        FROM student_answer sa
        JOIN student s ON sa.student_id = s.student_id
        JOIN question q ON sa.question_id = q.question_id
        JOIN exam_question eq ON sa.exam_id = eq.exam_id AND sa.question_id = eq.question_id
        WHERE sa.exam_id = ? AND q.question_type = 'Text'
        ORDER BY s.student_name, q.question_id
    """, (exam_id,)).fetchall()

    students = db.execute("""
        SELECT DISTINCT s.student_id, s.student_name
        FROM student_exam se
        JOIN student s ON se.student_id = s.student_id
        WHERE se.exam_id = ?
    """, (exam_id,)).fetchall()

    graded_count = len([a for a in answers if a['obtained_marks'] is not None])
    ungraded_count = len([a for a in answers if a['obtained_marks'] is None])
    total_count = len(answers)

    return render_template("grade_exam.html", exam=exam, answers=answers, students=students,
                         graded_count=graded_count, ungraded_count=ungraded_count, total_count=total_count)

@app.route("/instructor/grade-answer", methods=["POST"])
@login_required("instructor")
def grade_answer():
    db = get_db()

    answer_id = request.form.get("answer_id")
    obtained_marks = request.form.get("obtained_marks")
    is_correct = request.form.get("is_correct")
    exam_id = request.form.get("exam_id")

    db.execute("""
        UPDATE student_answer
        SET obtained_marks = ?, is_correct = ?
        WHERE answer_id = ?
    """, (obtained_marks, is_correct, answer_id))

    # Recalculate total score
    answer = db.execute("SELECT student_id, exam_id FROM student_answer WHERE answer_id = ?", (answer_id,)).fetchone()

    total_score = db.execute("""
        SELECT SUM(obtained_marks) as total
        FROM student_answer
        WHERE student_id = ? AND exam_id = ?
    """, (answer['student_id'], answer['exam_id'])).fetchone()['total'] or 0

    db.execute("""
        UPDATE student_exam
        SET total_score = ?, obtained_degree = ?
        WHERE student_id = ? AND exam_id = ?
    """, (total_score, total_score, answer['student_id'], answer['exam_id']))

    db.commit()

    flash("Answer graded successfully!", "success")
    return redirect(f"/instructor/grade/{exam_id}")

# =====================================================
# TRAINING MANAGER ROUTES
# =====================================================

@app.route("/manager/dashboard")
@login_required("manager")
def manager_dashboard():
    db = get_db()

    stats = {
        'branches': db.execute("SELECT COUNT(*) as count FROM branch").fetchone()['count'],
        'tracks': db.execute("SELECT COUNT(*) as count FROM track").fetchone()['count'],
        'students': db.execute("SELECT COUNT(*) as count FROM student").fetchone()['count'],
        'instructors': db.execute("SELECT COUNT(*) as count FROM instructor").fetchone()['count'],
        'courses': db.execute("SELECT COUNT(*) as count FROM course").fetchone()['count'],
        'exams': db.execute("SELECT COUNT(*) as count FROM exam").fetchone()['count'],
        'active_students': db.execute("SELECT COUNT(*) as count FROM student s JOIN user u ON s.user_id = u.user_id WHERE u.is_active = 1").fetchone()['count'],
        'active_instructors': db.execute("SELECT COUNT(*) as count FROM instructor i JOIN user u ON i.user_id = u.user_id WHERE u.is_active = 1").fetchone()['count']
    }

    intakes = db.execute("""
        SELECT i.*, b.branch_name, t.track_name,
        (SELECT COUNT(*) FROM student WHERE intake_id = i.intake_id) as student_count
        FROM intake i
        JOIN branch b ON i.branch_id = b.branch_id
        JOIN track t ON i.track_id = t.track_id
        ORDER BY i.intake_year DESC, i.intake_name
        LIMIT 10
    """).fetchall()

    branches = db.execute("SELECT * FROM branch").fetchall()
    tracks = db.execute("SELECT * FROM track").fetchall()

    return render_template("manager_dashboard.html",
                         stats=stats, intakes=intakes, branches=branches, tracks=tracks, activities=[])

@app.route("/manager/add-branch", methods=["GET", "POST"])
@login_required("manager")
def add_branch():
    if request.method == "POST":
        branch_name = request.form.get("branch_name")
        branch_location = request.form.get("branch_location")

        db = get_db()
        db.execute("INSERT INTO branch (branch_name, branch_location) VALUES (?, ?)",
                  (branch_name, branch_location))
        db.commit()

        flash("Branch added successfully!", "success")
        return redirect("/manager/dashboard")

    return render_template("add_branch.html")

@app.route("/manager/add-track", methods=["GET", "POST"])
@login_required("manager")
def add_track():
    if request.method == "POST":
        track_name = request.form.get("track_name")
        track_description = request.form.get("track_description")

        db = get_db()
        db.execute("INSERT INTO track (track_name, track_description) VALUES (?, ?)",
                  (track_name, track_description))
        db.commit()

        flash("Track added successfully!", "success")
        return redirect("/manager/dashboard")

    return render_template("add_track.html")

@app.route("/manager/add-intake", methods=["GET", "POST"])
@login_required("manager")
def add_intake():
    db = get_db()

    if request.method == "POST":
        intake_name = request.form.get("intake_name")
        intake_year = request.form.get("intake_year")
        branch_id = request.form.get("branch_id")
        track_id = request.form.get("track_id")

        db.execute("""
            INSERT INTO intake (intake_name, intake_year, branch_id, track_id)
            VALUES (?, ?, ?, ?)
        """, (intake_name, intake_year, branch_id, track_id))
        db.commit()

        flash("Intake added successfully!", "success")
        return redirect("/manager/dashboard")

    branches = db.execute("SELECT * FROM branch").fetchall()
    tracks = db.execute("SELECT * FROM track").fetchall()

    return render_template("add_intake.html", branches=branches, tracks=tracks)

@app.route("/manager/add-course", methods=["GET", "POST"])
@login_required("manager")
def add_course():
    if request.method == "POST":
        course_name = request.form.get("course_name")
        course_description = request.form.get("course_description")
        max_degree = request.form.get("max_degree")
        min_degree = request.form.get("min_degree")

        db = get_db()
        db.execute("""
            INSERT INTO course (course_name, course_description, max_degree, min_degree)
            VALUES (?, ?, ?, ?)
        """, (course_name, course_description, max_degree, min_degree))
        db.commit()

        flash("Course added successfully!", "success")
        return redirect("/manager/dashboard")

    return render_template("add_course.html")

@app.route("/manager/add-student", methods=["GET", "POST"])
@login_required("manager")
def manager_add_student():
    db = get_db()

    if request.method == "POST":
        username = request.form.get("username")
        password = request.form.get("password")
        name = request.form.get("name")
        email = request.form.get("email")
        phone = request.form.get("phone")
        intake_id = request.form.get("intake_id")

        if db.execute("SELECT * FROM user WHERE username = ?", (username,)).fetchone():
            flash("Username already exists", "error")
            return redirect("/manager/add-student")

        password_hash = generate_password_hash(password)
        cursor = db.execute("INSERT INTO user (username, password_hash, role) VALUES (?, ?, 'student')",
                           (username, password_hash))
        user_id = cursor.lastrowid

        db.execute("""
            INSERT INTO student (user_id, student_name, student_email, student_phone, intake_id)
            VALUES (?, ?, ?, ?, ?)
        """, (user_id, name, email, phone, intake_id))
        db.commit()

        flash("Student added successfully!", "success")
        return redirect("/manager/students")

    intakes = db.execute("SELECT * FROM intake ORDER BY intake_year DESC").fetchall()
    return render_template("add_student.html", intakes=intakes)

@app.route("/manager/add-instructor", methods=["GET", "POST"])
@login_required("manager")
def add_instructor():
    if request.method == "POST":
        username = request.form.get("username")
        password = request.form.get("password")
        name = request.form.get("name")
        email = request.form.get("email")
        phone = request.form.get("phone")
        salary = request.form.get("salary")

        db = get_db()

        if db.execute("SELECT * FROM user WHERE username = ?", (username,)).fetchone():
            flash("Username already exists", "error")
            return redirect("/manager/add-instructor")

        password_hash = generate_password_hash(password)
        cursor = db.execute("INSERT INTO user (username, password_hash, role) VALUES (?, ?, 'instructor')",
                           (username, password_hash))
        user_id = cursor.lastrowid

        db.execute("""
            INSERT INTO instructor (user_id, instructor_name, instructor_email, instructor_phone, hire_date, salary)
            VALUES (?, ?, ?, ?, ?, ?)
        """, (user_id, name, email, phone, datetime.now().date(), salary))
        db.commit()

        flash("Instructor added successfully!", "success")
        return redirect("/manager/instructors")

    return render_template("add_instructor.html")

@app.route("/manager/students")
@login_required("manager")
def view_students():
    db = get_db()
    students = db.execute("""
        SELECT s.*, i.intake_name, b.branch_name, t.track_name, u.is_active
        FROM student s
        JOIN intake i ON s.intake_id = i.intake_id
        JOIN branch b ON i.branch_id = b.branch_id
        JOIN track t ON i.track_id = t.track_id
        JOIN user u ON s.user_id = u.user_id
        ORDER BY s.student_name
    """).fetchall()

    return render_template("view_students.html", students=students)

@app.route("/manager/instructors")
@login_required("manager")
def view_instructors():
    db = get_db()
    instructors = db.execute("""
        SELECT i.*, u.is_active,
        (SELECT COUNT(DISTINCT ic.course_id) FROM instructor_course ic WHERE ic.instructor_id = i.instructor_id) as course_count
        FROM instructor i
        JOIN user u ON i.user_id = u.user_id
        ORDER BY i.instructor_name
    """).fetchall()

    return render_template("view_instructors.html", instructors=instructors)

@app.route("/manager/assign-instructor", methods=["GET", "POST"])
@login_required("manager")
def assign_instructor():
    db = get_db()

    if request.method == "POST":
        instructor_id = request.form.get("instructor_id")
        course_id = request.form.get("course_id")
        intake_id = request.form.get("intake_id")

        db.execute("""
            INSERT INTO instructor_course (instructor_id, course_id, intake_id)
            VALUES (?, ?, ?)
        """, (instructor_id, course_id, intake_id))
        db.commit()

        flash("Instructor assigned to course successfully!", "success")
        return redirect("/manager/instructors")

    instructors = db.execute("SELECT * FROM instructor").fetchall()
    courses = db.execute("SELECT * FROM course").fetchall()
    intakes = db.execute("SELECT * FROM intake").fetchall()

    return render_template("assign_instructor.html", instructors=instructors, courses=courses, intakes=intakes)

if __name__ == "__main__":
    init_db()
    app.run(debug=True)
