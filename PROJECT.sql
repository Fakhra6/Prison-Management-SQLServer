create database project;
use project;



create table Section(
SectionID int PRIMARY KEY,
TotalRooms int not null,
OccupiedRooms int not null
);

create table Room(
RoomID int PRIMARY KEY,
SectionID int not null,
FOREIGN KEY(SectionID) references Section(SectionID)
);


create table CaseFile(
CaseID varchar(50) PRIMARY KEY,
CourtDate date,
Verdict varchar(255),
ProsecutorIncharge varchar(50),
CrimeDetails varchar(255),
); 

create table PrisonInfirmary(
RecordID int PRIMARY KEY,
Date date,
Time time,
Diagnosis varchar(255),
Treatment varchar(255),
);

create table Inmate(
InmateID int PRIMARY KEY,
Name varchar(50),
DOB date,
Address varchar(50),
AdmittedDate date,
ReleaseDate date,
Crime varchar(50),
CaseID varchar(50),
RoomID int,
RecordID int,
FOREIGN KEY(CaseID) references CaseFile(CaseID),
FOREIGN KEY(RoomID) references Room(RoomID)
);

create table PrisonStaff(
StaffID int PRIMARY KEY,
Name varchar(50),
DOB date,
Address varchar(50),
JoiningDate date,
Salary money,
StaffType varchar(50) CHECK (StaffType IN ('Warden', 'Correctional Officer', 'Administrator')),
WordSchedule varchar(50),
SectionID int,
FOREIGN KEY(SectionID) references Section(SectionID)
);

Create table DisciplinaryAction(
ActionID int PRIMARY KEY,
DateOccured date,
TimeOccured time,
Description varchar(100),
InmateID int,
StaffID int,
FOREIGN KEY(InmateID) references Inmate(InmateID),
FOREIGN KEY(StaffID) references PrisonStaff(StaffID)
);

alter table disciplinaryaction 
alter column staffid int not null;

create table Visitor(
VisitorID int PRIMARY KEY,
Date date,
Time time,
ContactInfo varchar(50),
RelationWithInmate varchar(50),
);

create table VisitorLogFile(
FileNo int PRIMARY KEY,
VisitorID int,
InmateID int,
FOREIGN KEY(VisitorID) references Visitor(VisitorID),
FOREIGN KEY(InmateID) references Inmate(InmateID)
);

create table InfirmaryLogFile(
FileNumber int PRIMARY KEY,
InmateID int,
RecordID int,
FOREIGN KEY(InmateID) references Inmate(InmateID),
FOREIGN KEY(RecordID) references PrisonInfirmary(RecordID)
);

------------------------------DENORMALIZED-----------------------------------------

CREATE TABLE DenormalizedInmateCase (
	InmateID INT,
	Name VARCHAR(50),
	DOB DATE,
	Address VARCHAR(50),
	AdmittedDate DATE,
	ReleaseDate DATE,
	Crime varchar(50),
	CaseID varchar(50),
	CourtDate date,
	Verdict varchar(255),
	ProsecutorIncharge varchar(50),
	CrimeDetails varchar(255)
	Primary key(InmateID, CaseID)
);

Create table DenormVisitorfileinmate(
InmateID int ,
Name varchar(50),
DOB date,
Address varchar(50),
AdmittedDate date,
ReleaseDate date,
Crime varchar(50),
VisitorID int,
Date date,
Time time,
ContactInfo varchar(50),
RelationWithInmate varchar(50),
FileNo int
Primary key(InmateID, VisitorID, FileNo)
);

INSERT INTO DenormVisitorfileinmate (InmateID, Name, DOB, Address, AdmittedDate, ReleaseDate, Crime, VisitorID, Date, Time, ContactInfo, RelationWithInmate, FileNo)
SELECT
    i.InmateID,
    i.Name,
    i.DOB,
    i.Address,
    i.AdmittedDate,
    i.ReleaseDate,
    i.Crime,
    v.VisitorID,
    v.Date,
    v.Time,
    v.ContactInfo,
    v.RelationWithInmate,
    vl.FileNo
FROM
    VisitorLogFile vl
JOIN
    inmate i ON i.InmateID = vl.InmateID
JOIN
    visitor v ON v.VisitorID = vl.VisitorID;


INSERT INTO DenormalizedInmateCase (InmateID, Name, DOB, Address, AdmittedDate, ReleaseDate, Crime, CaseID, CourtDate, Verdict, ProsecutorIncharge, CrimeDetails)
SELECT
    i.InmateID,
    i.Name,
    i.DOB,
    i.Address,
    i.AdmittedDate,
    i.ReleaseDate,
    i.Crime,
    c.CaseID,
    c.CourtDate,
    c.Verdict,
    c.ProsecutorIncharge,
    c.CrimeDetails
FROM
    Inmate i
JOIN
    CaseFile c ON i.CaseID = c.CaseID;

