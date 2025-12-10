from fastapi import FastAPI, HTTPException, Request, Form
from fastapi.responses import JSONResponse, HTMLResponse
from fastapi.templating import Jinja2Templates
import logging
from botocore.exceptions import NoCredentialsError, ClientError

import os
from typing import List

import boto3
from fastapi import FastAPI, HTTPException
from fastapi.responses import JSONResponse

from . import db
from .models import EmployeeCreate, Employee, EmployeeStatusUpdate

app = FastAPI(title="Innovatech Employee Portal")

templates = Jinja2Templates(directory="app/templates")
logger = logging.getLogger(__name__)

lambda_client = boto3.client("lambda", region_name=os.environ.get("AWS_REGION", "eu-central-1"))

ONBOARDING_LAMBDA_ARN = os.environ.get("ONBOARDING_LAMBDA_ARN")
OFFBOARDING_LAMBDA_ARN = os.environ.get("OFFBOARDING_LAMBDA_ARN")


@app.get("/health")
def health():
    return {"status": "ok"}

@app.get("/", response_class=HTMLResponse)
def employees_page(request: Request):
    employees = db.list_employees()
    return templates.TemplateResponse(
        "employees.html",
        {"request": request, "employees": employees}
    )

@app.get("/employees", response_model=List[Employee])
def list_all_employees():
    employees = db.list_employees()
    return employees


@app.get("/employees/{employee_id}", response_model=Employee)
def get_employee_by_id(employee_id: int):
    employee = db.get_employee(employee_id)
    if not employee:
        raise HTTPException(status_code=404, detail="Employee not found")
    return employee


@app.post("/employees", response_model=Employee, status_code=201)
def create_employee_endpoint(payload: EmployeeCreate):
    employee_id = db.create_employee(
        name=payload.name,
        email=payload.email,
        department=payload.department,
        role=payload.role,
    )

    employee = db.get_employee(employee_id)

    # Optionally auto-trigger onboarding:
    if ONBOARDING_LAMBDA_ARN:
        lambda_client.invoke(
            FunctionName=ONBOARDING_LAMBDA_ARN,
            InvocationType="Event",
            Payload=f'{{"employee_id": {employee_id}}}'.encode("utf-8"),
        )

    return employee

@app.post("/ui/employees", response_class=HTMLResponse)
def create_employee_form(
    request: Request,
    name: str = Form(...),
    email: str = Form(...),
    department: str = Form(...),
    role: str = Form(...),
):
    # Gebruik gewoon dezelfde logica als de JSON endpoint
    employee_id = db.create_employee(
        name=name,
        email=email,
        department=department,
        role=role,
    )
    employee = db.get_employee(employee_id)

    # Lambda invoke met logging, maar errors slopen de pagina niet
    if ONBOARDING_LAMBDA_ARN:
        try:
            logger.info("Invoking onboarding lambda for employee_id=%s (via UI)", employee_id)
            lambda_client.invoke(
                FunctionName=ONBOARDING_LAMBDA_ARN,
                InvocationType="Event",
                Payload=f'{{"employee_id": {employee_id}}}'.encode("utf-8"),
            )
        except NoCredentialsError:
            logger.warning("No AWS credentials found in portal task. Skipping Lambda invoke.")
        except ClientError as e:
            logger.error("Error invoking onboarding Lambda: %s", e)
        except Exception as e:
            logger.error("Unexpected error invoking onboarding Lambda: %s", e)

    # Redirect terug naar overzicht (simpelste manier: opnieuw renderen)
    employees = db.list_employees()
    return templates.TemplateResponse(
        "employees.html",
        {"request": request, "employees": employees}
    )

@app.post("/employees/{employee_id}/onboard")
def trigger_onboarding(employee_id: int):
    employee = db.get_employee(employee_id)
    if not employee:
        raise HTTPException(status_code=404, detail="Employee not found")

    if not ONBOARDING_LAMBDA_ARN:
        raise HTTPException(status_code=500, detail="Onboarding Lambda not configured")

    lambda_client.invoke(
        FunctionName=ONBOARDING_LAMBDA_ARN,
        InvocationType="Event",
        Payload=f'{{"employee_id": {employee_id}}}'.encode("utf-8"),
    )

    return JSONResponse({"message": "Onboarding triggered"})


@app.post("/employees/{employee_id}/offboard")
def trigger_offboarding(employee_id: int):
    employee = db.get_employee(employee_id)
    if not employee:
        raise HTTPException(status_code=404, detail="Employee not found")

    if not OFFBOARDING_LAMBDA_ARN:
        raise HTTPException(status_code=500, detail="Offboarding Lambda not configured")

    lambda_client.invoke(
        FunctionName=OFFBOARDING_LAMBDA_ARN,
        InvocationType="Event",
        Payload=f'{{"employee_id": {employee_id}}}'.encode("utf-8"),
    )

    return JSONResponse({"message": "Offboarding triggered"})

@app.post("/ui/employees/{employee_id}/onboard", response_class=HTMLResponse)
def onboard_employee_from_ui(request: Request, employee_id: int):
    # Hergebruik de bestaande logic
    resp = trigger_onboarding(employee_id)
    logger.info("UI onboard triggered for employee_id=%s result=%s", employee_id, resp)

    employees = db.list_employees()
    return templates.TemplateResponse(
        "employees.html",
        {"request": request, "employees": employees}
    )


@app.post("/ui/employees/{employee_id}/offboard", response_class=HTMLResponse)
def offboard_employee_from_ui(request: Request, employee_id: int):
    resp = trigger_offboarding(employee_id)
    logger.info("UI offboard triggered for employee_id=%s result=%s", employee_id, resp)

    employees = db.list_employees()
    return templates.TemplateResponse(
        "employees.html",
        {"request": request, "employees": employees}
    )

@app.patch("/employees/{employee_id}/status", response_model=Employee)
def update_status(employee_id: int, payload: EmployeeStatusUpdate):
    employee = db.get_employee(employee_id)
    if not employee:
        raise HTTPException(status_code=404, detail="Employee not found")

    db.update_employee_status(employee_id, payload.status)
    updated = db.get_employee(employee_id)
    return updated