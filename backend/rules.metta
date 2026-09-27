; Scholarship eligibility rules
(= (min-cgpa) 7.0)
(= (max-income) 300000)
(= (min-attendance) 75)

; Check each criterion
(= (check-cgpa $cgpa)
   (if (>= $cgpa (min-cgpa))
       (passed "CGPA is above minimum requirement")
       (failed "CGPA is below minimum requirement")))

(= (check-income $income)
   (if (<= $income (max-income))
       (passed "Family income is within eligible range")
       (failed "Family income exceeds eligible limit")))

(= (check-attendance $attendance)
   (if (>= $attendance (min-attendance))
       (passed "Attendance meets minimum requirement")
       (failed "Attendance is below minimum requirement")))

(= (check-existing-aid $aid)
   (if (== $aid "no")
       (passed "No existing aid conflict")
       (failed "Already receiving scholarship")))
