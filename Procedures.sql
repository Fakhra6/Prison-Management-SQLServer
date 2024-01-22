--1-------------------------------
CREATE PROCEDURE GetVisitationsStatistics
    @month INT,
    @year INT
AS
BEGIN
    
    Declare @TotalVisitations INT;
    
    
    SELECT @TotalVisitations = COUNT(*)
    FROM DenormVisitorfileinmate
    WHERE MONTH(Date) = @month AND YEAR(Date) = @year;

   
    Print 'Total Visitations in ' + Convert(VARCHAR, @month) + '/' + Convert(VARCHAR, @year) + ': ' + Convert(VARCHAR, @TotalVisitations);

   --mostcommon
    SELECT TOP 1 RelationWithInmate, COUNT(*) AS RelationCount
    FROM DenormVisitorfileinmate
    WHERE MONTH(Date) = @month AND YEAR(Date) = @year
    GROUP BY RelationWithInmate
    ORDER BY RelationCount DESC;
    
    SELECT TOP 1 InmateID, Name, COUNT(*) AS VisitationsCount
    FROM DenormVisitorfileinmate
    WHERE MONTH(Date) = @month AND YEAR(Date) = @year
    GROUP BY InmateID, Name
    ORDER BY VisitationsCount DESC;
END;


--2-----------------------------------------------------------
CREATE PROCEDURE CalculateAverageAgeForCrime
    @crime varchar(50)
AS
BEGIN
    DECLARE @AverageAge float;
	DECLARE @Totalage float;
	DECLARE @Count int

	SELECT @Count = Count(*)
    FROM Inmate
    WHERE Crime = @crime;

    SELECT @Totalage = SUM(DATEDIFF(YEAR, DOB, GETDATE()))
    FROM Inmate
    WHERE Crime = @crime;

	SELECT @AverageAge = CAST(@Totalage AS decimal(10, 2)) / @Count
    FROM Inmate
    WHERE Crime = @crime;

    PRINT 'The no of inmates who commited the Crime '  + @crime + ' is: ' + CAST(@count AS VARCHAR) + ' and their average age is: "' + CAST(@AverageAge AS VARCHAR);
END
--3---------------------------------------------------------
CREATE PROCEDURE CountInmatesVisitedInfirmary
    @SectionID int
AS
BEGIN
    DECLARE @TotalVisits INT;
    SELECT @TotalVisits = COUNT(DISTINCT i.InmateID)
    FROM Inmate i
   JOIN InfirmaryLogFile l ON l.InmateID = i.InmateID
    JOIN PrisonInfirmary pi ON l.RecordID = pi.RecordID
    JOIN Room r ON i.RoomID = r.RoomID
    WHERE r.SectionID = @SectionID;

    PRINT 'Total number of inmates who visited the prison infirmary in Section ' + CONVERT(VARCHAR, @SectionID) + ': ' + CONVERT(VARCHAR, @TotalVisits);

    IF @TotalVisits > 1
    BEGIN
        PRINT 'List of inmates who visited more than once:';
        
        SELECT i.InmateID, i.Name, COUNT(pi.RecordID) AS VisitCount
        FROM Inmate i
		JOIN InfirmaryLogFile l ON l.InmateID = i.InmateID
        JOIN PrisonInfirmary pi ON l.RecordID = pi.RecordID
        JOIN Room r ON i.RoomID = r.RoomID
        WHERE r.SectionID = @SectionID
        GROUP BY i.InmateID, i.Name
        HAVING COUNT(l.InmateID) > 1;
    END
    ELSE
    BEGIN
        PRINT 'No inmates visited more than once in Section ' + CONVERT(VARCHAR, @SectionID) + '.';
    END
END;

--4--------------------------------------------------------------------
CREATE PROCEDURE ListofReleasedInmates
    @Month INT,
    @Year INT
	
