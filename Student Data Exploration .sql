-- Data retrieved from https://www.kaggle.com/datasets/uciml/student-alcohol-consumption/data
-- Visualizations link https://public.tableau.com/app/profile/lok.to.yan/vizzes
-- Codes and findings below:

USE Project;


ALTER TABLE `mytable` RENAME student_mat; -- Rename table for convenience

SELECT * FROM student_mat;

-- Insert primary key on the dataset for identifying students
ALTER TABLE student_mat
ADD COLUMN student_id INT AUTO_INCREMENT PRIMARY KEY;

-- 1. Family relationship 

-- Find out if parents separate, who would take care of their children
SELECT famrel, Pstatus, student_id, guardian FROM student_mat
WHERE Pstatus='A' 
and famsize='LE3'; -- only selecting family with three or fewer than three members
-- Mainly mothers (18 out of 20 cases) take care of their children

-- Compare average level of family relationship under different conditions
SELECT 
(SELECT Avg(famrel) FROM student_mat WHERE Pstatus='A') avg_cohabitation,
(SELECT Avg(famrel) FROM student_mat WHERE goout=5) avg_goout,
(SELECT Avg(famrel) FROM student_mat WHERE romantic='Yes') avg_romantic,
(SELECT Avg(famrel) FROM student_mat WHERE internet='Yes') avg_internet,
(SELECT Avg(famrel) FROM student_mat) total_avg
FROM student_mat
LIMIT 1;
-- Average level of family relationship is lower if parents separate or students have romantic relationships 
-- Effect of having internet access on family relationships is insignificant

-- Show proportions of stay-at-home father and mother as students' guardian
With father_at_home AS(
SELECT guardian, COUNT(guardian), CAST(COUNT(guardian)AS FLOAT)/(SELECT COUNT(guardian) FROM student_mat WHERE Mjob='at_home') AS Proportion FROM student_mat
WHERE Mjob='at_home'
GROUP BY guardian), 

mother_at_home AS(
SELECT guardian, COUNT(guardian), CAST(COUNT(guardian)AS FLOAT)/(SELECT COUNT(guardian) FROM student_mat WHERE Fjob='at_home') AS Proportion FROM student_mat
WHERE Fjob='at_home'
GROUP BY guardian)

SELECT * FROM father_at_home f
JOIN mother_at_home m ON f.guardian=m.guardian;
-- Only 17% stay-at-home father are gurardian but 65% of stay-at-home mother are guardian


-- 2. School location and student's travel time

-- Find out any students choose the school because it is close to home at first,
-- but eventually need to travel for a long time
SELECT * FROM student_mat
WHERE traveltime=4 and reason='home';
-- Two students 

-- Compare travel time between students living in urban and rural areas
SELECT DISTINCT address, traveltime, 
COUNT(address) OVER (PARTITION BY address,traveltime) number_of_student,
COUNT(address) OVER (PARTITION BY address,traveltime)/COUNT(address) OVER (PARTITION BY address)*100 percentage FROM student_mat
ORDER BY traveltime DESC;

SELECT DISTINCT address, Avg (traveltime) OVER(PARTITION BY address) avg_traveltime, 
COUNT(traveltime) OVER(PARTITION BY address)/(SELECT COUNT(*)FROM student_mat) proportion
FROM student_mat;
-- Average travel time of students living in urban is lower
-- Proportion of students living in urban is ~0.78


-- 3. Academic performance

-- Summarize support to students
SELECT schoolsup,famsup, paid, COUNT(*) total_number, 
COUNT(*)/(SELECT COUNT(*) FROM student_mat)*100 Percentage 
FROM student_mat
GROUP BY schoolsup, famsup, paid
ORDER BY total_number DESC;
-- More than 85% of students do not get educational support from school

-- Compare students' study time having support (from family and/or extra school) or not having support 
WITH bothsupport (studytime, Percentage_bothsupport) AS(
SELECT studytime, COUNT(*) FROM student_mat
WHERE famsup='Yes' and paid='Yes'
GROUP BY studytime), 

no_support (studytime, Percentage_nosupport) AS(
SELECT studytime, COUNT(*)/(SELECT COUNT(*) FROM student_mat WHERE famsup='No' and paid='No') FROM student_mat
WHERE famsup='No' and paid='No'
GROUP BY studytime), 

famsupport (studytime,Percentage_famsupport) AS(SELECT studytime, COUNT(*)/(SELECT COUNT(*) FROM student_mat WHERE famsup='Yes' and paid='No') FROM student_mat
WHERE famsup='Yes' and paid='No'
GROUP BY studytime), 

classsupport (studytime,Percentage_classsupport) AS (SELECT studytime, COUNT(*)/(SELECT COUNT(*) FROM student_mat WHERE famsup='No' and paid='Yes') Percentage FROM student_mat
WHERE famsup='No' and paid='Yes'
GROUP BY studytime),

