from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Optional

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

class StudentApplication(BaseModel):
    name: str
    scenario: str  # "scholarship", "lab_access", "project_funding"
    cgpa: float
    attendance: float
    family_income: Optional[float] = None
    existing_aid: Optional[str] = None
    department: Optional[str] = None
    project_score: Optional[float] = None

SCENARIOS = {
    "scholarship": {
        "title": "Scholarship Allocation",
        "icon": "🎓",
        "rules": {
            "cgpa": {"min": 7.0, "label": "Academic Excellence"},
            "income": {"max": 300000, "label": "Financial Need"},
            "attendance": {"min": 75, "label": "Commitment"},
            "aid": {"label": "No Aid Conflict"},
        }
    },
    "lab_access": {
        "title": "Lab Access Request",
        "icon": "🔬",
        "rules": {
            "cgpa": {"min": 6.0, "label": "Academic Standing"},
            "attendance": {"min": 80, "label": "Reliability"},
            "department": {"allowed": ["science", "engineering", "cs", "ece", "eee", "mech"],
                          "label": "Department Eligibility"},
        }
    },
    "project_funding": {
        "title": "Project Funding Request",
        "icon": "💡",
        "rules": {
            "cgpa": {"min": 7.5, "label": "Academic Excellence"},
            "attendance": {"min": 70, "label": "Engagement"},
            "project_score": {"min": 60, "label": "Project Viability"},
        }
    }
}

def evaluate_scholarship(student):
    steps = []

    # CGPA
    passed = student.cgpa >= 7.0
    steps.append({
        "criterion": "CGPA",
        "label": "Academic Excellence",
        "value": f"{student.cgpa}",
        "threshold": "Minimum 7.0",
        "status": "PASSED ✓" if passed else "FAILED ✗",
        "reason": f"CGPA {student.cgpa} {'meets' if passed else 'does not meet'} minimum requirement of 7.0",
        "passed": passed
    })

    # Income
    passed = student.family_income <= 300000 if student.family_income else False
    steps.append({
        "criterion": "INCOME",
        "label": "Financial Need",
        "value": f"₹{student.family_income:,.0f}" if student.family_income else "N/A",
        "threshold": "Maximum ₹3,00,000",
        "status": "PASSED ✓" if passed else "FAILED ✗",
        "reason": f"Family income {'is within' if passed else 'exceeds'} the eligible limit of ₹3,00,000",
        "passed": passed
    })

    # Attendance
    passed = student.attendance >= 75
    steps.append({
        "criterion": "ATTENDANCE",
        "label": "Commitment",
        "value": f"{student.attendance}%",
        "threshold": "Minimum 75%",
        "status": "PASSED ✓" if passed else "FAILED ✗",
        "reason": f"Attendance {student.attendance}% {'meets' if passed else 'is below'} minimum of 75%",
        "passed": passed
    })

    # Existing Aid
    passed = student.existing_aid == "no"
    steps.append({
        "criterion": "EXISTING AID",
        "label": "No Aid Conflict",
        "value": student.existing_aid or "N/A",
        "threshold": "Must have no existing aid",
        "status": "PASSED ✓" if passed else "FAILED ✗",
        "reason": "No existing scholarship conflict detected" if passed else "Student is already receiving a scholarship",
        "passed": passed
    })

    return steps

def evaluate_lab_access(student):
    steps = []

    # CGPA
    passed = student.cgpa >= 6.0
    steps.append({
        "criterion": "CGPA",
        "label": "Academic Standing",
        "value": f"{student.cgpa}",
        "threshold": "Minimum 6.0",
        "status": "PASSED ✓" if passed else "FAILED ✗",
        "reason": f"CGPA {student.cgpa} {'meets' if passed else 'does not meet'} minimum of 6.0 for lab access",
        "passed": passed
    })

    # Attendance
    passed = student.attendance >= 80
    steps.append({
        "criterion": "ATTENDANCE",
        "label": "Reliability",
        "value": f"{student.attendance}%",
        "threshold": "Minimum 80%",
        "status": "PASSED ✓" if passed else "FAILED ✗",
        "reason": f"Attendance {student.attendance}% {'meets' if passed else 'is below'} minimum of 80% for lab access",
        "passed": passed
    })

    # Department
    dept = (student.department or "").lower()
    allowed = ["science", "engineering", "cs", "ece", "eee", "mech"]
    passed = any(d in dept for d in allowed)
    steps.append({
        "criterion": "DEPARTMENT",
        "label": "Department Eligibility",
        "value": student.department or "N/A",
        "threshold": "Science or Engineering",
        "status": "PASSED ✓" if passed else "FAILED ✗",
        "reason": f"Department '{student.department}' {'is' if passed else 'is not'} eligible for lab access",
        "passed": passed
    })

    return steps

def evaluate_project_funding(student):
    steps = []

    # CGPA
    passed = student.cgpa >= 7.5
    steps.append({
        "criterion": "CGPA",
        "label": "Academic Excellence",
        "value": f"{student.cgpa}",
        "threshold": "Minimum 7.5",
        "status": "PASSED ✓" if passed else "FAILED ✗",
        "reason": f"CGPA {student.cgpa} {'meets' if passed else 'does not meet'} minimum of 7.5 for funding",
        "passed": passed
    })

    # Attendance
    passed = student.attendance >= 70
    steps.append({
        "criterion": "ATTENDANCE",
        "label": "Engagement",
        "value": f"{student.attendance}%",
        "threshold": "Minimum 70%",
        "status": "PASSED ✓" if passed else "FAILED ✗",
        "reason": f"Attendance {student.attendance}% {'meets' if passed else 'is below'} minimum of 70% for funding",
        "passed": passed
    })

    # Project Score
    passed = (student.project_score or 0) >= 60
    steps.append({
        "criterion": "PROJECT SCORE",
        "label": "Project Viability",
        "value": f"{student.project_score}%" if student.project_score else "N/A",
        "threshold": "Minimum 60%",
        "status": "PASSED ✓" if passed else "FAILED ✗",
        "reason": f"Project score {student.project_score}% {'meets' if passed else 'does not meet'} viability threshold of 60%",
        "passed": passed
    })

    return steps

@app.post("/evaluate")
async def evaluate_student(student: StudentApplication):
    if student.scenario == "scholarship":
        steps = evaluate_scholarship(student)
    elif student.scenario == "lab_access":
        steps = evaluate_lab_access(student)
    elif student.scenario == "project_funding":
        steps = evaluate_project_funding(student)
    else:
        return {"error": "Invalid scenario"}

    all_passed = all(s["passed"] for s in steps)
    passed_count = sum(1 for s in steps if s["passed"])
    confidence = (passed_count / len(steps)) * 100
    scenario_info = SCENARIOS[student.scenario]

    return {
        "student_name": student.name,
        "scenario": student.scenario,
        "scenario_title": scenario_info["title"],
        "scenario_icon": scenario_info["icon"],
        "decision": "APPROVED" if all_passed else "REJECTED",
        "confidence": f"{confidence:.0f}%",
        "reasoning_steps": steps,
        "summary": f"Student {'meets' if all_passed else 'does not meet'} all {len(steps)} criteria for {scenario_info['title']}.",
        "challengeable": True
    }

@app.get("/health")
async def health():
    return {"status": "GlassBox Agent running", "scenarios": list(SCENARIOS.keys())}

@app.get("/scenarios")
async def get_scenarios():
    return SCENARIOS
