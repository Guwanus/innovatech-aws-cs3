import os
import pymysql


def get_connection():
    return pymysql.connect(
        host=os.environ["DB_HOST"],
        user=os.environ["DB_USER"],
        password=os.environ["DB_PASSWORD"],
        database=os.environ["DB_NAME"],
        port=int(os.environ.get("DB_PORT", "3306")),
        autocommit=True,
        connect_timeout=5,
    )


def list_employees():
    conn = get_connection()
    try:
        with conn.cursor() as cursor:
            cursor.execute(
                """
                SELECT employee_id, name, email, department, role, status
                FROM employee
                ORDER BY employee_id DESC
                """
            )
            rows = cursor.fetchall()
            return [
                {
                    "employee_id": r[0],
                    "name": r[1],
                    "email": r[2],
                    "department": r[3],
                    "role": r[4],
                    "status": r[5],
                }
                for r in rows
            ]
    finally:
        conn.close()


def get_employee(employee_id: int):
    conn = get_connection()
    try:
        with conn.cursor() as cursor:
            cursor.execute(
                """
                SELECT employee_id, name, email, department, role, status
                FROM employee
                WHERE employee_id = %s
                """,
                (employee_id,),
            )
            row = cursor.fetchone()
            if not row:
                return None
            return {
                "employee_id": row[0],
                "name": row[1],
                "email": row[2],
                "department": row[3],
                "role": row[4],
                "status": row[5],
            }
    finally:
        conn.close()


def create_employee(name: str, email: str, department: str, role: str):
    conn = get_connection()
    try:
        with conn.cursor() as cursor:
            cursor.execute(
                """
                INSERT INTO employee (name, email, department, role, status)
                VALUES (%s, %s, %s, %s, 'pending')
                """,
                (name, email, department, role),
            )
            employee_id = cursor.lastrowid
            return employee_id
    finally:
        conn.close()


def update_employee_status(employee_id: int, status: str):
    conn = get_connection()
    try:
        with conn.cursor() as cursor:
            cursor.execute(
                "UPDATE employee SET status = %s WHERE employee_id = %s",
                (status, employee_id),
            )
    finally:
        conn.close()
