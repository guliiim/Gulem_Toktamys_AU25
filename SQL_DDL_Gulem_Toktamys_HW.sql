-- Create the database
CREATE DATABASE IF NOT EXISTS campaign_db
--\c campaign_db

-- Create the schema
CREATE SCHEMA IF NOT EXISTS campaign;

--Create Table
-- PARTY
CREATE TABLE IF NOT EXISTS campaign.party (
    partyid INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    partyname VARCHAR(100) NOT NULL UNIQUE
);

-- CANDIDATE
CREATE TABLE IF NOT EXISTS campaign.candidate (
    candidateid INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    fullname VARCHAR(100) NOT NULL UNIQUE,
    partyid INT REFERENCES campaign.party(partyid) ON DELETE SET NULL,
    position VARCHAR(100),
    campaignstartdate DATE CHECK (campaignstartdate IS NULL OR campaignstartdate > DATE '2000-01-01')
);

-- VOTER
CREATE TABLE IF NOT EXISTS campaign.voter (
    voterid INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    firstname VARCHAR(50) NOT NULL,
    lastname VARCHAR(50) NOT NULL,
    dateofbirth DATE CHECK (dateofbirth < CURRENT_DATE),
    gender CHAR(1) CHECK (gender IN ('M','F','O')),
    email VARCHAR(100) UNIQUE,
    phone VARCHAR(20),
    district VARCHAR(100),
    state VARCHAR(100),
    locality VARCHAR(100),
    street VARCHAR(100),
    building VARCHAR(100)
);

-- DONOR
CREATE TABLE IF NOT EXISTS campaign.donor (
    donorid INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    donorname VARCHAR(100) NOT NULL UNIQUE,
    contactnumber VARCHAR(20),
    email VARCHAR(100),
    address VARCHAR(255)
);

-- CAMPAIGNEVENT
CREATE TABLE IF NOT EXISTS campaign.campaignevent (
    eventid INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    candidateid INT REFERENCES campaign.candidate(candidateid) ON DELETE CASCADE,
    eventname VARCHAR(100) NOT NULL,
    eventtype VARCHAR(50) CHECK (eventtype IN ('Rally','TownHall','SocialMedia')),
    eventdate DATE NOT NULL CHECK (eventdate > DATE '2000-01-01'),
    location VARCHAR(100)
);

-- VOLUNTEER
CREATE TABLE IF NOT EXISTS campaign.volunteer (
    volunteerid INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    fullname VARCHAR(100) NOT NULL,
    contactnumber VARCHAR(20),
    email VARCHAR(100) UNIQUE,
    availability VARCHAR(50) CHECK (availability IN ('Full-Time','Part-Time')),
    supervisorid INT REFERENCES campaign.volunteer(volunteerid) ON DELETE SET NULL,
    role VARCHAR(50)
);

-- VOLUNTEEREVENTASSIGNMENT
CREATE TABLE IF NOT EXISTS campaign.volunteereventassignment (
    volunteerid INT NOT NULL REFERENCES campaign.volunteer(volunteerid) ON DELETE CASCADE,
    eventid INT NOT NULL REFERENCES campaign.campaignevent(eventid) ON DELETE CASCADE,
    task VARCHAR(100),
    assigneddate DATE DEFAULT CURRENT_DATE,
    PRIMARY KEY (volunteerid, eventid)
);

-- DONATION
CREATE TABLE IF NOT EXISTS campaign.donation (
    donationid INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    donorid INT NOT NULL REFERENCES campaign.donor(donorid) ON DELETE RESTRICT,
    candidateid INT NOT NULL REFERENCES campaign.candidate(candidateid) ON DELETE CASCADE,
    amount DECIMAL(10,2) NOT NULL CHECK (amount > 0),
    donationdate DATE NOT NULL CHECK (donationdate > DATE '2000-01-01'),
    paymentmethod VARCHAR(20) CHECK (paymentmethod IN ('Cash','Card','Online'))
);

-- SURVEY
CREATE TABLE IF NOT EXISTS campaign.survey (
    surveyid INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    title VARCHAR(100),
    candidateid INT REFERENCES campaign.candidate(candidateid) ON DELETE SET NULL,
    conducteddate DATE CHECK (conducteddate IS NULL OR conducteddate > DATE '2000-01-01'),
    samplesize INT CHECK (samplesize IS NULL OR samplesize > 0)
);

