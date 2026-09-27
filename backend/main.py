from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from hyperon import MeTTa
import json

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

class StudentApplication(BaseModel):
    name: str
    cgpa: float
    family_income: float
    attendance: float
    existing_aid: str

def run_metta_check(criterion: str, value, threshold, passed_msg: str, failed_msg: str):
    if criterion == "cgpa":
        result = value >= threshold
    elif criterion == "income":
        result = value <= threshold
    elif criterion == "attendance":
        result = value >= threshold
    elif criterion == "aid":
        result = value == "no"
    
    return {
        "criterion": criterion.upper(),
        "value": value,
        "threshold": threshold,
        "status": "PASSED ✓" if result else "FAILED ✗",
        "reason": passed_msg if result else failed_msg,
        "passed": result
    }

@app.post("/evaluate")
async def evaluate_student(student: StudentApplication):
    reasoning_steps = []
    
    # Step 1: Check CGPA
    step1 = run_metta_check(
        "cgpa", student.cgpa, 7.0,
        f"CGPA {student.cgpa} meets minimum requirement of 7.0",
        f"CGPA {student.cgpa} is below minimum requirement of 7.0"
    )
    reasoning_steps.append(step1)
    
    # Step 2: Check Income
    step2 = run_metta_check(
        "income", student.family_income, 300000,
        f"Family income ₹{student.family_income} is within eligible limit of ₹3,00,000",
        f"Family income ₹{student.family_income} exceeds eligible limit of ₹3,00,000"
    )
    reasoning_steps.append(step2)
    
    # Step 3: Check Attendance
    step3 = run_metta_check(
        "attendance", student.attendance, 75,
        f"Attendance {student.attendance}% meets minimum requirement of 75%",
        f"Attendance {student.attendance}% is below minimum requirement of 75%"
    )
    reasoning_steps.append(step3)
    
    # Step 4: Check Existing Aid
    step4 = run_metta_check(
        "aid", student.existing_aid, None,
        "No existing scholarship conflict detected",
        "Student is already receiving a scholarship"
    )
    reasoning_steps.append(step4)
    
    # Final Decision
    all_passed = all(step["passed"] for step in reasoning_steps)
    passed_count = sum(1 for step in reasoning_steps if step["passed"])
    confidence = (passed_count / len(reasoning_steps)) * 100
    
    decision = {
        "student_name": student.name,
        "decision": "APPROVED" if all_passed else "REJECTED",
        "confidence": f"{confidence:.0f}%",
        "reasoning_steps": reasoning_steps,
        "summary": f"Student {'meets' if all_passed else 'does not meet'} all {len(reasoning_steps)} criteria for scholarship allocation.",
        "challengeable": True
    }
    
    return decision

@app.get("/health")
async def health():
    return {"status": "GlassBox Agent is running"}
