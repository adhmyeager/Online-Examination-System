"""
Helper functions for the Examination System
Converted from SQL Server stored procedures
"""

from flask import redirect, session
from functools import wraps

def login_required(role=None):
    """
    Decorate routes to require login.
    Optionally restrict to specific role.

    Usage:
        @app.route("/student/dashboard")
        @login_required("student")
        def student_dashboard():
            ...
    """
    def decorator(f):
        @wraps(f)
        def decorated_function(*args, **kwargs):
            if session.get("user_id") is None:
                return redirect("/login")
            if role and session.get("role") != role:
                return redirect("/")
            return f(*args, **kwargs)
        return decorated_function
    return decorator

def check_exam_availability(exam_date, start_time, end_time):
    """
    Check if exam is currently available
    Returns: (is_available, message)
    """
    from datetime import datetime

    now = datetime.now()
    exam_datetime_start = datetime.combine(
        datetime.strptime(exam_date, "%Y-%m-%d").date(),
        datetime.strptime(start_time, "%H:%M:%S").time()
    )
    exam_datetime_end = datetime.combine(
        datetime.strptime(exam_date, "%Y-%m-%d").date(),
        datetime.strptime(end_time, "%H:%M:%S").time()
    )

    if now.date() != exam_datetime_start.date():
        return False, "Exam is not scheduled for today"

    if now < exam_datetime_start:
        return False, f"Exam starts at {start_time}"

    if now > exam_datetime_end:
        return False, "Exam time has expired"

    return True, "Exam is available"

def calculate_exam_score(db, student_id, exam_id):
    """
    Calculate total score for a student's exam
    Returns: total_score
    """
    result = db.execute(
        "SELECT SUM(obtained_marks) as total FROM student_answer "
        "WHERE student_id = ? AND exam_id = ?",
        (student_id, exam_id)
    ).fetchone()

    return result["total"] if result["total"] else 0

def get_student_progress(db, student_id):
    """
    Get student's overall progress statistics
    Returns: dict with stats
    """
    stats = {}

    # Total exams taken
    exams_taken = db.execute(
        "SELECT COUNT(*) as count FROM student_exam "
        "WHERE student_id = ? AND actual_end_time IS NOT NULL",
        (student_id,)
    ).fetchone()["count"]

    # Average score
    avg_score = db.execute(
        "SELECT AVG(obtained_degree) as avg FROM student_exam "
        "WHERE student_id = ? AND actual_end_time IS NOT NULL",
        (student_id,)
    ).fetchone()["avg"]

    # Exams passed
    exams_passed = db.execute(
        "SELECT COUNT(*) as count FROM student_exam se "
        "JOIN exam e ON se.exam_id = e.exam_id "
        "JOIN course c ON e.course_id = c.course_id "
        "WHERE se.student_id = ? AND se.obtained_degree >= c.min_degree",
        (student_id,)
    ).fetchone()["count"]

    stats["exams_taken"] = exams_taken
    stats["average_score"] = round(avg_score, 2) if avg_score else 0
    stats["exams_passed"] = exams_passed
    stats["pass_rate"] = round((exams_passed / exams_taken * 100), 2) if exams_taken > 0 else 0

    return stats

def format_datetime(dt_string):
    """
    Format datetime string for display
    """
    from datetime import datetime
    if not dt_string:
        return ""
    try:
        dt = datetime.strptime(dt_string, "%Y-%m-%d %H:%M:%S")
        return dt.strftime("%b %d, %Y at %I:%M %p")
    except:
        return dt_string

def format_date(date_string):
    """
    Format date string for display
    """
    from datetime import datetime
    if not date_string:
        return ""
    try:
        dt = datetime.strptime(date_string, "%Y-%m-%d")
        return dt.strftime("%b %d, %Y")
    except:
        return date_string

def format_time(time_string):
    """
    Format time string for display
    """
    from datetime import datetime
    if not time_string:
        return ""
    try:
        t = datetime.strptime(time_string, "%H:%M:%S")
        return t.strftime("%I:%M %p")
    except:
        return time_string

def validate_password_strength(password):
    """
    Validate password meets minimum requirements
    Returns: (is_valid, message)
    """
    if len(password) < 8:
        return False, "Password must be at least 8 characters"

    if not any(c.isupper() for c in password):
        return False, "Password must contain at least one uppercase letter"

    if not any(c.islower() for c in password):
        return False, "Password must contain at least one lowercase letter"

    if not any(c.isdigit() for c in password):
        return False, "Password must contain at least one number"

    return True, "Password is strong"

# Template filters (use in Jinja2 templates)
def register_template_filters(app):
    """Register custom Jinja2 filters"""
    app.jinja_env.filters['datetime'] = format_datetime
    app.jinja_env.filters['date'] = format_date
    app.jinja_env.filters['time'] = format_time