-- SURVEYRESULT
CREATE TABLE IF NOT EXISTS campaign.surveyresult (
    resultid INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    surveyid INT NOT NULL REFERENCES campaign.survey(surveyid) ON DELETE CASCADE,
    question VARCHAR(255),
    optiona VARCHAR(100),
    optionb VARCHAR(100),
    optionc VARCHAR(100),
    optiond VARCHAR(100),
    winningoption CHAR(1) CHECK (winningoption IN ('A','B','C','D'))
);

-- ELECTIONISSUE
CREATE TABLE IF NOT EXISTS campaign.electionissue (
    issueid INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    description TEXT NOT NULL,
    reportedby VARCHAR(100),
    datereported DATE CHECK (datereported IS NULL OR datereported > DATE '2000-01-01'),
    severity VARCHAR(20) CHECK (severity IN ('Low','Medium','High')),
    relatedeventid INT REFERENCES campaign.campaignevent(eventid) ON DELETE SET NULL
);


-- FINANCE 
CREATE TABLE IF NOT EXISTS campaign.finance (
    financeid INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    candidateid INT UNIQUE REFERENCES campaign.candidate(candidateid) ON DELETE CASCADE,
    totalraised DECIMAL(12,2) NOT NULL CHECK (totalraised >= 0),
    totalspent DECIMAL(12,2) NOT NULL CHECK (totalspent >= 0),
    lastupdated DATE DEFAULT CURRENT_DATE
);


--Insert Data
INSERT INTO campaign.party (partyname)
SELECT 'People''s Choice'
WHERE NOT EXISTS (SELECT 1 FROM campaign.party WHERE LOWER(partyname)=LOWER('People''s Choice'));

INSERT INTO campaign.party (partyname)
SELECT 'United Future'
WHERE NOT EXISTS (SELECT 1 FROM campaign.party WHERE LOWER(partyname)=LOWER('United Future'));

INSERT INTO campaign.candidate (fullname, partyid, position, campaignstartdate)
SELECT 'Aliyev Askar', partyid, 'President', DATE '2025-03-01'
FROM campaign.party
WHERE LOWER(partyname)=LOWER('People''s Choice')
  AND NOT EXISTS (SELECT 1 FROM campaign.candidate WHERE LOWER(fullname)=LOWER('Aliyev Askar'));

INSERT INTO campaign.candidate (fullname, partyid, position, campaignstartdate)
SELECT 'Nurgali Dina', partyid, 'Mayor', DATE '2025-02-15'
FROM campaign.party
WHERE LOWER(partyname)=LOWER('United Future')
  AND NOT EXISTS (SELECT 1 FROM campaign.candidate WHERE LOWER(fullname)=LOWER('Nurgali Dina'));

INSERT INTO campaign.voter (firstname, lastname, dateofbirth, gender, email, phone, district, state, locality, street, building)
SELECT 'Aida', 'Serikova', DATE '1998-03-15', 'F', 'aida.s@mail.kz', '+77011234567', 'Almaty District 3', 'Almaty Region', 'Almaty', 'Abai Avenue', '5A'
WHERE NOT EXISTS (SELECT 1 FROM campaign.voter WHERE LOWER(email)=LOWER('aida.s@mail.kz'));

INSERT INTO campaign.voter (firstname, lastname, dateofbirth, gender, email, phone, district, state, locality, street, building)
SELECT 'Bulat', 'Karimov', DATE '1979-11-02', 'M', 'bulat.k@mail.kz', '+77017654321', 'Astana District 1', 'Astana Region', 'Astana', 'Republic Ave', '12'
WHERE NOT EXISTS (SELECT 1 FROM campaign.voter WHERE LOWER(email)=LOWER('bulat.k@mail.kz'));

INSERT INTO campaign.donor (donorname, contactnumber, email, address)
SELECT 'NurCorp Ltd.', '+77055667788', 'contact@nurcorp.kz', 'Astana, 12 Republic Ave'
WHERE NOT EXISTS (SELECT 1 FROM campaign.donor WHERE LOWER(donorname)=LOWER('NurCorp Ltd.'));

INSERT INTO campaign.donor (donorname, contactnumber, email, address)
SELECT 'Individual Donor 1', '+77010020030', 'donor1@example.com', 'Almaty, 5 Abai Ave'
WHERE NOT EXISTS (SELECT 1 FROM campaign.donor WHERE LOWER(donorname)=LOWER('Individual Donor 1'));