Select * from DenormalizedInmateCase;
select * from DenormVisitorfileinmate;

-----------------------------------------------------------------------



----------------------------AUDIT TABLE---------------------------------------------------------
create table auditTable1(TableName varchar(50), ModifiedBy varchar(50), ModifiedDate varchar(50))

create trigger Auditdelete
on DisciplinaryAction
after delete
as
insert into dbo.auditTable1
(TableName , ModifiedBy , ModifiedDate)

Values('DisciplinaryAction',SUSER_SNAME(),GETDATE())
GO

create trigger Auditins1
on DisciplinaryAction
after insert
as
insert into dbo.auditTable1
(TableName , ModifiedBy , ModifiedDate)

Values('DisciplinaryAction',SUSER_SNAME(),GETDATE())
GO

create trigger Auditupdat1
on DisciplinaryAction
after update
as
insert into dbo.auditTable1
(TableName , ModifiedBy , ModifiedDate)

Values('DisciplinaryAction',SUSER_SNAME(),GETDATE())
GO

select * from auditTable1;
--------------------------------------------------------------------
---------------------------------------------------------------------
select * from CaseFile;
select * from Inmate;
select * from Section;
select * from Room;
select * from DisciplinaryAction;
select * from PrisonStaff; 
select * from PrisonInfirmary;
select * from Visitor;
select * from VisitorLogFile;
select * from InfirmaryLogFile;
-----------------------------------------------------

Select * from auditTable1;
-----------------------------------------------------

---non clustered index--
CREATE NONCLUSTERED INDEX IX_Section_OccupiedRooms ON Section(OccupiedRooms);
CREATE NONCLUSTERED INDEX IX_Section_TotalRooms ON Section(TotalRooms);
CREATE NONCLUSTERED INDEX IX_Room_SectionID ON Room(SectionID);
CREATE NONCLUSTERED INDEX IX_PrisonStaff_SectionID ON PrisonStaff(SectionID);
CREATE NONCLUSTERED INDEX IX_DisciplinaryAction_InmateID ON DisciplinaryAction(InmateID);
CREATE NONCLUSTERED INDEX IX_DisciplinaryAction_StaffID ON DisciplinaryAction(StaffID);
CREATE NONCLUSTERED INDEX IX_VisitorLogFile_InmateID ON VisitorLogFile(InmateID);
CREATE NONCLUSTERED INDEX IX_VisitorLogFile_VisitorID ON VisitorLogFile(VisitorID);
CREATE NONCLUSTERED INDEX IX_InfirmaryLogFile_InmateID ON InfirmaryLogFile(InmateID);
CREATE NONCLUSTERED INDEX IX_InfirmaryLogFile_RecordID ON InfirmaryLogFile(RecordID);

--------------------------------------------------------------------------------------------

-- 1. No of visitations in a specific month and year, most common relation with inmate, the inmate with highest visitor in that month -- (DenormVisitorfileinmate)
Exec GetVisitationsStatistics @month = 12, @year = 2022;

-- 2. Display count and The average age of those who commited a specific crime --
Exec CalculateAverageAgeForCrime @crime = 'CyberCrime';
Exec CalculateAverageAgeForCrime @crime = 'Manslaughter';
Exec CalculateAverageAgeForCrime @crime = 'Animal Smuggling';
Exec CalculateAverageAgeForCrime @crime = 'Hit and Run';
Exec CalculateAverageAgeForCrime @crime = 'Fraud';

--3. Count the no of inmates from specific section visited the infimrary during their stay in prison and lsit those who visited more than once
EXEC CountInmatesVisitedInfirmary @SectionID = 102

--4. List the ones who got released in a specific month and specific year- (DenormalizedInmateCase)
EXEC ListofReleasedInmates @month = 1, @year = 2024;
EXEC ListofReleasedInmates @month = 12, @year = 2022;

--5. Calculate the sentence lenth and remaining serving time of given inmate-- used view
EXEC CalculateSentenceLengthAndRemainingTime @InmateID = 5007;
EXEC CalculateSentenceLengthAndRemainingTime @InmateID = 5009;

--6. Calculate age right now and age at admission and after release, order by youngest right now. --used view
EXEC CalculateAgeInfo;

--7. Most common diagnosis in inmates and list those who have been diagnosed with it. (distincly counted) Used temp table
EXEC GetMostCommonDiagnosis

--8. Display and count the inmates suffering from specific disease/diagnosis
EXEC GetInmatesByDiagnosis @Diagnosis = 'Depression';

--9. Number of displinaryaction against inmates, crime and descripption about action taken order by noOFActions
EXEC CountDisciplinaryActionsByInmate

--10. Get average age of correctional officers and adminitrators separately
EXEC CalculateAvgAgeAndSalary

--11. Free rooms
EXEC RoomsWithFewInmatesorZero

--12. IF officer wants to look up an inmate -denormalizedInmate
EXEC GetInmateDetails @inmateID = 5724;

