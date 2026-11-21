#create database hospital_overview;
use hospital_overview;
select * from Admission;
select * from patient;

          #Hospital Overview
create view total_admission as
select count(*) as total_adm from admission;
select * from total_admission;

create view total_patients as
select count(distinct patient_id) as total_pat from admission;
select * from total_patients;

create view total_revenue as
select sum(bill_amount_cleaned) as total_rev from admission where bill_status in ("Valid","Refunds");
select * from total_revenue;

create view average_bill as 
select round(avg(bill_amount_cleaned),2) as ave_bill from admission where bill_status ="Valid" ;
select * from average_bill;

CREATE view avg_len_of_stay AS
SELECT
    ROUND(AVG(stay_days), 2) AS average_length_of_stay
FROM (
    SELECT
        DATEDIFF(
            STR_TO_DATE(dis_date, '%d-%m-%Y'),
            STR_TO_DATE(Adm_date, '%d-%m-%Y')
        ) AS stay_days
    FROM admission
) AS date_calculations
WHERE stay_days IS NOT NULL
  AND stay_days >= 0;
 select * from avg_len_of_stay;
 
               # admission by month
create or replace view monthly_admission_trends as
SELECT
    MONTHNAME(STR_TO_DATE(Adm_date, '%d-%m-%Y')) AS Month_Name, dept ,
    COUNT(*) AS Total_Admissions , patient_id
FROM admission
WHERE Adm_date IS NOT NULL
GROUP BY MONTH(STR_TO_DATE(Adm_date, '%d-%m-%Y')), MONTHNAME(STR_TO_DATE(Adm_date, '%d-%m-%Y'))  , dept , patient_id
ORDER BY MONTH(STR_TO_DATE(Adm_date, '%d-%m-%Y'));
select * from monthly_admission_trends;

  # number of admission by department
create or replace view admission_by_dept as 
select dept as department_name, count(*) as total_admission , patient_id from admission group by dept, patient_id order by total_admission desc;
select * from admission_by_dept;
        
        # revenue by department
create or replace view revenue_by_depart as 
select dept as department_name , round(sum(bill_amount_cleaned),2) as total_revenue , patient_id from admission where bill_status="valid" group by dept ,patient_id order by total_revenue desc;
select * from revenue_by_depart;

     # gender distribution , used to count number of males and females
create or replace view gender_distribution as 
SELECT
    COALESCE(p.gender, 'Not Available') AS gender, a.dept , YEAR(STR_TO_DATE(a.Adm_date, '%d-%m-%Y')) AS admission_year ,
    COUNT(DISTINCT a.patient_id) AS total_patients , a.patient_id 
FROM admission a
LEFT JOIN patient p
    ON a.patient_id = p.patient_id
GROUP BY COALESCE(p.gender, 'Not Available'),a.dept,YEAR(STR_TO_DATE(a.Adm_date, '%d-%m-%Y')), a.patient_id ;
select * from gender_distribution;

      # Department and Doctor Analysis

create view total_department as 
select count(distinct dept) as total_dep from admission where dept is not null ;
select * from total_department;

create view total_doctor as
select count(distinct doctor_name) as total_doctor from admission ;
select * from total_doctor;

        # top 10 doctor by number of admission 
create or replace view top10_doctor_by_dep as
select doctor_name , dept as department , count(*) as total_admission from admission 
where doctor_name is not null group by doctor_name,dept  order by total_admission desc limit 10;
select * from top10_doctor_by_dep;

        # revenue by doctot top10
create or replace view revenue_by_doc as 
select  doctor_name , round(sum(bill_amount_cleaned),2) as total_revenue , patient_id from admission where bill_status="valid" group by doctor_name , patient_id order by total_revenue desc limit 10;
select * from revenue_by_doc;

                # averge length of stay by department
create or replace view average_length_of_stay_by_dept as
SELECT dept AS department, ROUND(AVG(DATEDIFF(
                STR_TO_DATE(dis_date, '%d-%m-%Y'),
                STR_TO_DATE(Adm_date, '%d-%m-%Y'))), 2) AS average_stay_days ,patient_id FROM admission
  WHERE Adm_date IS NOT NULL
  AND dis_date IS NOT NULL
  AND STR_TO_DATE(Adm_date, '%d-%m-%Y') IS NOT NULL
  AND STR_TO_DATE(dis_date, '%d-%m-%Y') IS NOT NULL
  AND STR_TO_DATE(dis_date, '%d-%m-%Y')
      >= STR_TO_DATE(Adm_date, '%d-%m-%Y')
GROUP BY dept , patient_id
ORDER BY average_stay_days DESC;
select * from average_length_of_stay_by_dept;
 
        # doctor perfrormance table