INSERT INTO campaign.campaignevent (candidateid, eventname, eventtype, eventdate, location)
SELECT c.candidateid, 'Central Rally', 'Rally', DATE '2025-05-12', 'Astana Square'
FROM campaign.candidate c
WHERE LOWER(fullname)=LOWER('Aliyev Askar')
  AND NOT EXISTS (SELECT 1 FROM campaign.campaignevent WHERE candidateid=c.candidateid AND LOWER(eventname)=LOWER('Central Rally'));

INSERT INTO campaign.campaignevent (candidateid, eventname, eventtype, eventdate, location)
SELECT c.candidateid, 'Town Hall Meeting', 'TownHall', DATE '2025-04-20', 'City Hall'
FROM campaign.candidate c
WHERE LOWER(fullname)=LOWER('Nurgali Dina')
  AND NOT EXISTS (SELECT 1 FROM campaign.campaignevent WHERE candidateid=c.candidateid AND LOWER(eventname)=LOWER('Town Hall Meeting'));

INSERT INTO campaign.volunteer (fullname, contactnumber, email, availability, supervisorid, role)
SELECT 'Dina Tulegenova', '+77033445566', 'dina.t@mail.kz', 'Full-Time', NULL, 'Assistant'
WHERE NOT EXISTS (SELECT 1 FROM campaign.volunteer WHERE LOWER(email)=LOWER('dina.t@mail.kz'));

INSERT INTO campaign.volunteer (fullname, contactnumber, email, availability, supervisorid, role)
SELECT 'Erik Samat', '+77030040050', 'erik.s@mail.kz', 'Part-Time', NULL, 'Stage Crew'
WHERE NOT EXISTS (SELECT 1 FROM campaign.volunteer WHERE LOWER(email)=LOWER('erik.s@mail.kz'));

--creates the supervisor relationship after inserting the volunteers 
UPDATE campaign.volunteer
SET supervisorid = (SELECT volunteerid FROM campaign.volunteer WHERE LOWER(fullname)=LOWER('Dina Tulegenova'))
WHERE LOWER(fullname)=LOWER('Erik Samat')
  AND supervisorid IS DISTINCT FROM (SELECT volunteerid FROM campaign.volunteer WHERE LOWER(fullname)=LOWER('Dina Tulegenova'));

INSERT INTO campaign.volunteereventassignment (volunteerid, eventid, task, assigneddate)
SELECT v.volunteerid, e.eventid, 'Stage Setup', DATE '2025-05-10'
FROM campaign.volunteer v
JOIN campaign.campaignevent e ON LOWER(v.fullname)=LOWER('Dina Tulegenova') AND LOWER(e.eventname)=LOWER('Central Rally')
WHERE NOT EXISTS (
    SELECT 1 FROM campaign.volunteereventassignment ve
    WHERE ve.volunteerid=v.volunteerid AND ve.eventid=e.eventid
);

INSERT INTO campaign.volunteereventassignment (volunteerid, eventid, task, assigneddate)
SELECT v.volunteerid, e.eventid, 'Sound Check', CURRENT_DATE
FROM campaign.volunteer v
JOIN campaign.campaignevent e ON LOWER(v.fullname)=LOWER('Erik Samat') AND LOWER(e.eventname)=LOWER('Central Rally')
WHERE NOT EXISTS (
    SELECT 1 FROM campaign.volunteereventassignment ve
    WHERE ve.volunteerid=v.volunteerid AND ve.eventid=e.eventid
);

INSERT INTO campaign.donation (donorid, candidateid, amount, donationdate, paymentmethod)
SELECT d.donorid, c.candidateid, 5000.00, DATE '2025-04-15', 'Online'
FROM campaign.donor d
JOIN campaign.candidate c ON LOWER(d.donorname)=LOWER('NurCorp Ltd.') AND LOWER(c.fullname)=LOWER('Aliyev Askar')
WHERE NOT EXISTS (
    SELECT 1 FROM campaign.donation x
    WHERE x.donorid=d.donorid AND x.candidateid=c.candidateid AND x.donationdate=DATE '2025-04-15'
);

