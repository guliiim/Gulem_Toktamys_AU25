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
INSERT INTO campaign.party (partyname) VALUES
  ('People''s Choice'),
  ('United Future')
ON CONFLICT (partyname) DO NOTHING;

INSERT INTO campaign.candidate (fullname, partyid, position, campaignstartdate) VALUES
  ('Aliyev Askar', (SELECT partyid FROM campaign.party WHERE partyname = 'People''s Choice'), 'President', DATE '2025-03-01'),
  ('Nurgali Dina', (SELECT partyid FROM campaign.party WHERE partyname = 'United Future'), 'Mayor', DATE '2025-02-15')
ON CONFLICT (fullname) DO NOTHING;

INSERT INTO campaign.voter (firstname, lastname, dateofbirth, gender, email, phone, district, state, locality, street, building) VALUES
  ('Aida', 'Serikova', DATE '1998-03-15', 'F', 'aida.s@mail.kz', '+77011234567', 'Almaty District 3', 'Almaty Region', 'Almaty', 'Abai Avenue', '5A'),
  ('Bulat', 'Karimov', DATE '1979-11-02', 'M', 'bulat.k@mail.kz', '+77017654321', 'Astana District 1', 'Astana Region', 'Astana', 'Republic Ave', '12')
ON CONFLICT (email) DO NOTHING;

INSERT INTO campaign.donor (donorname, contactnumber, email, address) VALUES
  ('NurCorp Ltd.', '+77055667788', 'contact@nurcorp.kz', 'Astana, 12 Republic Ave'),
  ('Individual Donor 1', '+77010020030', 'donor1@example.com', 'Almaty, 5 Abai Ave')
ON CONFLICT (donorname) DO NOTHING;

INSERT INTO campaign.campaignevent (candidateid, eventname, eventtype, eventdate, location) VALUES
  (
    (SELECT candidateid FROM campaign.candidate WHERE fullname='Aliyev Askar'),
    'Central Rally',
    'Rally',
    DATE '2025-05-12',
    'Astana Square'
  ),
  (
    (SELECT candidateid FROM campaign.candidate WHERE fullname='Nurgali Dina'),
    'Town Hall Meeting',
    'TownHall',
    DATE '2025-04-20',
    'City Hall'
  )
ON CONFLICT (eventid) DO NOTHING;

INSERT INTO campaign.volunteer (fullname, contactnumber, email, availability, supervisorid, role) VALUES
  ('Dina Tulegenova', '+77033445566', 'dina.t@mail.kz', 'Full-Time', NULL, 'Assistant'),
  ('Erik Samat', '+77030040050', 'erik.s@mail.kz', 'Part-Time', NULL, 'Stage Crew')
ON CONFLICT (email) DO NOTHING;

--creates the supervisor relationship after inserting the volunteers 
UPDATE campaign.volunteer
SET supervisorid = (SELECT volunteerid FROM campaign.volunteer WHERE fullname='Dina Tulegenova')
WHERE fullname = 'Erik Samat' AND supervisorid IS DISTINCT FROM (SELECT volunteerid FROM campaign.volunteer WHERE fullname='Dina Tulegenova');

INSERT INTO campaign.volunteereventassignment (volunteerid, eventid, task, assigneddate) VALUES
  (
    (SELECT volunteerid FROM campaign.volunteer WHERE email='dina.t@mail.kz'),
    (SELECT eventid FROM campaign.campaignevent WHERE eventname='Central Rally'),
    'Stage Setup',
    DATE '2025-05-10'
  ),
  (
    (SELECT volunteerid FROM campaign.volunteer WHERE email='erik.s@mail.kz'),
    (SELECT eventid FROM campaign.campaignevent WHERE eventname='Central Rally'),
    'Sound Check',
    CURRENT_DATE
  )
ON CONFLICT (volunteerid, eventid) DO NOTHING;

INSERT INTO campaign.donation (donorid, candidateid, amount, donationdate, paymentmethod) VALUES
  (
    (SELECT donorid FROM campaign.donor WHERE donorname='NurCorp Ltd.'),
    (SELECT candidateid FROM campaign.candidate WHERE fullname='Aliyev Askar'),
    5000.00,
    DATE '2025-04-15',
    'Online'
  ),
  (
    (SELECT donorid FROM campaign.donor WHERE donorname='Individual Donor 1'),
    (SELECT candidateid FROM campaign.candidate WHERE fullname='Nurgali Dina'),
    250.00,
    DATE '2025-03-20',
    'Card'
  )
ON CONFLICT (donationid) DO NOTHING;

INSERT INTO campaign.survey (title, candidateid, conducteddate, samplesize) VALUES
  ('Public Approval 2025', (SELECT candidateid FROM campaign.candidate WHERE fullname='Aliyev Askar'), DATE '2025-06-01', 1200),
  ('City Concerns Poll', (SELECT candidateid FROM campaign.candidate WHERE fullname='Nurgali Dina'), DATE '2025-05-10', 500)
ON CONFLICT (surveyid) DO NOTHING;

INSERT INTO campaign.surveyresult (surveyid, question, optiona, optionb, optionc, optiond, winningoption) VALUES
  (
    (SELECT surveyid FROM campaign.survey WHERE title='Public Approval 2025'),
    'Do you support Candidate Aliyev?',
    'Yes', 'No', 'Neutral', 'No Answer', 'A'
  ),
  (
    (SELECT surveyid FROM campaign.survey WHERE title='City Concerns Poll'),
    'Is public transport satisfactory?',
    'Yes', 'No', 'Somewhat', 'No answer', 'B'
  )
ON CONFLICT (resultid) DO NOTHING;

INSERT INTO campaign.electionissue (description, reportedby, datereported, severity, relatedeventid) VALUES
  ('Missing chairs at Town Hall', 'Bulat Karim', DATE '2025-05-20', 'Low', (SELECT eventid FROM campaign.campaignevent WHERE eventname='Town Hall Meeting')),
  ('Protest near rally entrance', 'Local Police', DATE '2025-05-12', 'Medium', (SELECT eventid FROM campaign.campaignevent WHERE eventname='Central Rally'))
ON CONFLICT (issueid) DO NOTHING;

INSERT INTO campaign.finance (candidateid, totalraised, totalspent, lastupdated) VALUES
  ((SELECT candidateid FROM campaign.candidate WHERE fullname='Aliyev Askar'), 125000.00, 87000.00, CURRENT_DATE),
  ((SELECT candidateid FROM campaign.candidate WHERE fullname='Nurgali Dina'), 35000.00, 15000.00, CURRENT_DATE)
ON CONFLICT (candidateid) DO NOTHING;

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