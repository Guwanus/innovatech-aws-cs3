import json
import logging

import boto3
from shared.db import get_connection, get_employee, update_employee_status

logger = logging.getLogger()
logger.setLevel(logging.INFO)

iam = boto3.client("iam")


def remove_user_from_all_groups(username):
    response = iam.list_groups_for_user(UserName=username)
    for group in response.get("Groups", []):
        group_name = group["GroupName"]
        logger.info("Removing user %s from group %s", username, group_name)
        iam.remove_user_from_group(UserName=username, GroupName=group_name)


def deactivate_user(username):
    remove_user_from_all_groups(username)
    logger.info("Tagging user %s as Disabled", username)
    iam.tag_user(
        UserName=username,
        Tags=[{"Key": "Status", "Value": "Disabled"}],
    )


def lambda_handler(event, context):
    logger.info("Received event: %s", json.dumps(event))

    employee_id = event.get("employee_id")
    if not employee_id:
        raise ValueError("employee_id missing from event")

    conn = get_connection()
    try:
        with conn.cursor() as cursor:
            employee = get_employee(cursor, employee_id)
            if not employee:
                raise ValueError(f"No employee found with id {employee_id}")

            logger.info("Processing offboarding for %s", employee)

            if employee["status"] == "disabled":
                logger.info("Already disabled, skipping")
                return {"status": "already_disabled"}

            username = employee["email"]
            deactivate_user(username)

            update_employee_status(cursor, employee_id, "disabled")

            logger.info("Offboarding completed for employee %s", employee_id)
            return {"status": "disabled", "employee_id": employee_id}

    except Exception:
        logger.exception("Offboarding failed")
        raise
    finally:
        conn.close()