INSERT INTO campaign.donation (donorid, candidateid, amount, donationdate, paymentmethod)
SELECT d.donorid, c.candidateid, 250.00, DATE '2025-03-20', 'Card'
FROM campaign.donor d
JOIN campaign.candidate c ON LOWER(d.donorname)=LOWER('Individual Donor 1') AND LOWER(c.fullname)=LOWER('Nurgali Dina')
WHERE NOT EXISTS (
    SELECT 1 FROM campaign.donation x
    WHERE x.donorid=d.donorid AND x.candidateid=c.candidateid AND x.donationdate=DATE '2025-03-20'
);

INSERT INTO campaign.survey (title, candidateid, conducteddate, samplesize)
SELECT 'Public Approval 2025', c.candidateid, DATE '2025-06-01', 1200
FROM campaign.candidate c
WHERE LOWER(c.fullname)=LOWER('Aliyev Askar')
  AND NOT EXISTS (
    SELECT 1 FROM campaign.survey s
    WHERE LOWER(s.title)=LOWER('Public Approval 2025') AND s.candidateid=c.candidateid
);

INSERT INTO campaign.survey (title, candidateid, conducteddate, samplesize)
SELECT 'City Concerns Poll', c.candidateid, DATE '2025-05-10', 500
FROM campaign.candidate c
WHERE LOWER(c.fullname)=LOWER('Nurgali Dina')
  AND NOT EXISTS (
    SELECT 1 FROM campaign.survey s
    WHERE LOWER(s.title)=LOWER('City Concerns Poll') AND s.candidateid=c.candidateid
);

INSERT INTO campaign.surveyresult (surveyid, question, optiona, optionb, optionc, optiond, winningoption)
SELECT s.surveyid, 'Do you support Candidate Aliyev?', 'Yes', 'No', 'Neutral', 'No Answer', 'A'
FROM campaign.survey s
WHERE LOWER(s.title)=LOWER('Public Approval 2025')
  AND NOT EXISTS (
    SELECT 1 FROM campaign.surveyresult r
    WHERE r.surveyid=s.surveyid AND LOWER(r.question)=LOWER('Do you support Candidate Aliyev?')
);

INSERT INTO campaign.surveyresult (surveyid, question, optiona, optionb, optionc, optiond, winningoption)
SELECT s.surveyid, 'Is public transport satisfactory?', 'Yes', 'No', 'Somewhat', 'No answer', 'B'
FROM campaign.survey s
WHERE LOWER(s.title)=LOWER('City Concerns Poll')
  AND NOT EXISTS (
    SELECT 1 FROM campaign.surveyresult r
    WHERE r.surveyid=s.surveyid AND LOWER(r.question)=LOWER('Is public transport satisfactory?')
);

INSERT INTO campaign.electionissue (description, reportedby, datereported, severity, relatedeventid)
SELECT 'Missing chairs at Town Hall', 'Bulat Karim', DATE '2025-05-20', 'Low', e.eventid
FROM campaign.campaignevent e
WHERE LOWER(e.eventname)=LOWER('Town Hall Meeting')
  AND NOT EXISTS (
    SELECT 1 FROM campaign.electionissue i
    WHERE LOWER(i.description)=LOWER('Missing chairs at Town Hall') AND i.relatedeventid=e.eventid
);

INSERT INTO campaign.electionissue (description, reportedby, datereported, severity, relatedeventid)
SELECT 'Protest near rally entrance', 'Local Police', DATE '2025-05-12', 'Medium', e.eventid
FROM campaign.campaignevent e
WHERE LOWER(e.eventname)=LOWER('Central Rally')
  AND NOT EXISTS (
    SELECT 1 FROM campaign.electionissue i
    WHERE LOWER(i.description)=LOWER('Protest near rally entrance') AND i.relatedeventid=e.eventid
);

INSERT INTO campaign.finance (candidateid, totalraised, totalspent, lastupdated)
SELECT c.candidateid, 125000.00, 87000.00, CURRENT_DATE
FROM campaign.candidate c
WHERE LOWER(c.fullname)=LOWER('Aliyev Askar')
  AND NOT EXISTS (SELECT 1 FROM campaign.finance f WHERE f.candidateid=c.candidateid);

INSERT INTO campaign.finance (candidateid, totalraised, totalspent, lastupdated)
SELECT c.candidateid, 35000.00, 15000.00, CURRENT_DATE
FROM campaign.candidate c
WHERE LOWER(c.fullname)=LOWER('Nurgali Dina')
  AND NOT EXISTS (SELECT 1 FROM campaign.finance f WHERE f.candidateid=c.candidateid);

