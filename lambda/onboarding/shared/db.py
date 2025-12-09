import os
import pymysql


def get_connection():
    return pymysql.connect(
        host=os.environ["DB_HOST"],
        user=os.environ["DB_USER"],
        password=os.environ["DB_PASSWORD"],
        database=os.environ["DB_NAME"],
        port=int(os.environ.get("DB_PORT", "3306")),
        connect_timeout=5,
        autocommit=True,
    )


def get_employee(cursor, employee_id):
    sql = """
        SELECT employee_id, name, email, department, role, status
        FROM employee
        WHERE employee_id = %s
    """
    cursor.execute(sql, (employee_id,))
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


def update_employee_status(cursor, employee_id, new_status):
    sql = "UPDATE employee SET status = %s WHERE employee_id = %s"
    cursor.execute(sql, (new_status, employee_id))