AS
Begin
	Declare @totalcount int;

	SELECT @totalcount = count(inmateID)
	FROM DenormalizedInmateCase 
	WHERE MONTH(ReleaseDate) = @Month 
	AND YEAR(ReleaseDate) = @Year;

	
    
    SELECT
        InmateID,
        Name,
        Crime,
        AdmittedDate,
		ReleaseDate,
		CaseID,
        Verdict,
        CrimeDetails

    FROM DenormalizedInmateCase 
    WHERE
        MONTH(ReleaseDate) = @Month
        AND YEAR(ReleaseDate) = @Year;
	
	PRINT 'Total no of inmates released in month ' + convert(varchar, @month) + ' and year ' + convert(varchar, @year) + ': ' + convert(varchar, @totalcount);
	
END;

--5--------------------------------------------------
 Create view InmateSentenceView as
    Select
        InmateID,
        Name,
        AdmittedDate,
        ReleaseDate,
        DATEDIFF(YEAR, AdmittedDate, ReleaseDate) AS SentenceYears,
        DATEDIFF(MONTH, AdmittedDate, ReleaseDate) % 12 AS SentenceMonths,
        DATEDIFF(DAY, AdmittedDate, ReleaseDate) % 30 AS SentenceDays,
        DATEDIFF(YEAR, GETDATE(), ReleaseDate) AS RemainingYears,
        DATEDIFF(MONTH, GETDATE(), ReleaseDate) % 12 AS RemainingMonths,
        DATEDIFF(DAY, GETDATE(), ReleaseDate) % 30 AS RemainingDays
    From
        Inmate
	where RoomID is not null;

	--drop view InmateSentenceView;

CREATE PROCEDURE CalculateSentenceLengthAndRemainingTime
	@inmateid int
AS
begin
    Select
        InmateID,
        Name,
        AdmittedDate,
        ReleaseDate,
        SentenceYears,
        SentenceMonths,
        SentenceDays,
        RemainingYears,
        RemainingMonths,
        RemainingDays
    From
        InmateSentenceView
	where inmateID = @inmateID;

END;
--6-------------------------------------------------------------------------------------
CREATE VIEW currentFutureAge as
select 
	InmateID,
	Name,
	DOB,
	AdmittedDate,
	ReleaseDate,
	DATEDIFF(YEAR, DOB, GETDATE()) AS CurrentAge,
	DATEDIFF(YEAR, DOB, AdmittedDate) AS AgeAtAdmission,
	DATEDIFF(YEAR, DOB, ReleaseDate) AS AgeAfterRelease
	from Inmate
	where ReleaseDate > GETDATE();

	drop view curentFutureAge



CREATE PROCEDURE CalculateAgeInfo
as
Begin
    SELECT 
		InmateID,
		Name,
		DOB, 
		AdmittedDate,
		ReleaseDate,
		CurrentAge,
		AgeAtAdmission,
		AgeAfterRelease
	from
		CurrentFutureAge
	order by currentAge
END;

--7----------------------------------------------
CREATE PROCEDURE GetMostCommonDiagnosis
AS
Begin
    CREATE TABLE #DiagnosisCount (
        Diagnosis varchar(255),
        InmateCount int
    );
    INSERT INTO #DiagnosisCount (Diagnosis, InmateCount) --for counting
    Select
        Diagnosis,
        COUNT(DISTINCT il.InmateID) AS InmateCount
    from InfirmaryLogFile il
    Join  PrisonInfirmary pi ON il.RecordID = pi.RecordID
    Group by Diagnosis;

    Declare @MostCommonDiagnosis varchar(255);
	Declare @InmatesCount int;

	SELECT TOP 1
        @InmatesCount = InmateCount
    FROM
        #DiagnosisCount
    ORDER BY
        InmateCount DESC;

    SELECT TOP 1
        @MostCommonDiagnosis = Diagnosis
    FROM
        #DiagnosisCount
    ORDER BY
        InmateCount DESC;
    
    Print 'Most Common Diagnosis: ' + @MostCommonDiagnosis;

    Print 'Count of Inmates with ' + @MostCommonDiagnosis + ': ' + CAST(@inmatescount AS varchar(50));

    Print 'List of Inmates with ' + @MostCommonDiagnosis + ':';
    Select distinct
        i.InmateID,
        i.Name
    FROM
        InfirmaryLogFile il
    JOIN
        PrisonInfirmary pi ON il.RecordID = pi.RecordID
    JOIN
        Inmate i ON il.InmateID = i.InmateID
    WHERE
        pi.Diagnosis = @MostCommonDiagnosis;

    Drop table #DiagnosisCount;
