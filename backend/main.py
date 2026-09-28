from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Optional, List

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

class StudentApplication(BaseModel):
    name: str
    scenario: str
    cgpa: float
    attendance: float
    family_income: Optional[float] = None
    existing_aid: Optional[str] = None
    department: Optional[str] = None
    project_score: Optional[float] = None

class ChallengeRequest(BaseModel):
    student: StudentApplication
    challenged_criterion: str
    challenge_reason: str
    new_value: Optional[str] = None

class AppealRequest(BaseModel):
    student: StudentApplication
    appeal_reason: str
    supporting_info: str

class WhatIfRequest(BaseModel):
    student: StudentApplication
    target_criterion: str

SCENARIOS = {
    "scholarship": {
        "title": "Scholarship Allocation",
        "icon": "🎓",
        "color": "6C63FF",
        "thresholds": {
            "cgpa": {"min": 7.0, "label": "Academic Excellence"},
            "income": {"max": 300000, "label": "Financial Need"},
            "attendance": {"min": 75, "label": "Commitment"},
            "aid": {"label": "No Aid Conflict"},
        }
    },
    "lab_access": {
        "title": "Lab Access Request",
        "icon": "🔬",
        "color": "00BCD4",
        "thresholds": {
            "cgpa": {"min": 6.0, "label": "Academic Standing"},
            "attendance": {"min": 80, "label": "Reliability"},
            "department": {"label": "Department Eligibility"},
        }
    },
    "project_funding": {
        "title": "Project Funding Request",
        "icon": "💡",
        "color": "FFB300",
        "thresholds": {
            "cgpa": {"min": 7.5, "label": "Academic Excellence"},
            "attendance": {"min": 70, "label": "Engagement"},
            "project_score": {"min": 60, "label": "Project Viability"},
        }
    }
}

FAILURE_EXPLANATIONS = {
    "CGPA": {
        "scholarship": "Your CGPA is below the minimum 7.0 required for scholarship. This ensures recipients maintain strong academic performance. Consider improving your grades next semester.",
        "lab_access": "Lab access requires minimum CGPA of 6.0 to ensure students can handle advanced equipment safely and productively.",
        "project_funding": "Project funding requires CGPA of 7.5+ to ensure the student has the academic capability to complete the project successfully."
    },
    "INCOME": {
        "scholarship": "Family income exceeds ₹3,00,000 annual limit. This scholarship is need-based and prioritizes financially disadvantaged students."
    },
    "ATTENDANCE": {
        "scholarship": "Attendance below 75% suggests inconsistent commitment. Scholarship recipients must demonstrate regular academic engagement.",
        "lab_access": "Lab access requires 80%+ attendance as safety protocols demand consistent presence and training.",
        "project_funding": "Project funding requires 70%+ attendance to ensure the student can dedicate time to complete the project."
    },
    "EXISTING AID": {
        "scholarship": "You are already receiving financial aid. This scholarship targets students without existing support to maximize reach."
    },
    "DEPARTMENT": {
        "lab_access": "This lab is designated for Science and Engineering departments only due to equipment relevance and safety requirements."
    },
    "PROJECT SCORE": {
        "project_funding": "Project viability score below 60% indicates the proposal needs more development. Consider strengthening your methodology and objectives."
    }
}

def evaluate_scholarship(student):
    steps = []
    passed = student.cgpa >= 7.0
    steps.append({
        "criterion": "CGPA", "label": "Academic Excellence",
        "value": f"{student.cgpa}", "threshold": "Minimum 7.0",
        "status": "PASSED ✓" if passed else "FAILED ✗",
        "reason": f"CGPA {student.cgpa} {'meets' if passed else 'does not meet'} minimum of 7.0",
        "failure_explanation": FAILURE_EXPLANATIONS["CGPA"]["scholarship"] if not passed else None,
        "what_if_hint": f"You need CGPA of 7.0 to pass this step. You are {7.0 - student.cgpa:.1f} points away." if not passed else None,
        "passed": passed
    })
    passed = student.family_income <= 300000 if student.family_income else False
    steps.append({
        "criterion": "INCOME", "label": "Financial Need",
        "value": f"₹{student.family_income:,.0f}" if student.family_income else "N/A",
        "threshold": "Maximum ₹3,00,000",
        "status": "PASSED ✓" if passed else "FAILED ✗",
        "reason": f"Family income {'is within' if passed else 'exceeds'} the eligible limit of ₹3,00,000",
        "failure_explanation": FAILURE_EXPLANATIONS["INCOME"]["scholarship"] if not passed else None,
        "what_if_hint": f"Maximum allowed income is ₹3,00,000. Your income exceeds by ₹{student.family_income - 300000:,.0f}." if not passed else None,
        "passed": passed
    })
    passed = student.attendance >= 75
    steps.append({
        "criterion": "ATTENDANCE", "label": "Commitment",
        "value": f"{student.attendance}%", "threshold": "Minimum 75%",
        "status": "PASSED ✓" if passed else "FAILED ✗",
        "reason": f"Attendance {student.attendance}% {'meets' if passed else 'is below'} minimum of 75%",
        "failure_explanation": FAILURE_EXPLANATIONS["ATTENDANCE"]["scholarship"] if not passed else None,
        "what_if_hint": f"You need {75 - student.attendance:.1f}% more attendance to qualify." if not passed else None,
        "passed": passed
    })
    passed = student.existing_aid == "no"
    steps.append({
        "criterion": "EXISTING AID", "label": "No Aid Conflict",
        "value": student.existing_aid or "N/A", "threshold": "Must have no existing aid",
        "status": "PASSED ✓" if passed else "FAILED ✗",
        "reason": "No existing scholarship conflict detected" if passed else "Student is already receiving a scholarship",
        "failure_explanation": FAILURE_EXPLANATIONS["EXISTING AID"]["scholarship"] if not passed else None,
        "what_if_hint": "You must not have any existing scholarship to apply for this one." if not passed else None,
        "passed": passed
    })
    return steps