total (studytime,percentage_total) AS(SELECT student_mat.studytime, COUNT(*)/(SELECT COUNT(*) FROM student_mat) Percentage FROM student_mat
GROUP BY studytime)

SELECT total.studytime, Percentage_bothsupport, Percentage_nosupport, Percentage_famsupport, Percentage_classsupport, percentage_total FROM bothsupport
JOIN no_support ON bothsupport.studytime=no_support.studytime
JOIN famsupport ON bothsupport.studytime=famsupport.studytime
JOIN classsupport ON bothsupport.studytime=classsupport.studytime
JOIN total ON bothsupport.studytime=total.studytime
ORDER BY total.studytime;

-- Find out the relationship between study time and academic performance 
SELECT school, ROUND((G1+G2+G3)/3,0) rounded_point, ROUND(AVG(studytime),1) avg_studytime FROM student_mat
GROUP BY school, rounded_point;

-- Summarize students' academic performance
SELECT ROUND((G1+G2+G3)/3,0) avg_point, count(*), 
GROUP_CONCAT(DISTINCT student_id ORDER BY student_id separator ',')  -- Showing student_id for further enquiry
FROM student_mat
GROUP BY avg_point
ORDER BY avg_point DESC;
-- Using more criteria 
SELECT ROUND((G1+G2+G3)/3,0) avg_point, studytime, famsup, paid, 
GROUP_CONCAT(DISTINCT student_id ORDER BY student_id separator ',') 
FROM student_mat
GROUP BY avg_point, studytime, famsup, paid
ORDER BY avg_point DESC, studytime; 

-- Sort outstanding students
SELECT student_id, Dalc, Walc FROM student_mat
WHERE ROUND((G1+G2+G3)/3,0)=19 AND studytime=1 AND schoolsup='No' AND famsup='No' AND paid='No';
-- Their alcohol consumption level is very low

-- Sort outstanding students using student ID
SELECT student_id, Dalc, Walc FROM student_mat
WHERE student_id IN (30,39);

-- Alcohol consumption level of bottom students
WITH bottom_30 AS
(SELECT * FROM student_mat
ORDER BY (G1+G2+G3)/3
LIMIT 30) -- Selecting the bottom 30
SELECT student_id, Dalc, Walc FROM bottom_30
WHERE Dalc>=4 OR Walc>=4; -- 4-5 belongs to high clcohol consumption level
-- 5 students from the bottom 30 consume alcohol frequently on weekends but not on weekdays
-- Effect of weekend consumption on academic performance may be higher than weekday consumption

SELECT * FROM student_por;

ALTER TABLE student_por
ADD COLUMN student_id INT AUTO_INCREMENT PRIMARY KEY;

-- Combine dataset
SELECT * FROM student_mat 
JOIN student_por USING (school, sex, age, address, famsize, Pstatus, Medu, Fedu, Mjob, Fjob, reason, nursery ,internet); -- related column mentioned by owner of the dataset

-- Count number of student attending both course
SELECT COUNT(m.student_id) FROM student_mat m
JOIN student_por p USING (school, sex, age, address, famsize, Pstatus, Medu, Fedu, Mjob, Fjob, reason, nursery ,internet);

-- Count number of student only attending math course
SELECT COUNT(student_id) no_of_student FROM student_mat 
WHERE student_id NOT IN (SELECT m.student_id FROM student_mat m
JOIN student_por p USING (school, sex, age, address, famsize, Pstatus, Medu, Fedu, Mjob, Fjob, reason, nursery ,internet));

-- Count number of student only attending portuguese course
SELECT COUNT(student_id) FROM student_por
WHERE student_id NOT IN (SELECT p.student_id FROM student_mat m
JOIN student_por p USING (school, sex, age, address, famsize, Pstatus, Medu, Fedu, Mjob, Fjob, reason, nursery ,internet));
-- 25 students only attend maths course, 275 students only attend portuguese course, 382 students attend both
-- Total number of students in combined dataset is (25+275+382)=682

-- Comparing average absences of different classes on different alcohol consumption level
SELECT m.DALC, -- Using weekday alcohol consumption level
AVG(m.absences) average_absence_mat, AVG(p.absences) average_absence_por FROM student_mat m
JOIN student_por p USING (school, sex, age, address, famsize, Pstatus, Medu, Fedu, Mjob, Fjob, reason, nursery ,internet)
GROUP BY DALC
ORDER BY DALC DESC;

SELECT m.WALC, -- Using weekend alcohol consumption level
AVG(m.absences) average_absence_mat, AVG(p.absences) average_absence_por FROM student_mat m
JOIN student_por p USING (school, sex, age, address, famsize, Pstatus, Medu, Fedu, Mjob, Fjob, reason, nursery ,internet)
GROUP BY WALC
ORDER BY WALC DESC;
-- Absences in math courses are more severe than portuguese courses
-- Absences for students with high alcohol consumption levels in both courses are more severe
