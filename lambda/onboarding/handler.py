import json
import logging
import os

import boto3
from shared.db import get_connection, get_employee, update_employee_status

logger = logging.getLogger()
logger.setLevel(logging.INFO)

iam = boto3.client("iam")

DEPARTMENT_GROUP_MAP = {
    "IT": "IT-Staff",
    "HR": "HR-Staff",
    "Finance": "Finance-Staff",
}

DEFAULT_GROUP = os.environ.get("DEFAULT_GROUP", "General-Staff")


def get_group_for_employee(employee):
    return DEPARTMENT_GROUP_MAP.get(employee["department"], DEFAULT_GROUP)


def ensure_iam_user(email, name):
    username = email
    try:
        iam.get_user(UserName=username)
        logger.info("IAM user %s already exists", username)
    except iam.exceptions.NoSuchEntityException:
        logger.info("Creating IAM user %s", username)
        iam.create_user(
            UserName=username,
            Tags=[
                {"Key": "Name", "Value": name},
                {"Key": "Email", "Value": email},
            ],
        )
    return username


def add_user_to_group(username, group_name):
    try:
        iam.get_group(GroupName=group_name)
    except iam.exceptions.NoSuchEntityException:
        logger.info("Creating IAM group %s", group_name)
        iam.create_group(GroupName=group_name)

    logger.info("Adding user %s to group %s", username, group_name)
    iam.add_user_to_group(UserName=username, GroupName=group_name)


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

            logger.info("Processing onboarding for %s", employee)

            if employee["status"] == "provisioned":
                logger.info("Already provisioned, skipping")
                return {"status": "already_provisioned"}

            username = ensure_iam_user(employee["email"], employee["name"])

            group_name = get_group_for_employee(employee)
            add_user_to_group(username, group_name)

            update_employee_status(cursor, employee_id, "provisioned")

            logger.info("Onboarding completed for employee %s", employee_id)
            return {"status": "provisioned", "employee_id": employee_id}

    except Exception as e:
        logger.exception("Onboarding failed")
        with conn.cursor() as cursor:
            update_employee_status(cursor, employee_id, "error")
        raise
    finally:
        conn.close()