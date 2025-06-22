drop database cm3;
create database cm3;
use cm3;

-- ███████████████████████████████████████████████████████████████████████████
-- 1) DROP & RECREATE ALL TABLES
-- ███████████████████████████████████████████████████████████████████████████
SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS Prescription_Content, Prescription, Contract, Sells, Drug, Pharmacy, Pharma_Company, Patient, Doctor;
SET FOREIGN_KEY_CHECKS = 1;

CREATE TABLE Doctor (
  aadhar_id       VARCHAR(12) PRIMARY KEY,
  name            VARCHAR(100) NOT NULL,
  speciality      VARCHAR(100),
  experience      INT
) ENGINE=InnoDB;

CREATE TABLE Patient (
  aadhar_id            VARCHAR(12) PRIMARY KEY,
  name                 VARCHAR(100) NOT NULL,
  address              VARCHAR(255),
  age                  INT,
  primary_physician_id VARCHAR(12) NOT NULL,
  FOREIGN KEY (primary_physician_id)
    REFERENCES Doctor(aadhar_id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE Pharma_Company (
  name   VARCHAR(100) PRIMARY KEY,
  phone  VARCHAR(10)
) ENGINE=InnoDB;

CREATE TABLE Drug (
  trade_name   VARCHAR(100),
  ph_comp_name VARCHAR(100),
  formula      TEXT,
  PRIMARY KEY (trade_name, ph_comp_name),
  FOREIGN KEY (ph_comp_name)
    REFERENCES Pharma_Company(name)
    ON UPDATE CASCADE
    ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE Pharmacy (
  name    VARCHAR(100) PRIMARY KEY,
  address VARCHAR(255),
  phone   VARCHAR(20)
) ENGINE=InnoDB;

CREATE TABLE Sells (
  trade_name   VARCHAR(100),
  ph_comp_name VARCHAR(100),
  ph_name      VARCHAR(100),
  price        DECIMAL(10,2) check (price > 0),
  quantity 	 INT CHECK (quantity >= 0),
  PRIMARY KEY (trade_name, ph_comp_name, ph_name),
  FOREIGN KEY (trade_name, ph_comp_name)
    REFERENCES Drug(trade_name, ph_comp_name)
    ON UPDATE CASCADE
    ON DELETE cascade,
  FOREIGN KEY (ph_name)
    REFERENCES Pharmacy(name)
    ON UPDATE CASCADE
    ON DELETE cascade
) ENGINE=InnoDB;
create table cures(
	p_adhar varchar(12),
    D_Adhar varchar(12),
    PRIMARY KEY (p_adhar,D_Adhar),
    FOREIGN KEY (p_adhar) REFERENCES patient (aadhar_id) on update CASCADE ON DELETE cascade,
    FOREIGN KEY (D_Adhar) REFERENCES Doctor (aadhar_id) on update CASCADE ON DELETE cascade
)ENGINE=InnoDB;
CREATE TABLE Contract (
  ph_name      VARCHAR(100),
  ph_comp_name VARCHAR(100),
  start_date   DATE,
  end_date     DATE,
  content      TEXT,
  supervisor   VARCHAR(100),
  PRIMARY KEY (ph_name, ph_comp_name, start_date,end_date),
  FOREIGN KEY (ph_name)
    REFERENCES Pharmacy(name)
    ON DELETE CASCADE,
  FOREIGN KEY (ph_comp_name)
    REFERENCES Pharma_Company(name)
    ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE Prescription (
  doc_id      VARCHAR(12),
  patient_id  VARCHAR(12),
  date        DATE,
  primary key (doc_id,patient_id),
  FOREIGN KEY (doc_id)      REFERENCES Doctor(aadhar_id)   ON UPDATE CASCADE ON DELETE RESTRICT,
  FOREIGN KEY (patient_id)  REFERENCES Patient(aadhar_id)  ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE Prescription_Content (
	doc_id      VARCHAR(12),
  patient_id  VARCHAR(12),
  trade_name      VARCHAR(100),
  ph_comp_name    VARCHAR(100),
  quantity        INT,
  PRIMARY KEY (doc_id,patient_id, trade_name, ph_comp_name),
  FOREIGN KEY (doc_id,patient_id)
    REFERENCES Prescription(doc_id,patient_id)
    ON DELETE CASCADE,
  FOREIGN KEY (trade_name, ph_comp_name)
    REFERENCES Drug(trade_name, ph_comp_name)
    ON DELETE RESTRICT
) ENGINE=InnoDB;

-- ███████████████████████████████████████████████████████████████████████████
-- 2) CRUD STORED PROCEDURES for each entity
-- ███████████████████████████████████████████████████████████████████████████
DELIMITER //

-- Doctors
CREATE PROCEDURE add_doctor(
  IN p_id VARCHAR(12), IN p_name VARCHAR(100),
  IN p_speciality VARCHAR(100), IN p_experience INT,
  IN PAT_ID VARCHAR(12))
BEGIN
  INSERT INTO Doctor VALUES(p_id,p_name,p_speciality,p_experience);
  INSERT INTO cures VALUES(PAT_ID,p_id);
END;//
DELIMITER //
create procedure adddoctorpatient(
	in patientid varchar(12), in doctorid varchar(12))
begin
	insert into cures values (patientid,doctorid);
end;//
CREATE PROCEDURE update_doctor(
  IN p_id VARCHAR(12), IN p_name VARCHAR(100),
   IN p_experience INT)
BEGIN
  UPDATE Doctor
    SET name=p_name, experience=p_experience
    WHERE aadhar_id=p_id;
END;//

DELIMITER //

CREATE PROCEDURE delete_doctor(IN d_aadhar VARCHAR(12))
BEGIN
  DECLARE doc_specialty VARCHAR(100);
  DECLARE patient_count INT;

  -- Get specialty
  SELECT speciality INTO doc_specialty
  FROM doctor
  WHERE aadhar_id = d_aadhar;

  -- If doctor not found
  IF doc_specialty IS NULL THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Error: Doctor not found.';
  END IF;

  -- If doctor is a physician, check if they have patients
  IF LOWER(doc_specialty) = 'physician' THEN
    SELECT COUNT(*) INTO patient_count
    FROM patient
    WHERE primary_physician_id = d_aadhar;

    IF patient_count > 1 THEN
      SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Cannot delete physician with assigned patients.';
    END IF;
  END IF;

  -- Delete from cures
  DELETE FROM cures WHERE D_Adhar = d_aadhar;

  -- Delete from doctor
  DELETE FROM doctor WHERE aadhar_id = d_aadhar;
END;
//



-- Patients
CREATE PROCEDURE add_patient(
  IN p_id VARCHAR(12), IN p_name VARCHAR(100),
  IN p_address VARCHAR(255), IN p_age INT,
  IN p_primary_phys VARCHAR(12))
BEGIN
  INSERT INTO Patient
    (aadhar_id,name,address,age,primary_physician_id)
    VALUES(p_id,p_name,p_address,p_age,p_primary_phys);
	insert into cures values (p_id,p_primary_phys);
END;//
CREATE PROCEDURE add_patientwithdoctor(
  IN p_aadhar VARCHAR(12),
  IN p_name    VARCHAR(100),
  IN p_address VARCHAR(200),
  IN p_age     INT,
  IN p_paadhardoctor VARCHAR(12),
  IN p_name_doctor    VARCHAR(100),
  IN p_exp     INT
)
BEGIN
insert into doctor values (p_paadhardoctor,p_name_doctor,"PHYSICIAN",p_exp);
  INSERT INTO patient VALUES(p_aadhar,p_name,p_address,p_age,p_paadhardoctor);
    
    insert into cures values(p_aadhar,p_paadhardoctor);
END;//
DELIMITER //



CREATE PROCEDURE update_patient(
  IN p_id VARCHAR(12),
  IN p_name VARCHAR(100),
  IN p_address VARCHAR(255),
  IN p_age INT,
  IN p_primary_phys VARCHAR(12)
)
BEGIN
  DECLARE doc_specialty VARCHAR(100);

  -- Get the specialty of the doctor (if they exist)
  SELECT speciality INTO doc_specialty
  FROM doctor
  WHERE aadhar_id = p_primary_phys;

  -- If no doctor found, signal error
  IF doc_specialty IS NULL THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Error: Doctor does not exist.';
  ELSEIF LOWER(doc_specialty) != 'physician' THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Error: Primary doctor must be a physician.';
  ELSE
    -- Proceed with update
    UPDATE patient
      SET name = p_name,
          address = p_address,
          age = p_age,
          primary_physician_id = p_primary_phys
      WHERE aadhar_id = p_id;
  END IF;
END;
//


DELIMITER //

CREATE PROCEDURE delete_patient(IN p_aadhar VARCHAR(12))
BEGIN

  DECLARE done INT DEFAULT 0;
  DECLARE d_id VARCHAR(12);
  DECLARE doc_patient_count INT;

  -- Cursor to loop over doctors linked to the patient
  DECLARE doc_cursor CURSOR FOR
    SELECT D_Adhar FROM cures WHERE p_adhar = p_aadhar;

  DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

  OPEN doc_cursor;
 
  read_loop: LOOP
    FETCH doc_cursor INTO d_id;
    IF done THEN
      LEAVE read_loop;
    END IF;

    -- Count how many patients this doctor has
    SELECT COUNT(*) INTO doc_patient_count
    FROM cures
    WHERE D_Adhar = d_id;

    -- If doctor has only this patient, delete the doctor
    IF doc_patient_count = 1 THEN
      DELETE FROM doctor WHERE aadhar_id = d_id;
    END IF;
  END LOOP;

  CLOSE doc_cursor;

  -- Delete from cures
 DELETE FROM cures WHERE p_adhar = p_aadhar;

  -- Delete patient
  DELETE FROM patient WHERE aadhar_id = p_aadhar;
END;
//


DELIMITER //

-- Pharma Companies
CREATE PROCEDURE add_pharma_company(
  IN p_name VARCHAR(100), IN p_phone VARCHAR(20))
BEGIN
  INSERT INTO Pharma_Company VALUES(p_name,p_phone);
END;//
DELIMITER //

CREATE PROCEDURE update_pharma_company(
  IN p_name VARCHAR(100), IN p_phone VARCHAR(20))
BEGIN
  UPDATE Pharma_Company
    SET phone=p_phone
    WHERE name=p_name;
END;//
DELIMITER //

CREATE PROCEDURE delete_pharma_company(IN p_name VARCHAR(100))
BEGIN
    delete from sells where ph_comp_name=p_name;
    delete from drug where ph_comp_name = p_name; 
  DELETE FROM Pharma_Company WHERE name=p_name;
END;//
DELIMITER //

-- Drugs
CREATE PROCEDURE add_drug(
  IN p_trade VARCHAR(100), 
  IN p_comp VARCHAR(100), 
  IN p_formula TEXT
)
BEGIN
INSERT INTO Drug (trade_name, ph_comp_name, formula)
  VALUES (p_trade, p_comp, p_formula);
END //
DELIMITER //

CREATE PROCEDURE update_drug(
  IN p_trade VARCHAR(100), IN p_comp VARCHAR(100), IN p_formula TEXT)
BEGIN
  UPDATE Drug
    SET formula=p_formula
    WHERE trade_name=p_trade AND ph_comp_name=p_comp;
END;//
DELIMITER //

CREATE PROCEDURE delete_drug(
  IN p_trade VARCHAR(100), IN p_comp VARCHAR(100))
BEGIN
  DELETE FROM Drug
    WHERE trade_name=p_trade AND ph_comp_name=p_comp;
END;//
DELIMITER //

-- Pharmacies
CREATE PROCEDURE add_pharmacy(
  IN p_name VARCHAR(100), IN p_address VARCHAR(255), IN p_phone VARCHAR(20))
BEGIN
  INSERT INTO Pharmacy VALUES(p_name,p_address,p_phone);
END;//
DELIMITER //

CREATE PROCEDURE update_pharmacy(
  IN p_name VARCHAR(100), IN p_address VARCHAR(255), IN p_phone VARCHAR(20))
BEGIN
  UPDATE Pharmacy
    SET address=p_address, phone=p_phone
    WHERE name=p_name;
END;//
DELIMITER //

CREATE PROCEDURE delete_pharmacy(IN p_name VARCHAR(100))
BEGIN
	delete from sells where ph_name = p_name;
  DELETE FROM Pharmacy WHERE name=p_name;
END;//
DELIMITER //

-- Contracts
CREATE PROCEDURE add_contract(
  IN p_ph_name VARCHAR(100),
  IN p_comp VARCHAR(100), IN p_start DATE, IN p_end DATE,
  IN p_content TEXT, IN p_supervisor VARCHAR(100))
BEGIN
  INSERT INTO Contract
    VALUES(p_ph_name,p_comp,p_start,p_end,p_content,p_supervisor);
END;//
DELIMITER //

CREATE PROCEDURE update_contract(
  IN p_ph_name VARCHAR(100), IN p_comp VARCHAR(100),
  IN p_start DATE, IN p_end DATE, IN p_supervisor VARCHAR(100))
BEGIN
  UPDATE Contract
    SET  supervisor=p_supervisor
    WHERE ph_name=p_ph_name
      AND ph_comp_name=p_comp
      AND start_date=p_start
      and end_date = p_end;
END;//
DELIMITER //

CREATE PROCEDURE delete_contract(
  IN p_ph_name VARCHAR(100), IN p_comp VARCHAR(100), IN p_start DATE,IN p_end DATE)
BEGIN
  DELETE FROM Contract
    WHERE ph_name=p_ph_name
      AND ph_comp_name=p_comp
      AND start_date=p_start
      AND end_date = p_end;
END;//
DELIMITER //

-- Prescriptions (header + contents)
CREATE PROCEDURE add_prescription(
  IN p_doc VARCHAR(12),
  IN p_patient VARCHAR(12),
  IN p_date DATE
)
BEGIN
  DECLARE old_date DATE;

  -- Ensure the doctor-patient pair exists in the cures table
  IF EXISTS (
    SELECT 1 FROM cures
    WHERE D_Adhar = p_doc AND p_adhar = p_patient
  ) THEN

    -- Fetch the previous prescription date (if any)
    SELECT date INTO old_date
    FROM Prescription
    WHERE doc_id = p_doc AND patient_id = p_patient;

    -- Insert/update only if no entry or new date is more recent
    IF old_date IS NULL OR p_date > old_date THEN
      DELETE FROM prescription_content
      WHERE doc_id = p_doc AND patient_id = p_patient;

      DELETE FROM Prescription
      WHERE doc_id = p_doc AND patient_id = p_patient;

      INSERT INTO Prescription(doc_id, patient_id, date)
      VALUES(p_doc, p_patient, p_date);
    END IF;

  ELSE
    -- Raise error if not found in cures
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Error: Doctor-Patient pair not found in cures table.';
  END IF;
END //
DELIMITER //

CREATE PROCEDURE add_prescription_content(
  IN p_doc VARCHAR(12), IN p_patient VARCHAR(12),
  IN p_trade VARCHAR(100), IN p_comp VARCHAR(100), IN p_quantity INT)
BEGIN
  INSERT INTO Prescription_Content VALUES(p_doc,p_patient,p_trade,p_comp,p_quantity) ;
END;//

DELIMITER //

CREATE PROCEDURE delete_prescription(
  IN p_doc VARCHAR(12), IN p_patient VARCHAR(12))
BEGIN
    delete from prescription_content where doc_id = p_doc and patient_id=p_patient;
  DELETE FROM Prescription
    WHERE doc_id=p_doc
      AND patient_id=p_patient;
END;//
DELIMITER //

CREATE PROCEDURE update_prescription_date(
  IN p_doc VARCHAR(12), IN p_patient VARCHAR(12),
  IN p_old_date DATE, IN p_new_date DATE)
BEGIN
  UPDATE Prescription
    SET date=p_new_date
    WHERE doc_id=p_doc
      AND patient_id=p_patient
      AND date=p_old_date;
END;//

-- ███████████████████████████████████████████████████████████████████████████
-- 4) THE 7 REPORTING PROCEDURES
-- ███████████████████████████████████████████████████████████████████████████
DELIMITER //

-- 2. Prescriptions of a patient in a given period
CREATE PROCEDURE report_patient_prescriptions(
  IN p_patient VARCHAR(12), IN p_start DATE, IN p_end DATE)
BEGIN
  SELECT 
    p.date,
    d.name             AS doctor_name,
    pc.trade_name,
    pc.ph_comp_name,
    pc.quantity
  FROM Prescription p
  JOIN Doctor d
    ON p.doc_id      = d.aadhar_id
  JOIN Prescription_Content pc
    ON p.id          = pc.prescription_id
  WHERE p.patient_id = p_patient
    AND p.date       BETWEEN p_start AND p_end
  ORDER BY p.date;
END;//
DELIMITER //

-- 3. Details of a prescription for a given patient & date
CREATE PROCEDURE get_prescription_details(
  IN p_patient VARCHAR(12), IN p_date DATE)
BEGIN
  SELECT
    d.name             AS doctor_name,
    dr.trade_name,
    dr.formula,
    pc.quantity
  FROM Prescription p
  JOIN Doctor d
    ON p.doc_id = d.aadhar_id
  JOIN Prescription_Content pc
    ON p.id     = pc.prescription_id
  JOIN Drug dr
    ON pc.trade_name   = dr.trade_name
   AND pc.ph_comp_name = dr.ph_comp_name
  WHERE p.patient_id = p_patient
    AND p.date       = p_date;
END;//
DELIMITER //

-- 4. Drugs produced by a pharmaceutical company
CREATE PROCEDURE get_drugs_by_company(IN p_comp VARCHAR(100))
BEGIN
  SELECT trade_name, formula
    FROM Drug
   WHERE ph_comp_name = p_comp;
END;//
DELIMITER //

-- 5. Stock position of a pharmacy
CREATE PROCEDURE get_pharmacy_stock(IN p_pharmacy VARCHAR(100))
BEGIN
  SELECT
    s.trade_name,
    s.ph_comp_name,
    d.formula,
    s.price
  FROM Sells s
  JOIN Drug d
    ON s.trade_name   = d.trade_name
   AND s.ph_comp_name = d.ph_comp_name
  WHERE s.ph_name = p_pharmacy;
END;//
DELIMITER //

-- 6. Contact details of a pharmacy ↔ pharma company
CREATE PROCEDURE get_pharmacy_company_contact(
  IN p_pharmacy VARCHAR(100), IN p_comp VARCHAR(100))
BEGIN
  SELECT
    ph.name  AS pharmacy_name,
    ph.address AS pharmacy_address,
    ph.phone AS pharmacy_phone,
    pc.name  AS company_name,
    pc.phone AS company_phone
  FROM Pharmacy ph
  JOIN Pharma_Company pc
    ON pc.name = p_comp
 WHERE ph.name = p_pharmacy;
END;//
DELIMITER //

-- 7. List of patients for a given doctor
CREATE PROCEDURE get_doctor_patients(IN p_doc VARCHAR(12))
BEGIN
  SELECT
    p.aadhar_id,
    p.name,
    p.address,
    p.age
  FROM Patient p
  WHERE p.primary_physician_id = p_doc;
END;//
DELIMITER //

CREATE PROCEDURE report_patient_prescriptions_period(
  IN in_patient_id VARCHAR(12),
  IN in_start_date DATE,
  IN in_end_date   DATE
)
BEGIN
  SELECT
    p.date            AS prescription_date,
    d.name            AS doctor_name,
    pc.trade_name,
    pc.ph_comp_name,
    pc.quantity
  FROM Prescription p
  JOIN Prescription_Content pc
    ON p.doc_id      = pc.doc_id
   AND p.patient_id  = pc.patient_id
  JOIN Doctor d
    ON p.doc_id      = d.aadhar_id
  WHERE p.patient_id = in_patient_id
    AND p.date       BETWEEN in_start_date AND in_end_date
  ORDER BY p.date;
END;
//

CREATE PROCEDURE print_prescription_details_by_date(
  IN in_patient_id VARCHAR(12),
  IN in_presc_date DATE
)
BEGIN
  SELECT
    p.date            AS prescription_date,
    d.name            AS doctor_name,
    pc.trade_name,
    pc.ph_comp_name,
    dr.formula,
    pc.quantity
  FROM Prescription p
  JOIN Prescription_Content pc
    ON p.doc_id      = pc.doc_id
   AND p.patient_id  = pc.patient_id
  JOIN Doctor d
    ON p.doc_id      = d.aadhar_id
  JOIN Drug dr
    ON pc.trade_name   = dr.trade_name
   AND pc.ph_comp_name = dr.ph_comp_name
  WHERE p.patient_id = in_patient_id
    AND p.date       = in_presc_date;
END;
//

CREATE PROCEDURE list_drugs_by_company(
  IN in_company VARCHAR(100)
)
BEGIN
  SELECT
    trade_name,
    formula
  FROM Drug
  WHERE ph_comp_name = in_company;
END;
//

CREATE PROCEDURE print_pharmacy_stock_position(
  IN in_pharmacy_name VARCHAR(100)
)
BEGIN
  SELECT
    s.trade_name,
    s.ph_comp_name,
    d.formula,
    s.price,
    s.quantity
  FROM Sells s
  JOIN Drug d
    ON s.trade_name   = d.trade_name
   AND s.ph_comp_name = d.ph_comp_name
  WHERE s.ph_name = in_pharmacy_name;
END;
//

CREATE PROCEDURE print_pharmacy_company_contact(
  IN in_pharmacy VARCHAR(100),
  IN in_company  VARCHAR(100)
)
BEGIN
  SELECT
    ph.name    AS pharmacy_name,
    ph.address AS pharmacy_address,
    ph.phone   AS pharmacy_phone,
    pc.name    AS company_name,
    pc.phone   AS company_phone
  FROM Pharmacy ph
  JOIN Pharma_Company pc
    ON pc.name = in_company
  WHERE ph.name = in_pharmacy;
END;
//

DELIMITER //

CREATE PROCEDURE print_patients_of_doctor(
  IN in_doctor_id VARCHAR(12)
)
BEGIN
  SELECT
    p.aadhar_id,
    p.name,
    p.address,
    p.age
  FROM cures c
  JOIN patient p ON c.p_adhar = p.aadhar_id
  WHERE c.D_adhar = in_doctor_id;
END //



DELIMITER //


CREATE PROCEDURE update_stocks(
    IN p_trade     VARCHAR(100),
    IN p_comp      VARCHAR(100),
    IN p_pharmacy  VARCHAR(100),
    IN p_price     DECIMAL(10,2),
    IN p_quantity  INT
)
BEGIN
    /* add new line or tweak price / quantity */
    INSERT INTO Sells (trade_name, ph_comp_name, ph_name, price, quantity)
    VALUES (p_trade, p_comp, p_pharmacy, p_price, p_quantity)
    ON DUPLICATE KEY UPDATE
        price    = VALUES(price),
        quantity = VALUES(quantity);
END;
//
DROP TRIGGER IF EXISTS trg_sells_min10_before_delete;
DELIMITER //

CREATE TRIGGER trg_sells_min10_before_delete
BEFORE DELETE ON Sells
FOR EACH ROW
BEGIN
    DECLARE drug_cnt INT;

    /* rows that still exist before this DELETE fires */
    SELECT COUNT(*) INTO drug_cnt
    FROM Sells
    WHERE ph_name = OLD.ph_name;

    /* if only 10 remain, deleting one would leave 9 → block it */
    IF drug_cnt <= 10 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: A pharmacy must stock at least 10 different drugs.';
    END IF;
END;
//

DELIMITER //

CREATE PROCEDURE print_contract(
  IN pharmaname VARCHAR(100),
  IN pharmacompany VARCHAR(100)
)
BEGIN
  SELECT * 
  FROM Contract
  WHERE ph_name = pharmaname AND ph_comp_name = pharmacompany;
END //
-- 1) Create two patients (and their physicians) in one go


-- DUMMY DATA

-- ███  SECTION A  –  LOAD A CLEAN, VALID DATA‑SET  ██████████████████████████
CALL add_patientwithdoctor('P100','Alice','123 Main St',30,
                            'D100','Dr. Alice',12);
CALL add_patientwithdoctor('P200','Bob'  ,'456 Oak Av',45,
                            'D200','Dr. Bob' ,15);

-- Doctor D300 will link to both patients (rule: every doctor must have ≥1 pt)
CALL add_doctor('D300','Dr. Fox','Cardio',8,'P100');
CALL adddoctorpatient('P200','D300');

CALL add_pharma_company('PharmA','1112223333');
CALL add_pharma_company('PharmB','4445556666');

-- 14 drugs  =  enough to seed two pharmacies with ≥10 each
CALL add_drug('D01','PharmA','F1'); CALL add_drug('D02','PharmA','F2');
CALL add_drug('D03','PharmA','F3'); CALL add_drug('D04','PharmA','F4');
CALL add_drug('D05','PharmA','F5'); CALL add_drug('D06','PharmA','F6');
CALL add_drug('D07','PharmA','F7'); CALL add_drug('D08','PharmA','F8');
CALL add_drug('D09','PharmA','F9'); CALL add_drug('D10','PharmA','F10');
CALL add_drug('D11','PharmB','F11'); CALL add_drug('D12','PharmB','F12');
CALL add_drug('D13','PharmB','F13'); CALL add_drug('D14','PharmB','F14');

CALL add_pharmacy('PhX','789 Elm St','9998887777');
CALL add_pharmacy('PhY','321 Pine St','6665554444');

-- load 10 items into each pharmacy (min‑10 rule)
START TRANSACTION;
  CALL update_stocks('D01','PharmA','PhX',1.0,50);  CALL update_stocks('D02','PharmA','PhX',1.0,50);
  CALL update_stocks('D03','PharmA','PhX',1.0,50);  CALL update_stocks('D04','PharmA','PhX',1.0,50);
  CALL update_stocks('D05','PharmA','PhX',1.0,50);  CALL update_stocks('D06','PharmA','PhX',1.0,50);
  CALL update_stocks('D07','PharmA','PhX',1.0,50);  CALL update_stocks('D08','PharmA','PhX',1.0,50);
  CALL update_stocks('D09','PharmA','PhX',1.0,50);  CALL update_stocks('D10','PharmA','PhX',1.0,50);
COMMIT;
START TRANSACTION;
  CALL update_stocks('D11','PharmB','PhY',2.0,60);  CALL update_stocks('D12','PharmB','PhY',2.0,60);
  CALL update_stocks('D13','PharmB','PhY',2.0,60);  CALL update_stocks('D14','PharmB','PhY',2.0,60);
  CALL update_stocks('D01','PharmA','PhY',2.0,60);  CALL update_stocks('D02','PharmA','PhY',2.0,60);
  CALL update_stocks('D03','PharmA','PhY',2.0,60);  CALL update_stocks('D04','PharmA','PhY',2.0,60);
  CALL update_stocks('D05','PharmA','PhY',2.0,60);  CALL update_stocks('D06','PharmA','PhY',2.0,60);
COMMIT;

-- prescriptions
CALL add_prescription('D100','P100','2025-04-01');
CALL add_prescription_content('D100','P100','D01','PharmA',10);
CALL add_prescription_content('D100','P100','D02','PharmA', 5);
CALL add_prescription('D300','P100','2025-05-01');
CALL add_prescription_content('D300','P100','D01','PharmA',10);
CALL add_prescription_content('D300','P100','D02','PharmA', 5);
-- contract
CALL add_contract('PhX','PharmA','2025-01-01','2026-01-01',
                  'bulk supply','Supervisor‑1');

-- ███  SECTION B  –  POSITIVE TESTS (report procedures)  ████████████████████

CALL report_patient_prescriptions_period('P100','2025-04-01','2025-05-30');

CALL print_prescription_details_by_date('P100','2025-04-01');

CALL list_drugs_by_company('PharmA');

CALL print_pharmacy_stock_position('PhX');

CALL print_pharmacy_company_contact('PhX','PharmA');
CALL print_contract('PhX','PharmA');

CALL print_patients_of_doctor('D100');

-- ███  SECTION C  –  NEGATIVE / EDGE‑CASE TESTS  ████████████████████████████
/* Each numbered block corresponds to a rule bullet in the PDF.
   We expect every attempt to violate a rule to raise SQLSTATE 45000 or 23000.
   ------------------------------------------------------------------------ */



-- -- (2)  Doctor must have at least one patient       →  delete should fail
-- CALL delete_doctor('D100');

-- -- (3)  Pharma‑company delete should cascade drugs
-- CALL delete_pharma_company('PharmB');
-- SELECT 'PharmB deleted; its drugs gone?' AS banner;
-- SELECT * FROM Drug WHERE ph_comp_name='PharmB';

-- -- (4)  Min‑10‑drugs rule on INSERT  (attempt to open PhZ with <10 rows)
-- CALL add_pharmacy('PhZ','999 Zero St','0000000000');
-- SELECT '--- expect error below (min‑10) ---' AS banner;
-- CALL update_stocks('D01','PharmA','PhZ',1.0,20);    -- 1st drug  → error

-- -- (5)  Min‑10‑drugs rule on DELETE
-- SELECT '--- expect error deleting last allowed item ---' AS banner;
-- DELETE FROM Sells
-- WHERE ph_name='PhX' AND trade_name='D10' AND ph_comp_name='PharmA'; -- leaves 9

-- -- (6)  Only NEWEST prescription kept  (back‑dated insert should be ignored)
-- CALL add_prescription('D100','P100','2025-03-01');  -- older than current
-- SELECT * FROM Prescription WHERE doc_id='D100' AND patient_id='P100';

-- -- (7)  One prescription per doctor‑patient per DATE
-- SELECT '--- expect error: duplicate date ---' AS banner;
-- CALL add_prescription('D100','P100','2025-04-01');  -- same date  → error

-- -- (8)  Contract supervisor update allowed
-- CALL update_contract('PhX','PharmA','2025-01-01','2026-01-01','Supervisor‑2');
-- SELECT * FROM Contract WHERE ph_name='PhX' AND ph_comp_name='PharmA';

-- -- (9)  Deleting a doctor when they cease to have patients  (should succeed)
-- CALL delete_patient('P100');  -- now D100 has zero patients
-- CALL delete_doctor('D100');   -- allowed because our logic auto‑deleted empty docs
-- SELECT 'D100 should be gone:' AS banner;  SELECT * FROM Doctor WHERE aadhar_id='D100';

-- -- End of test‑suite