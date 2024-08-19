create database Healthcare_data;

use healthcare_data;

-- drop table patient_demographics;
-- drop table patient_health;


CREATE TABLE patient_demographics (
    encounter_id INT NOT NULL PRIMARY KEY,
    patient_nbr INT,
    race VARCHAR(255),
    gender VARCHAR(255),
    age VARCHAR(10), -- Changed to VARCHAR to handle range values
    weight VARCHAR(10) -- Changed to VARCHAR to handle non-numeric values
);


select count(*) from patient_demographics;

CREATE TABLE patient_health (
    encounter_id INT NOT NULL,
    admission_type_id INT,
    discharge_disposition_id INT,
    admission_source_id INT,
    time_in_hospital INT,
    diag_1 VARCHAR(255),
    diag_2 VARCHAR(255),
    diag_3 VARCHAR(255),
    number_diagnoses INT,
    max_glu_serum VARCHAR(255),
    A1Cresult VARCHAR(255),
    diabetesMed VARCHAR(50),
    metformin VARCHAR(50),
    insulin VARCHAR(50),
    medical_specialty VARCHAR(255),
    num_lab_procedures INT,
    num_procedures INT,
    num_medications INT,
    number_outpatient INT,
    number_emergency INT,
    number_inpatient INT,
    PRIMARY KEY (encounter_id),
    FOREIGN KEY (encounter_id) REFERENCES patient_demographics(encounter_id)
);

select count(*) from diabetic_data;

CREATE TABLE diabetic_data (
    encounter_id int ,
    patient_nbr int,
    race VARCHAR(255),
    gender VARCHAR(50),
    age VARCHAR(50),
    weight VARCHAR(50),
    admission_type_id INT,
    discharge_disposition_id INT,
    admission_source_id INT,
    time_in_hospital INT,
    payer_code VARCHAR(50),
    medical_specialty VARCHAR(255),
    num_lab_procedures INT,
    num_procedures INT,
    num_medications INT,
    number_outpatient INT,
    number_emergency INT,
    number_inpatient INT,
    diag_1 VARCHAR(255),
    diag_2 VARCHAR(255),
    diag_3 VARCHAR(255),
    number_diagnoses INT,
    max_glu_serum VARCHAR(50),
    A1Cresult VARCHAR(50),
    metformin VARCHAR(50),
    repaglinide VARCHAR(50),
    nateglinide VARCHAR(50),
    chlorpropamide VARCHAR(50),
    glimepiride VARCHAR(50),
    acetohexamide VARCHAR(50),
    glipizide VARCHAR(50),
    glyburide VARCHAR(50),
    tolbutamide VARCHAR(50),
    pioglitazone VARCHAR(50),
    rosiglitazone VARCHAR(50),
    acarbose VARCHAR(50),
    miglitol VARCHAR(50),
    troglitazone VARCHAR(50),
    tolazamide VARCHAR(50),
    examide VARCHAR(50),
    citoglipton VARCHAR(50),
    insulin VARCHAR(50),
    glyburide_metformin VARCHAR(50),
    glipizide_metformin VARCHAR(50),
    glimepiride_pioglitazone VARCHAR(50),
    metformin_rosiglitazone VARCHAR(50),
    metformin_pioglitazone VARCHAR(50),
    `change` VARCHAR(50),  -- "change" is a reserved keyword, so it should be enclosed in backticks
    diabetesMed VARCHAR(50),
    readmitted VARCHAR(50),
    PRIMARY KEY (encounter_id)
);


select count(*) from patient_health;

-- The health care management wants to know the distribution of time spent in the hospital in general


select time_in_hospital as total_days, count(*) as count,
	RPAD('', count(*)/100, '*') as bar
from patient_health
group by total_days
order by total_days;

-- Calculate the average 'time_in_hospital' by age group:

select age, round(avg(time_in_hospital), 2) as avg_hospital_stay
from patient_demographics pd
join patient_health ph on pd.encounter_id = ph.encounter_id
group by age
order by age desc;

-- Determine the distribution of diagnoses:

select diag_1, count(*) as count
from patient_health
group by diag_1
order by count desc;

/*  Budget management- A brand-new hospital director wants a list of all specialties
 and the average total of the number of procedures currently practiced at the hospital.*/

select distinct medical_specialty, count(*) as total,
round(avg(num_procedures), 1) as average_procedures
from patient_health
where not medical_specialty = '?'
group by medical_specialty
order by average_procedures desc;

-- added the filter for total equal or more than 50 with average_procedures more than 2.5. 

select distinct medical_specialty, count(*) as total,
round(avg(num_procedures), 1) as average_procedures
from patient_health
where not medical_specialty = '?'
group by medical_specialty
having total > 50 and average_procedures > 2.5
order by average_procedures desc;

/* Integrity- The Chief of Nursing wants to know if the hospital seems 
to be treating patients of different races differently, specifically with 
the number of lab procedures done.*/

select d.race, round(avg(h.num_lab_procedures),1) as avg_num_lab_procedures
from patient_health h
join patient_demographics d on h.encounter_id = d.encounter_id
group by d.race
order by avg_num_lab_procedures desc;

/* Challenge 4: Do people need more procedures if they stay longer in the hospital? */

-- step 1

select min(num_lab_procedures) as mininum, max(num_lab_procedures) as maximum,
	round (avg(num_lab_procedures),0) as average
from patient_health;

-- step 2: use CASE WHEN function

select round(avg(time_in_hospital), 0) as days_stay,
	(case 
    when num_lab_procedures >= 0 and num_lab_procedures < 25 then "few"
    when num_lab_procedures >= 25 and num_lab_procedures < 55 then "average"
    when num_lab_procedures >= 55 then "many" end) as procedures_frequency
from patient_health
group by procedures_frequency
order by days_stay;
    
/* The Hospital Administrator wants to highlight some of the biggest success stories of 
the hospital. They are looking for opportunities when patients came into the hospital with an 
emergency (admission_type_id of 1) but stayed less than the average time in the hospital. */ 


with avg_time_hospital as(
select avg(time_in_hospital) as average
from patient_health
)
select count(*) as successful_case
from patient_health
where admission_type_id = 1
	 and time_in_hospital < (select * from avg_time_hospital);       -- 33684
     
SELECT DISTINCT COUNT(*) as total_patients
FROM patient_health;

/*  You just got an email from a co-worker in research. They want to do a 
medical test with anyone who is African American or had an “Up” for metformin. 
They need a list of patients' ids as fast as possible.*/

-- step 1:
select patient_nbr from patient_demographics where race = "African American"
union
select patient_nbr from diabetic_data where metformin = "Up";

-- step 2: CTE
with total_patients as(
select patient_nbr from patient_demographics where race = "African American"
union
select patient_nbr from diabetic_data where metformin = "Up"
)
select count(patient_nbr)
from total_patients;

/*The requirement is to write a summary for the top 50
 medication patients, and break any ties with the number of lab 
 procedures (highest at the top) by following the hospital’s format. 
*/

select concat('Patient ', d.patient_nbr, ' was ', db.race, ' and ',
	case 
		when d.readmitted = "NO" then "was not readmitted. They had " else
			"was readmitted. They had " end,
		d.num_medications, ' medication and ', d.num_lab_procedures, ' lab procedures. ') as Summary

from diabetic_data d
join patient_demographics db
on d.patient_nbr = db.patient_nbr
order by d.num_medications desc, num_lab_procedures desc
limit 50;
        
-- ***************************************************************************************************************