def evaluate_lab_access(student):
    steps = []
    passed = student.cgpa >= 6.0
    steps.append({
        "criterion": "CGPA", "label": "Academic Standing",
        "value": f"{student.cgpa}", "threshold": "Minimum 6.0",
        "status": "PASSED ✓" if passed else "FAILED ✗",
        "reason": f"CGPA {student.cgpa} {'meets' if passed else 'does not meet'} minimum of 6.0",
        "failure_explanation": FAILURE_EXPLANATIONS["CGPA"]["lab_access"] if not passed else None,
        "what_if_hint": f"You need {6.0 - student.cgpa:.1f} more CGPA points for lab access." if not passed else None,
        "passed": passed
    })
    passed = student.attendance >= 80
    steps.append({
        "criterion": "ATTENDANCE", "label": "Reliability",
        "value": f"{student.attendance}%", "threshold": "Minimum 80%",
        "status": "PASSED ✓" if passed else "FAILED ✗",
        "reason": f"Attendance {student.attendance}% {'meets' if passed else 'is below'} minimum of 80%",
        "failure_explanation": FAILURE_EXPLANATIONS["ATTENDANCE"]["lab_access"] if not passed else None,
        "what_if_hint": f"You need {80 - student.attendance:.1f}% more attendance." if not passed else None,
        "passed": passed
    })
    dept = (student.department or "").lower()
    allowed = ["science", "engineering", "cs", "ece", "eee", "mech"]
    passed = any(d in dept for d in allowed)
    steps.append({
        "criterion": "DEPARTMENT", "label": "Department Eligibility",
        "value": student.department or "N/A", "threshold": "Science or Engineering",
        "status": "PASSED ✓" if passed else "FAILED ✗",
        "reason": f"Department '{student.department}' {'is' if passed else 'is not'} eligible",
        "failure_explanation": FAILURE_EXPLANATIONS["DEPARTMENT"]["lab_access"] if not passed else None,
        "what_if_hint": "Eligible departments: CS, ECE, EEE, Mechanical, Science, Engineering." if not passed else None,
        "passed": passed
    })
    return steps

def evaluate_project_funding(student):
    steps = []
    passed = student.cgpa >= 7.5
    steps.append({
        "criterion": "CGPA", "label": "Academic Excellence",
        "value": f"{student.cgpa}", "threshold": "Minimum 7.5",
        "status": "PASSED ✓" if passed else "FAILED ✗",
        "reason": f"CGPA {student.cgpa} {'meets' if passed else 'does not meet'} minimum of 7.5",
        "failure_explanation": FAILURE_EXPLANATIONS["CGPA"]["project_funding"] if not passed else None,
        "what_if_hint": f"You need {7.5 - student.cgpa:.1f} more CGPA points for project funding." if not passed else None,
        "passed": passed
    })
    passed = student.attendance >= 70
    steps.append({
        "criterion": "ATTENDANCE", "label": "Engagement",
        "value": f"{student.attendance}%", "threshold": "Minimum 70%",
        "status": "PASSED ✓" if passed else "FAILED ✗",
        "reason": f"Attendance {student.attendance}% {'meets' if passed else 'is below'} minimum of 70%",
        "failure_explanation": FAILURE_EXPLANATIONS["ATTENDANCE"]["project_funding"] if not passed else None,
        "what_if_hint": f"You need {70 - student.attendance:.1f}% more attendance." if not passed else None,
        "passed": passed
    })
    passed = (student.project_score or 0) >= 60
    steps.append({
        "criterion": "PROJECT SCORE", "label": "Project Viability",
        "value": f"{student.project_score}%" if student.project_score else "N/A",
        "threshold": "Minimum 60%",
        "status": "PASSED ✓" if passed else "FAILED ✗",
        "reason": f"Project score {student.project_score}% {'meets' if passed else 'does not meet'} threshold of 60%",
        "failure_explanation": FAILURE_EXPLANATIONS["PROJECT SCORE"]["project_funding"] if not passed else None,
        "what_if_hint": f"You need {60 - (student.project_score or 0):.1f}% more in project score." if not passed else None,
        "passed": passed
    })
    return steps