create view doctor_analys as
select  doctor_name,dept as department,count(*) as total_admission , round(sum(bill_amount_cleaned),2) as total_revenue,round(avg(bill_amount_cleaned),2) as average_revenue from admission where bill_status="valid" group by doctor_name, dept order by total_admission desc ;
select * from doctor_analys;
      
 #--------> patient and insurance analysis
 
 create view insurance_providers as
select count(distinct insurance) as total_insurance_providers from patient;
select * from insurance_providers;

create view average_age as
select round(avg(timestampdiff(year,str_to_date(DOB,'%d-%m-%Y'),CURDATE())),2) as averge_age from patient where DOB is not null and str_to_date(DOB,'%d-%m-%Y') is not null and str_to_date(DOB,'%d-%m-%Y') <= CURDATE();
select * from average_age;

create view insured_patients as 
select count(*) as insured_patient from patient where insurance not in ("Not Provided");
select * from insured_patients;

         # age_group : number of patients in age group
create or replace view age_group as
SELECT CASE
        WHEN TIMESTAMPDIFF(YEAR, STR_TO_DATE(DOB, '%d-%m-%Y'), CURDATE()) < 18 THEN 'Below 18'
        WHEN TIMESTAMPDIFF(YEAR, STR_TO_DATE(DOB, '%d-%m-%Y'), CURDATE()) BETWEEN 18 AND 30 THEN '18-30'
        WHEN TIMESTAMPDIFF(YEAR, STR_TO_DATE(DOB, '%d-%m-%Y'), CURDATE()) BETWEEN 31 AND 45 THEN '31-45'
        WHEN TIMESTAMPDIFF(YEAR, STR_TO_DATE(DOB, '%d-%m-%Y'), CURDATE()) BETWEEN 46 AND 60 THEN '46-60'
        ELSE 'Above 60'
    END AS age_group,
    COUNT(*) AS total_patients , patient_id 
FROM patient WHERE DOB IS NOT NULL
  AND STR_TO_DATE(DOB, '%d-%m-%Y') IS NOT NULL
  AND STR_TO_DATE(DOB, '%d-%m-%Y') <= CURDATE()
GROUP BY age_group , patient_id ORDER BY MIN(TIMESTAMPDIFF(YEAR, STR_TO_DATE(DOB, '%d-%m-%Y'), CURDATE()));
select * from age_group;

     # number of patients in each insurance provider
create or replace view insurance_by_patients as 
select insurance , count(*) as total_patients , patient_id from patient group by insurance , patient_id order by total_patients desc;
select * from insurance_by_patients;
        
        # revenue by insurance
create or replace view revenue_by_insurance as
select insurance , round(sum(bill_amount_cleaned),2) as net_revenue , p.patient_id from patient p left join admission a on p.patient_id = a.patient_id group by insurance , p.patient_id order by net_revenue desc;
select * from revenue_by_insurance;

      # age_group and gender ; number of M & F in a particular age group
create or replace view age_group_and_gender as
SELECT CASE
        WHEN TIMESTAMPDIFF(YEAR, STR_TO_DATE(DOB, '%d-%m-%Y'), CURDATE()) < 18 THEN 'Below 18'
        WHEN TIMESTAMPDIFF(YEAR, STR_TO_DATE(DOB, '%d-%m-%Y'), CURDATE()) BETWEEN 18 AND 30 THEN '18-30'
        WHEN TIMESTAMPDIFF(YEAR, STR_TO_DATE(DOB, '%d-%m-%Y'), CURDATE()) BETWEEN 31 AND 45 THEN '31-45'
        WHEN TIMESTAMPDIFF(YEAR, STR_TO_DATE(DOB, '%d-%m-%Y'), CURDATE()) BETWEEN 46 AND 60 THEN '46-60'
        ELSE 'Above 60'
    END AS age_group, gender ,
    COUNT(*) AS total_patients , patient_id 
FROM patient WHERE DOB IS NOT NULL
  AND STR_TO_DATE(DOB, '%d-%m-%Y') IS NOT NULL
  AND STR_TO_DATE(DOB, '%d-%m-%Y') <= CURDATE()
GROUP BY age_group ,patient_id , gender ORDER BY MIN(TIMESTAMPDIFF(YEAR, STR_TO_DATE(DOB, '%d-%m-%Y'), CURDATE()));
select * from age_group_and_gender;

   # insurance details table 
create or replace view insurance_details as
select p.insurance as insurance_provider , count(distinct p.patient_id) as total_patients, count(a.adm_id) as total_admission ,
			     round(sum(a.bill_amount_cleaned),2) as net_revenue , round(avg(a.bill_amount_cleaned),2) as average_bill 
from patient p left join admission a on p.patient_id = a.patient_id group by p.insurance order by net_revenue desc;
select * from insurance_details;

