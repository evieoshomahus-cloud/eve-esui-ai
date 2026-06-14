from __future__ import annotations

from .schemas import AdmissionEstimateRequest, AdmissionEstimateResponse


GRADE_POINTS = {
    "A1": 10,
    "B2": 9,
    "B3": 8,
    "C4": 7,
    "C5": 6,
    "C6": 5,
    "D7": 2,
    "E8": 1,
    "F9": 0,
}


SCIENCE_KEYWORDS = ["computer", "cyber", "medicine", "nursing", "engineering", "biochemistry", "microbiology"]


def estimate_admission_readiness(payload: AdmissionEstimateRequest) -> AdmissionEstimateResponse:
    grades = [
        payload.english.upper(),
        payload.mathematics.upper(),
        payload.science.upper(),
        payload.fourth_subject.upper(),
    ]
    o_level_score = sum(GRADE_POINTS.get(grade, 0) for grade in grades)
    jamb_component = round((payload.jamb_score / 400) * 60)
    o_level_component = round((o_level_score / 40) * 40)
    readiness = max(0, min(100, jamb_component + o_level_component))

    reasons: list[str] = [
        f"JAMB contribution: {jamb_component}/60.",
        f"O-Level contribution: {o_level_component}/40.",
    ]
    recommendations: list[str] = []

    if payload.jamb_score < 180:
        recommendations.append("Strengthen JAMB preparation before applying to a competitive programme.")
    if any(GRADE_POINTS.get(grade, 0) < 5 for grade in grades):
        recommendations.append("Improve any O-Level subject below credit level because admission screening depends on required credits.")
    if any(keyword in payload.course.lower() for keyword in SCIENCE_KEYWORDS) and GRADE_POINTS.get(payload.mathematics.upper(), 0) < 7:
        recommendations.append("For science and computing programmes, raise Mathematics performance and practise quantitative reasoning.")
    if not recommendations:
        recommendations.append("Maintain official admission monitoring and prepare documents early for screening.")

    if readiness >= 78:
        band = "Strong readiness"
    elif readiness >= 60:
        band = "Moderate readiness"
    else:
        band = "Needs improvement"

    return AdmissionEstimateResponse(
        course=payload.course,
        readiness_score=readiness,
        band=band,
        reasons=reasons,
        recommendations=recommendations,
    )