def run_evaluation(student):
    if student.scenario == "scholarship":
        steps = evaluate_scholarship(student)
    elif student.scenario == "lab_access":
        steps = evaluate_lab_access(student)
    elif student.scenario == "project_funding":
        steps = evaluate_project_funding(student)
    else:
        return None, None

    all_passed = all(s["passed"] for s in steps)
    passed_count = sum(1 for s in steps if s["passed"])
    confidence = (passed_count / len(steps)) * 100
    failed_steps = [s for s in steps if not s["passed"]]

    return steps, {
        "student_name": student.name,
        "scenario": student.scenario,
        "scenario_title": SCENARIOS[student.scenario]["title"],
        "scenario_icon": SCENARIOS[student.scenario]["icon"],
        "decision": "APPROVED" if all_passed else "REJECTED",
        "confidence": f"{confidence:.0f}%",
        "confidence_value": confidence,
        "reasoning_steps": steps,
        "failed_steps": [s["criterion"] for s in failed_steps],
        "summary": f"Student {'meets' if all_passed else 'does not meet'} all {len(steps)} criteria for {SCENARIOS[student.scenario]['title']}.",
        "challengeable": True,
        "appeal_available": not all_passed
    }

@app.post("/evaluate")
async def evaluate_student(student: StudentApplication):
    _, result = run_evaluation(student)
    if result is None:
        return {"error": "Invalid scenario"}
    return result

@app.post("/challenge")
async def challenge_decision(request: ChallengeRequest):
    _, original = run_evaluation(request.student)
    return {
        "challenge_received": True,
        "challenged_criterion": request.challenged_criterion,
        "challenge_reason": request.challenge_reason,
        "agent_response": f"Your challenge on '{request.challenged_criterion}' has been noted. Reason: '{request.challenge_reason}'. This has been flagged for human review. The original decision stands pending verification.",
        "status": "UNDER_REVIEW",
        "original_decision": original["decision"],
        "review_message": f"A human reviewer will examine your challenge on '{request.challenged_criterion}' within 3 working days.",
        "challenge_id": f"CHG-{hash(request.challenge_reason) % 10000:04d}"
    }

@app.post("/whatif")
async def what_if(request: WhatIfRequest):
    _, result = run_evaluation(request.student)
    steps = result["reasoning_steps"]
    target = next((s for s in steps if s["criterion"] == request.target_criterion), None)

    if not target:
        return {"error": "Criterion not found"}

    return {
        "criterion": request.target_criterion,
        "current_value": target["value"],
        "current_status": target["status"],
        "what_if_hint": target.get("what_if_hint", "You already meet this requirement!"),
        "threshold": target["threshold"],
        "passed": target["passed"]
    }

@app.post("/appeal")
async def appeal_decision(request: AppealRequest):
    _, result = run_evaluation(request.student)
    appeal_id = f"APL-{hash(request.appeal_reason) % 10000:04d}"
    return {
        "appeal_received": True,
        "appeal_id": appeal_id,
        "student_name": request.student.name,
        "original_decision": result["decision"],
        "appeal_reason": request.appeal_reason,
        "supporting_info": request.supporting_info,
        "agent_response": f"Appeal {appeal_id} submitted successfully. Your appeal for {result['scenario_title']} has been received. Supporting information noted: '{request.supporting_info}'. Expected review time: 5-7 working days.",
        "status": "APPEAL_SUBMITTED",
        "next_steps": [
            "Your appeal has been logged in the system",
            "A committee will review your supporting information",
            "You will be notified of the outcome within 7 days",
            "Keep your documents ready for verification"
        ]
    }

@app.get("/health")
async def health():
    return {"status": "GlassBox Agent running", "scenarios": list(SCENARIOS.keys())}

@app.get("/scenarios")
async def get_scenarios():
    return SCENARIOS