#--------> # Revenue and Admission analysis

select * from total_admission;
select * from total_revenue;
select * from average_bill;

create view Refund_amount as
select abs(round(sum(bill_amount_cleaned),2))  as refund from admission where bill_status in ("Refunds");
select * from Refund_amount;

    # revenue by month
create or replace view monthly_revenue as
select monthname(str_to_date(Adm_date, '%d-%m-%y')) as admission_month , round(sum(bill_amount_cleaned),2)  as total_rev , patient_id  from admission where str_to_date(Adm_date, '%d-%m-%y') is not null group by admission_month, patient_id, MONTH(STR_TO_DATE(Adm_date, '%d-%m-%y')) order by MONTH(STR_TO_DATE(Adm_date, '%d-%m-%y')) ASC ;
select * from monthly_revenue;

    #bill_status : count bills based on status like valid , refunds ..
create or replace view bill_status as 
select bill_status , count(*) as total_bills ,patient_id from admission group by bill_status , patient_id order by total_bills DESC;
select * from bill_status;

     # bill_amount distribution : it counts number of bill in a particular bill range
create or replace view bill_amount_distribution as
select     CASE
        WHEN CAST(bill_amount_cleaned AS DECIMAL(12,2)) <= 5000 THEN '0 - 5,000'
        WHEN CAST(bill_amount_cleaned AS DECIMAL(12,2)) <= 10000 THEN '5,001 - 10,000'
        WHEN CAST(bill_amount_cleaned AS DECIMAL(12,2)) <= 20000 THEN '10,001 - 20,000'
        WHEN CAST(bill_amount_cleaned AS DECIMAL(12,2)) <= 50000 THEN '20,001 - 50,000'
        ELSE 'Above 50,000'
    END AS bill_range, count(*) as total_admission ,patient_id from admission where bill_status="valid" AND bill_amount_cleaned IS NOT NULL group by bill_range , patient_id;
select * from bill_amount_distribution;  

select * from revenue_by_depart;
 select * from patient;
 select * from admission;
  
    # KPI : missing_bill count
 create view missing_bill as
 select count(*) bill_status from admission where bill_status = "Missing";
 select * from missing_bill ;
     
       # kpi : refund rate
 create view refund_rate as
 SELECT ROUND( ABS(SUM( CASE
                WHEN bill_status IN ('Refund', 'Refunds')
                THEN CAST(bill_amount_cleaned AS DECIMAL(12,2))
                ELSE 0 END )) /
        NULLIF(SUM(CASE
                WHEN bill_status = 'Valid'
                THEN CAST(bill_amount_cleaned AS DECIMAL(12,2))
                ELSE 0 END ), 0) * 100,2) AS refund_rate FROM admission ;
select * from refund_rate ;                

     # compare gross revenue against net revenue
create or replace view gross_net as
SELECT DATE_FORMAT(STR_TO_DATE(Adm_date, '%d-%m-%Y'),'%M') AS admission_month, MONTH(STR_TO_DATE(Adm_date, '%d-%m-%y')) AS admission_month_number,
    ROUND(SUM(CASE WHEN bill_status = 'Valid' THEN CAST(bill_amount_cleaned AS DECIMAL(12,2))
                ELSE 0 END), 2) AS gross_revenue,
    ROUND(SUM(CASE WHEN bill_status IN ('Valid', 'Refunds') THEN CAST(bill_amount_cleaned AS DECIMAL(12,2))
                ELSE 0 END), 2 ) AS net_revenue , patient_id
	FROM admission
    WHERE STR_TO_DATE(Adm_date, '%d-%m-%Y') IS NOT NULL
    GROUP BY MONTH(STR_TO_DATE(Adm_date, '%d-%m-%Y')), admission_month_number,
    DATE_FORMAT(STR_TO_DATE(Adm_date, '%d-%m-%Y'), '%M') , patient_id  ORDER BY MONTH(STR_TO_DATE(Adm_date, '%d-%m-%Y')) ;
    select * from gross_net ;
     
      # monthly refund rate
create or replace view monthly_refund_trend as
select monthname(str_to_date(Adm_date, '%d-%m-%y')) as admission_month ,MONTH(STR_TO_DATE(Adm_date, '%d-%m-%y')) AS admission_month_number,  abs(round(sum(bill_amount_cleaned),2))  as total_refund , patient_id from admission 
where bill_status in ("Refunds") AND str_to_date(Adm_date, '%d-%m-%y') is not null 
group by admission_month, patient_id,admission_month_number, MONTH(STR_TO_DATE(Adm_date, '%d-%m-%y')) order by MONTH(STR_TO_DATE(Adm_date, '%d-%m-%y')) ASC ;
select * from monthly_refund_trend ;