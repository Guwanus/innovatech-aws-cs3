from pydantic import BaseModel, EmailStr
from typing import Optional


class EmployeeCreate(BaseModel):
    name: str
    email: EmailStr
    department: str
    role: str


class Employee(BaseModel):
    employee_id: int
    name: str
    email: EmailStr
    department: str
    role: str
    status: str


class EmployeeStatusUpdate(BaseModel):
    status: str