END;
--8----------------------------------------------
CREATE PROCEDURE GetInmatesByDiagnosis
    @Diagnosis varchar(255)
AS
Begin
    Declare @InmateCount INT;

    Select @InmateCount = COUNT(DISTINCT i.InmateID)
    From Inmate i
	join InfirmaryLogFile f on f.InmateID = i.InmateID
    Join PrisonInfirmary pi ON f.RecordID = pi.RecordID
    Where pi.Diagnosis = @Diagnosis;

    print 'Number of inmates with diagnosis "' + @Diagnosis + '": ' + CAST(@InmateCount AS varchar(10));

    
    IF @InmateCount > 0
    Begin
        print 'List of inmates with their crimes:';

        SELECT
            i.InmateID,
            i.Name,
            i.Crime
        FROM Inmate i
        join InfirmaryLogFile f on f.InmateID = i.InmateID
        Join PrisonInfirmary pi ON f.RecordID = pi.RecordID
        WHERE
            pi.Diagnosis = @Diagnosis;
    END
END;
--9----------------------------------------------------
CREATE PROCEDURE CountDisciplinaryActionsByInmate
AS
BEGIN
    SELECT
        i.InmateID,
        i.Name,
		i.Crime,
		da.description,
        COUNT(da.ActionID) AS NumberOfActions
    FROM
        Inmate i
    JOIN
        DisciplinaryAction da ON i.InmateID = da.InmateID
    GROUP BY
        i.InmateID, i.Name, da.description, i.crime
    ORDER BY
        NumberOfActions desc
END;

--10-----------------------------------------------------
CREATE PROCEDURE CalculateAvgAgeAndSalary
AS
Begin
    Declare @Correctionalavgage Float;
    Declare @Correctionalavgsalary Money;
    Select
        @Correctionalavgage = Avg(Datediff(Year, Dob, Getdate())),
        @Correctionalavgsalary = Avg(Salary)
    From
        Prisonstaff
    Where
        Stafftype = 'Correctional Officer';

    Print 'Average Age Of Correctional Officers: ' + Cast(@Correctionalavgage As Varchar(20));
    Print 'Average Salary Of Correctional Officers: ' + Cast(@Correctionalavgsalary As Varchar(20));

    Declare @Administratoravgage Float;
    Declare @Administratoravgsalary Money;

    Select
        @Administratoravgage = Avg(Datediff(Year, Dob, Getdate())),
        @Administratoravgsalary = Avg(Salary)
    From
        Prisonstaff
    Where
        Stafftype = 'Administrator';

    Print 'Average Age Of Administrators: ' + Cast(@Administratoravgage As Varchar(20));
    Print 'Average Salary Of Administrators: ' + Cast(@Administratoravgsalary As Varchar(20));
End;

--11---------------------------------------------------
CREATE PROCEDURE RoomsWithFewInmatesorZero
AS
BEGIN
    Select
        r.RoomID,
        COUNT(i.InmateID) AS NumberOfInmates
    FROM Room r
    LEFT JOIN Inmate i ON r.RoomID = i.RoomID
    GROUP BY
        r.RoomID
    HAVING
        COUNT(i.InmateID) < 4;
END;
--12----------------
CREATE PROCEDURE GetInmateDetails
    @InmateID int
AS
Begin
    SELECT
        @InmateID as InmateID,
        Name,
        Crime,
        AdmittedDate,
		ReleaseDate,
		CaseID,
        Verdict,
        CrimeDetails
    FROM DenormalizedInmateCase 
    WHERE
	InmateID = @InmateID;
End;