--Add new column
ALTER TABLE campaign.party
  ADD COLUMN IF NOT EXISTS record_ts DATE DEFAULT CURRENT_DATE;
UPDATE campaign.party SET record_ts = CURRENT_DATE WHERE record_ts IS NULL;
ALTER TABLE campaign.party ALTER COLUMN record_ts SET NOT NULL;

ALTER TABLE campaign.candidate
  ADD COLUMN IF NOT EXISTS record_ts DATE DEFAULT CURRENT_DATE;
UPDATE campaign.candidate SET record_ts = CURRENT_DATE WHERE record_ts IS NULL;
ALTER TABLE campaign.candidate ALTER COLUMN record_ts SET NOT NULL;

ALTER TABLE campaign.voter
  ADD COLUMN IF NOT EXISTS record_ts DATE DEFAULT CURRENT_DATE;
UPDATE campaign.voter SET record_ts = CURRENT_DATE WHERE record_ts IS NULL;
ALTER TABLE campaign.voter ALTER COLUMN record_ts SET NOT NULL;

ALTER TABLE campaign.donor
  ADD COLUMN IF NOT EXISTS record_ts DATE DEFAULT CURRENT_DATE;
UPDATE campaign.donor SET record_ts = CURRENT_DATE WHERE record_ts IS NULL;
ALTER TABLE campaign.donor ALTER COLUMN record_ts SET NOT NULL;

ALTER TABLE campaign.campaignevent
  ADD COLUMN IF NOT EXISTS record_ts DATE DEFAULT CURRENT_DATE;
UPDATE campaign.campaignevent SET record_ts = CURRENT_DATE WHERE record_ts IS NULL;
ALTER TABLE campaign.campaignevent ALTER COLUMN record_ts SET NOT NULL;

ALTER TABLE campaign.volunteer
  ADD COLUMN IF NOT EXISTS record_ts DATE DEFAULT CURRENT_DATE;
UPDATE campaign.volunteer SET record_ts = CURRENT_DATE WHERE record_ts IS NULL;
ALTER TABLE campaign.volunteer ALTER COLUMN record_ts SET NOT NULL;

ALTER TABLE campaign.volunteereventassignment
  ADD COLUMN IF NOT EXISTS record_ts DATE DEFAULT CURRENT_DATE;
UPDATE campaign.volunteereventassignment SET record_ts = CURRENT_DATE WHERE record_ts IS NULL;
ALTER TABLE campaign.volunteereventassignment ALTER COLUMN record_ts SET NOT NULL;

ALTER TABLE campaign.donation
  ADD COLUMN IF NOT EXISTS record_ts DATE DEFAULT CURRENT_DATE;
UPDATE campaign.donation SET record_ts = CURRENT_DATE WHERE record_ts IS NULL;
ALTER TABLE campaign.donation ALTER COLUMN record_ts SET NOT NULL;

ALTER TABLE campaign.survey
  ADD COLUMN IF NOT EXISTS record_ts DATE DEFAULT CURRENT_DATE;
UPDATE campaign.survey SET record_ts = CURRENT_DATE WHERE record_ts IS NULL;
ALTER TABLE campaign.survey ALTER COLUMN record_ts SET NOT NULL;

ALTER TABLE campaign.surveyresult
  ADD COLUMN IF NOT EXISTS record_ts DATE DEFAULT CURRENT_DATE;
UPDATE campaign.surveyresult SET record_ts = CURRENT_DATE WHERE record_ts IS NULL;
ALTER TABLE campaign.surveyresult ALTER COLUMN record_ts SET NOT NULL;

ALTER TABLE campaign.electionissue
  ADD COLUMN IF NOT EXISTS record_ts DATE DEFAULT CURRENT_DATE;
UPDATE campaign.electionissue SET record_ts = CURRENT_DATE WHERE record_ts IS NULL;
ALTER TABLE campaign.electionissue ALTER COLUMN record_ts SET NOT NULL;

ALTER TABLE campaign.finance
  ADD COLUMN IF NOT EXISTS record_ts DATE DEFAULT CURRENT_DATE;
UPDATE campaign.finance SET record_ts = CURRENT_DATE WHERE record_ts IS NULL;
ALTER TABLE campaign.finance ALTER COLUMN record_ts SET NOT NULL;