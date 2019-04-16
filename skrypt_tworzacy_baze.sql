USE master
IF DB_ID('Baza_Konferencje') IS NOT NULL
DROP DATABASE Baza_Konferencj
GO
CREATE DATABASE Baza_Konferencje
GO

USE Baza_Konferencje

IF OBJECT_ID ('Conferences','U') is not null
DROP Table Conferences
GO
CREATE TABLE Conferences (
    ConferenceID int IDENTITY(1, 1) NOT NULL,
    ConferenceName nvarchar(200) NOT NULL,
    StartDate date  NOT NULL,
    EndDate date  NOT NULL,
    Country nvarchar(32)  NOT NULL,
    City nvarchar(32)  NOT NULL,
    Street nvarchar(32)  NOT NULL,
    PRIMARY KEY  (ConferenceID),
	CONSTRAINT good_dates check (StartDate <= EndDate),
	CONSTRAINT name_and_date unique (ConferenceName, StartDate)
);

IF OBJECT_ID ('Customers','U') is not null
DROP Table Customers
GO
CREATE TABLE Customers (
    CustomerID int IDENTITY(1, 1) NOT NULL,
    Name nvarchar(32) NOT NULL,
    Country nvarchar(32)  NOT NULL,
    City nvarchar(32)  NOT NULL,
    Street nvarchar(32)  NOT NULL,
    Phone nvarchar(32)  NOT NULL,
    Email nvarchar(32),
    PRIMARY KEY  (CustomerID),
	CONSTRAINT phone check (Phone like '%[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'),
	CONSTRAINT email check (email like '%@%.%'),
	CONSTRAINT name UNIQUE (Name)
);

IF OBJECT_ID ('Days','U') is not null
DROP Table Days
GO
CREATE TABLE Days (
    DayID int IDENTITY(1, 1) NOT NULL,
    ConferenceID int  NOT NULL,
    Date date  NOT NULL,
    Price money  NOT NULL,
    NumOfPlaces int default (200) NOT NULL,
    PRIMARY KEY  (DayID),
	CONSTRAINT num_of_places check (NumOfPlaces > 0),
	CONSTRAINT price check (Price >= 0),
	CONSTRAINT conference_day UNIQUE (ConferenceID, date)
);

IF OBJECT_ID ('DaysReservations','U') is not null
DROP Table DaysReservations
GO
CREATE TABLE DaysReservations (
    DaysReservationID int IDENTITY(1, 1) NOT NULL,
    CustomerID int  NOT NULL,
    DayID int  NOT NULL,
    ReservationDate date  NOT NULL,
    IsCanceled bit default (0) NOT NULL,
	NumOfNormalParticipants int default (1) NOT NULL,
	NumOfStudents int default 0 NOT NULL,
    PRIMARY KEY  (DaysReservationID),
	CONSTRAINT num_of_all_participants check (NumOfNormalParticipants > 0 or NumOfStudents > 0),
	CONSTRAINT num_of_normal_participants check (NumOfNormalParticipants >=0 ),
	CONSTRAINT num_of_student_participants check (NumOfStudents >=0 ),
);

IF OBJECT_ID ('Firms','U') is not null
DROP Table Firms
GO
CREATE TABLE Firms (
    CustomerID int IDENTITY(1, 1) NOT NULL,
    NIP bigint  NOT NULL,
    REGON bigint  NOT NULL,
    PRIMARY KEY  (CustomerID),
	CONSTRAINT nip check (NIP like '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]')
);

IF OBJECT_ID ('Participants','U') is not null
DROP Table Participants
GO
CREATE TABLE Participants (
    ParticipantID int IDENTITY(1, 1) NOT NULL,
    CustomerID int  NOT NULL,
	DaysReservationID int NOT NULL,
    FirstName nvarchar(32)  NOT NULL,
    LastName nvarchar(32)  NOT NULL,
    StudentCardNr int  NULL,
    PRIMARY KEY  (ParticipantID),
	CONSTRAINT student_card_nr check (StudentCardNr like '[0-9][0-9][0-9][0-9][0-9][0-9]')
);

IF OBJECT_ID ('Payments','U') is not null
DROP Table Payments
GO
CREATE TABLE Payments (
    PaymentID int IDENTITY(1, 1) NOT NULL,
    DaysReservationID int  NOT NULL,
    Value money  NOT NULL,
    Date date  NOT NULL,
    PRIMARY KEY  (PaymentID),
	CONSTRAINT value check (value > 0)
);

IF OBJECT_ID ('Workshops','U') is not null
DROP Table Workshops
GO
CREATE TABLE Workshops (
    WorkshopID int IDENTITY(1, 1) NOT NULL,
    DayID int  NOT NULL,
    WorkshopName nvarchar(200)  NOT NULL,
    StartTime time  NOT NULL,
    EndTime time  NOT NULL,
    Price money  NOT NULL,
    NumOfPlaces int  NOT NULL,
    PRIMARY KEY  (WorkshopID),
	CONSTRAINT good_times check (StartTime < EndTime),
	CONSTRAINT num_of_places_on_Workshop check (NumOfPlaces > 0),
	CONSTRAINT price_of_workshop check (Price >= 0),
	CONSTRAINT workshop_and_day unique (StartTime,WorkshopName,DayID)
);

IF OBJECT_ID ('WorkshopsReservations','U') is not null
DROP Table WorkshopsReservations
GO
CREATE TABLE WorkshopsReservations (
    WorkshopsReservationID int IDENTITY(1, 1) NOT NULL,
    WorkshopID int  NOT NULL,
	ParticipantID int,
    DaysReservationID int  NOT NULL,
    IsCanceled bit default (0) NOT NULL,
    ReservationDate date  NOT NULL,
    PRIMARY KEY  (WorkshopsReservationID),
);

ALTER TABLE Firms ADD CONSTRAINT Customers_Firms
    FOREIGN KEY (CustomerID)
    REFERENCES Customers (CustomerID);

ALTER TABLE DaysReservations ADD CONSTRAINT DaysReservations_Customers
    FOREIGN KEY (CustomerID)
    REFERENCES Customers (CustomerID);

ALTER TABLE DaysReservations ADD CONSTRAINT DaysReservations_Days
    FOREIGN KEY (DayID)
    REFERENCES Days (DayID);

ALTER TABLE Days ADD CONSTRAINT Days_Conferences
    FOREIGN KEY (ConferenceID)
    REFERENCES Conferences (ConferenceID);

ALTER TABLE Participants ADD CONSTRAINT Participants_Customers
    FOREIGN KEY (CustomerID)
    REFERENCES Customers (CustomerID);

ALTER TABLE Payments ADD CONSTRAINT Payments_DaysReservations
    FOREIGN KEY (DaysReservationID)
    REFERENCES DaysReservations (DaysReservationID);

ALTER TABLE WorkshopsReservations ADD CONSTRAINT WorkshopsReservations_DaysReservations
    FOREIGN KEY (DaysReservationID)
    REFERENCES DaysReservations (DaysReservationID);

ALTER TABLE WorkshopsReservations ADD CONSTRAINT WorkshopsReservations_Workshops
    FOREIGN KEY (WorkshopID)
    REFERENCES Workshops (WorkshopID);

ALTER TABLE Workshops ADD CONSTRAINT Workshops_Days
    FOREIGN KEY (DayID)
    REFERENCES Days (DayID);

ALTER TABLE Participants ADD CONSTRAINT Participants_DaysReservation
    FOREIGN KEY (DaysReservationID)
    REFERENCES DaysReservations (DaysReservationID);

ALTER TABLE WorkshopsReservations ADD CONSTRAINT WorkshopsReservations_Participants
    FOREIGN KEY (ParticipantID)
    REFERENCES Participants (ParticipantID);


--FUNCTIONS	
IF OBJECT_ID('NumberOfFreePlaces_Day') is not null
DROP FUNCTION NumberOfFreePlaces_Day
GO
CREATE FUNCTION NumberOfFreePlaces_Day (@DayID int)
	RETURNS INT
	AS
	BEGIN
		DECLARE @Places int
		SET @Places = (select NumOfPlaces from Days where DayID = @DayID)
		DECLARE @Occupied int
		SET @Occupied = ( select count(NumOfNormalParticipants + NumOfStudents) from DaysReservations where DayID = @DayID and IsCanceled = 0)
		IF @Occupied is null
		BEGIN
			SET @Occupied = 0
		END
		RETURN (@Places - @Occupied)
	END
GO	


IF OBJECT_ID('NumberOfFreePlaces_Workshop') is not null
DROP FUNCTION NumberOfFreePlaces_Workshop
GO
CREATE FUNCTION NumberOfFreePlaces_Workshop (@WorkshopID int)
	RETURNS INT
	AS
	BEGIN
		DECLARE @Places int
		SET @Places = (select NumOfPlaces from Workshops where WorkshopID = @WorkshopID)
		DECLARE @Occupied int
		SET @Occupied = ( select count(*) from WorkshopsReservations where WorkshopID = @WorkshopID and IsCanceled = 0)
		IF @Occupied is null
		BEGIN
			SET @Occupied = 0
		END
		RETURN (@Places - @Occupied)
	END
GO


IF OBJECT_ID('isTheSameTimeOfWorkshops') is not null
DROP FUNCTION isTheSameTimeOfWorkshops
GO
CREATE FUNCTION isTheSameTimeOfWorkshops (@WorkshopID1 int, @WorkshopID2 int)
	RETURNS bit
	AS
	BEGIN
		DECLARE @StartTime1 time
		SET @StartTime1 = (select StartTime from Workshops where WorkshopID = @WorkshopID1)
		DECLARE @StartTime2 time
		SET @StartTime2 = (select StartTime from Workshops where WorkshopID = @WorkshopID2)
		DECLARE @EndTime1 time
		SET @EndTime1 = (select EndTime from Workshops where WorkshopID = @WorkshopID1)
		DECLARE @EndTime2 time
		SET @EndTime2 = (select EndTime from Workshops where WorkshopID = @WorkshopID2)
		DECLARE @Date1 date
		SET @Date1 = ( select Date from Days where DayID = ( select DayID from Workshops where WorkshopID = @WorkshopID1))
		DECLARE @Date2 date
		SET @Date2 = ( select Date from Days where DayID = ( select DayID from Workshops where WorkshopID = @WorkshopID2))
		IF @Date1 <> @Date2
		BEGIN
			RETURN 0
		END
		IF (@StartTime1 <= @StartTime2 and @StartTime2 <= @EndTime1) or (@StartTime2 <= @StartTime1 and @StartTime1 <= @EndTime2)
		BEGIN
			RETURN 1
		END
		RETURN 0
	END
GO


IF OBJECT_ID('idOfConferenceIncludingDate') is not null
DROP FUNCTION idOfConferenceIncludingDate
GO
CREATE FUNCTION idOfConferenceIncludingDate (@ConferenceName nvarchar(200), @Date date)
	RETURNS int
	AS
	BEGIN
		RETURN ( 
			select ConferenceID from Conferences 
			where ConferenceName = @ConferenceName and StartDate <= @Date and EndDate >= @Date
		)
	END
GO


IF OBJECT_ID('idOfCustomer') is not null
DROP FUNCTION idOfCustomer
GO
CREATE FUNCTION idOfCustomer (@CustomerName nvarchar(64))
	RETURNS int
	AS
	BEGIN
		Return ( 
			select CustomerID from Customers 
			where Name = @CustomerName )
	END
GO


IF OBJECT_ID('idOfDay') is not null
DROP FUNCTION idOfDay
GO
CREATE FUNCTION idOfDay (@ConferenceName nvarchar(200), @Date date)
	RETURNS int
	AS
	BEGIN
		Return ( 
			select DayID from Days
			where ConferenceID = dbo.idOfConferenceIncludingDate(@ConferenceName,@Date) and Date = @Date )
	END
GO


IF OBJECT_ID('idOfWorkshop') is not null
DROP FUNCTION idOfWorkshop
GO
CREATE FUNCTION idOfWorkshop (@WorkshopName nvarchar(200), @SatrtTime time, @DayID int)
	RETURNS int
	AS
	BEGIN
		Return ( 
			select WorkshopID from Workshops
			where WorkshopName = @WorkshopName and StartTime = @SatrtTime and DayID = @DayID)
	END
GO


IF OBJECT_ID('idOfDaysReservation') is not null
DROP FUNCTION idOfDaysReservation
GO
CREATE FUNCTION idOfDaysReservation (@CustomerID int, @DayID int)
	RETURNS int
	AS
	BEGIN
		Return ( 
			select DaysReservationID from DaysReservations
			where CustomerID = @CustomerID and DayID = @DayID and IsCanceled = 0)
	END
GO


IF OBJECT_ID('idOfParticipant') is not null
DROP FUNCTION idOfParticipant
GO
CREATE FUNCTION idOfParticipant (@CustomerID int, @FirstName nvarchar(32), @LastName nvarchar(32), @DaysReservationID int)
	RETURNS int
	AS
	BEGIN
		Return ( 
			select ParticipantID from Participants
			where CustomerID = @CustomerID and FirstName = @FirstName and LastName = @LastName and DaysReservationID = @DaysReservationID)
	END
GO


IF OBJECT_ID('countPriceOfDayResrvation') is not null
DROP FUNCTION countPriceOfDayResrvation
GO
CREATE FUNCTION countPriceOfDayResrvation (@DaysReservationID int)
	RETURNS money
	AS
	BEGIN
		DECLARE @WorkshopsPrice money
		SET @WorkshopsPrice = ( 
			select sum(Price) from Workshops 
			where WorkshopID in ( select WorkshopID from WorkshopsReservations where DaysReservationID = @DaysReservationID and IsCanceled = 0 )
		)
		DECLARE @DayPrice money
		SET @DayPrice = ( 
			select Price from Days 
			where DayID = ( 
				select DayID from DaysReservations 
				where DaysReservationID = @DaysReservationID and IsCanceled = 0
			)
		)
		DECLARE @NormalParticipantsPrice money
		SET @NormalParticipantsPrice = @DayPrice * ( 
			select NumOfNormalParticipants from DaysReservations 
			where DaysReservationID = @DaysReservationID
		)
		DECLARE @StudentParticipantsPrice money
		SET @StudentParticipantsPrice = @DayPrice * ( 
			select NumOfStudents from DaysReservations 
			where DaysReservationID = @DaysReservationID 
		) * 0.7
		SET @DayPrice = @StudentParticipantsPrice + @NormalParticipantsPrice
		DECLARE @ConferenceStartDay date
		SET @ConferenceStartDay = ( 
			select Date from Days 
			where DayID in ( 
				select DayID from DaysReservations 
				where DaysReservationID = @DaysReservationID
			)
		)
		DECLARE @DaysToConference int
		SET @DaysToConference = datediff(day,getdate(),@ConferenceStartDay)
		IF @DaysToConference > 30
		BEGIN 
			SET @DayPrice = @DayPrice * 0.7
		END
		ELSE IF @DaysToConference > 14
		BEGIN 
			SET @DayPrice = @DayPrice * 0.85
		END 
		IF @WorkshopsPrice is null
		BEGIN
			SET @WorkshopsPrice = 0
		END
		return @WorkshopsPrice + @DayPrice
	END
GO


--PROCEDURES
IF OBJECT_ID('AddDay') IS NOT NULL 
DROP PROC AddDay
GO
CREATE PROCEDURE AddDay
	@ConferenceName nvarchar(200),
	@Date date,
	@Price money,
	@NumOfPlaces int 
	AS
	BEGIN
		SET NOCOUNT ON;
		DECLARE @ConferenceID int
		SET @ConferenceID = dbo.idOfConferenceIncludingDate(@ConferenceName,@Date)
		IF @ConferenceID is not null
		BEGIN
			INSERT INTO Days(ConferenceID, Date, Price, NumOfPlaces)
			VALUES (@ConferenceID, @Date, @Price, @NumOfPlaces)
		END
	END
GO


IF OBJECT_ID('AddConference') IS NOT NULL 
DROP PROC AddConference
GO
CREATE PROCEDURE AddConference
	@ConferenceName nvarchar(200),
	@StartDate date,
	@EndDate date,
	@Country nvarchar(32),
	@City nvarchar(32),
	@Street nvarchar(32),
	@Price money,
	@NumOfPlaces int
	AS
	BEGIN
		BEGIN TRANSACTION
		SET NOCOUNT ON;
		INSERT INTO Conferences(ConferenceName, Country, City, Street, StartDate, EndDate)
		VALUES (@ConferenceName,@Country,@City,@Street,@StartDate,@EndDate)
		DECLARE @Date date
		SET @Date = @StartDate
		WHILE (@Date <= @EndDate)
		BEGIN
			exec AddDay @ConferenceName, @Date, @Price, @NumOfPlaces
			SET @Date = dateadd(day,1,@Date)
		END
		COMMIT TRANSACTION
	END
GO


IF OBJECT_ID('AddWorkshop') IS NOT NULL 
DROP PROC AddWorkshop
GO
CREATE PROCEDURE AddWorkshop
	@ConferenceName nvarchar(200),
	@Date date,
	@WorkshopName nvarchar(200),
	@StartTime time,
	@EndTime time,
	@Price money,
	@NumOfPlaces int
	AS
	BEGIN
		SET NOCOUNT ON;
		BEGIN TRY
		DECLARE @DayID int
		SET @DayID = dbo.idOfDay(@ConferenceName,@Date)
		IF @NumOfPlaces > ( 
			select NumOfPlaces from Days 
			where DayID = @DayID 
		)	
		BEGIN
			RAISERROR('Za duza liczba miejsc',16,2)
		END
		INSERT INTO Workshops(DayID, WorkshopName, StartTime, EndTime, Price, NumOfPlaces)
		VALUES (@DayID,@WorkshopName,@StartTime,@EndTime,@Price,@NumOfPlaces)
		END TRY
		BEGIN CATCH
		DECLARE @ErrorMsg nvarchar (2048)
			= 'Cannot add Workshop. Error message : '
				+ ERROR_MESSAGE () ;
		; THROW 50003 , @ErrorMsg ,1
		END CATCH
	END
GO


IF OBJECT_ID('AddWorkshopReservation') IS NOT NULL
DROP PROC AddWorkshopReservation
GO
CREATE PROCEDURE AddWorkshopReservation
	@CustomerName nvarchar(64),
	@ConferenceName nvarchar(200),
	@Date date,
	@WorkshopName nvarchar(200),
	@StartTime time
	AS
	BEGIN
		SET NOCOUNT ON;
		BEGIN TRY
		DECLARE @CustomerID int
		SET @CustomerID = dbo.idOfCustomer(@CustomerName)
		IF @CustomerID is null
		BEGIN RAISERROR('Nie znaleziono klienta',16,4) END

		DECLARE @DayID int
		SET @DayID = dbo.idOfDay(@ConferenceName,@Date)
		IF @DayID is null
		BEGIN RAISERROR('Nie znaleziono dnia konferencji',16,5) END

		DECLARE @DaysReservationID int
		SET @DaysReservationID = dbo.idOfDaysReservation(@CustomerID,@DayID)
		IF @DaysReservationID is null
		BEGIN RAISERROR('Nie znaleziono rezerwacji na podany dzieñ konferencji',16,6) END

		DECLARE @WorkshopID int
		SET @WorkshopID = dbo.idOfWorkshop(@WorkshopName,@StartTime,@DayID)
		IF @WorkshopID is null
		BEGIN RAISERROR('Nie znaleziono warsztatu',16,5) END

		DECLARE @FreePlaces int
		SET @FreePlaces = dbo.NumberOfFreePlaces_Workshop(@WorkshopID)
		IF ( @FreePlaces <= 0 )
		BEGIN RAISERROR('Brak wolnych miejsc na podany warsztatu',16,5) END

		IF exists ( 
			select * from Payments 
			where DaysReservationID = @DaysReservationID
		)
		BEGIN RAISERROR('Nie mo¿na dodaæ warsztatu do op³aconej ju¿ rezerwacji',16,5) END

		INSERT INTO WorkshopsReservations(WorkshopID, DaysReservationID, ReservationDate)
		VALUES (@WorkshopID, @DaysReservationID, getdate())
		END TRY
		BEGIN CATCH
		DECLARE @ErrorMsg nvarchar (2048)
			= 'Cannot add WorkshopReservation. Error message : '
				+ ERROR_MESSAGE () ;
		; THROW 50003 , @ErrorMsg ,1
		END CATCH
	END
GO


IF OBJECT_ID('CancelWorkshopReservation') IS NOT NULL
DROP PROC CancelWorkshopReservation
GO
CREATE PROCEDURE CancelWorkshopReservation
	@CustomerName nvarchar(64),
	@ConferenceName nvarchar(200),
	@Date date,
	@WorkshopName nvarchar(200),
	@StartTime time,
	@Firstname nvarchar(32),
	@Lastname nvarchar(32)
	AS
	BEGIN
		SET NOCOUNT ON;
		BEGIN TRY
		DECLARE @CustomerID int
		SET @CustomerID = dbo.idOfCustomer(@CustomerName)
		IF @CustomerID is null
		BEGIN RAISERROR('Nie znaleziono klienta',16,4) END

		DECLARE @DayID int
		SET @DayID = dbo.idOfDay(@ConferenceName,@Date)
		IF @DayID is null
		BEGIN RAISERROR('Nie znaleziono dnia konferencji',16,5) END

		DECLARE @DaysReservationID int
		SET @DaysReservationID = dbo.idOfDaysReservation(@CustomerID,@DayID)
		IF @DaysReservationID is null
		BEGIN RAISERROR('Nie znaleziono rezerwacji na podany dzieñ konferencji',16,5) END

		DECLARE @WorkshopID int
		SET @WorkshopID = dbo.idOfWorkshop(@WorkshopName,@StartTime,@DayID)
		IF @WorkshopID is null
		BEGIN RAISERROR('Nie znaleziono warsztatu',16,5) END

		DECLARE @ParticipantID int
		SET @ParticipantID = dbo.idOfParticipant(@CustomerID,@Firstname,@Lastname,@DaysReservationID)
		DECLARE @WorkshopReservatioID int
		IF @ParticipantID is not null
		BEGIN
			SET @WorkshopReservatioID = ( 
				select top 1 WorkshopsReservationID from WorkshopsReservations 
				where WorkshopID = @WorkshopID and DaysReservationID = @DaysReservationID and ParticipantID = @ParticipantID and IsCanceled = 0
			)
		END
		ELSE
		BEGIN
			SET @WorkshopReservatioID = ( 
				select top 1 WorkshopsReservationID from WorkshopsReservations 
				where WorkshopID = @WorkshopID and DaysReservationID = @DaysReservationID and ParticipantID is null and IsCanceled = 0
			)
		END

		UPDATE WorkshopsReservations
		SET IsCanceled = 1 where WorkshopsReservationID = @WorkshopReservatioID
		END TRY
		BEGIN CATCH
		DECLARE @ErrorMsg nvarchar (2048)
			= 'Cannot cancel WorkshopReservation. Error message : '
				+ ERROR_MESSAGE () ;
		; THROW 50003 , @ErrorMsg ,1
		END CATCH
	END
GO


IF OBJECT_ID('AddDaysReservation') IS NOT NULL
DROP PROC AddDaysReservation
GO
CREATE PROCEDURE AddDaysReservation
	@CustomerName nvarchar(64),
	@ConferenceName nvarchar(200),
	@Date date,
	@NumOfPlaces int,
	@NumOfStudents int
	AS
	BEGIN
		SET NOCOUNT ON;
		BEGIN TRY
		DECLARE @CustomerID int
		SET @CustomerID = dbo.idOfCustomer(@CustomerName)
		IF @CustomerID is null
		BEGIN RAISERROR('Nie znaleziono klienta',16,4) END

		DECLARE @DayID int
		SET @DayID = dbo.idOfDay(@ConferenceName,@Date)
		IF @DayID is null
		BEGIN RAISERROR('Nie znaleziono dnia konferencji',16,5) END

		if ( (select count(*) from DaysReservations where CustomerID = @CustomerID and DayID = @DayID and IsCanceled = 0) > 0 )
		BEGIN RAISERROR('Podany u¿ytkownik posiada ju¿ rezerwacje na podany dzieñ',16,5) END

		DECLARE @FreePlaces int
		SET @FreePlaces = dbo.NumberOfFreePlaces_Day(@DayID)
		IF ( @FreePlaces < (@NumOfPlaces + @NumOfStudents))
		BEGIN RAISERROR('Brak podanej iloœci miejsc na podany dzieñ konferencji',16,5) END

		INSERT INTO DaysReservations(CustomerID, DayID, ReservationDate,NumOfNormalParticipants,NumOfStudents)
		VALUES (@CustomerID, @DayID, getdate(),@NumOfPlaces,@NumOfStudents)
		END TRY
		BEGIN CATCH
		DECLARE @ErrorMsg nvarchar (2048)
			= 'Cannot add DaysReservation. Error message : '
				+ ERROR_MESSAGE () ;
		; THROW 50003 , @ErrorMsg ,1
		END CATCH
	END
GO


IF OBJECT_ID('CancelDaysReservation') IS NOT NULL
DROP PROC CancelDaysReservation
GO
CREATE PROCEDURE CancelDaysReservation
	@CustomerName nvarchar(64),
	@ConferenceName nvarchar(200),
	@Date date
	AS
	BEGIN
		SET NOCOUNT ON;
		BEGIN TRY
		DECLARE @CustomerID int
		SET @CustomerID = dbo.idOfCustomer(@CustomerName)
		IF @CustomerID is null
		BEGIN RAISERROR('Nie znaleziono klienta',16,4) END

		DECLARE @DayID int
		SET @DayID = dbo.idOfDay(@ConferenceName,@Date)
		IF @DayID is null
		BEGIN RAISERROR('Nie znaleziono dnia konferencji',16,5) END

		DECLARE @DaysReservationID int
		SET @DaysReservationID = dbo.idOfDaysReservation(@CustomerID,@DayID)
		IF @DaysReservationID is null
		BEGIN RAISERROR('Nie znaleziono rezerwacji na podany dzieñ konferencji',16,5) END

		UPDATE DaysReservations
		SET IsCanceled = 1 where DaysReservationID = @DaysReservationID
		END TRY
		BEGIN CATCH
		DECLARE @ErrorMsg nvarchar (2048)
			= 'Cannot cancel DaysReservation. Error message : '
				+ ERROR_MESSAGE () ;
		; THROW 50003 , @ErrorMsg ,1
		END CATCH
	END
GO


IF OBJECT_ID('AddParticipantToWorkshopsReservation') IS NOT NULL
DROP PROC AddParticipantToWorkshopsReservation
GO
CREATE PROCEDURE AddParticipantToWorkshopsReservation
	@CustomerName nvarchar(64),
	@Firstname nvarchar(32),
	@Lastname nvarchar(32),
	@ConferenceName nvarchar(200),
	@Date date,
	@WorkshopName nvarchar(200),
	@StartTime time
	AS
	BEGIN
		SET NOCOUNT ON;
		BEGIN TRY
		DECLARE @CustomerID int
		SET @CustomerID = dbo.idOfCustomer(@CustomerName)
		IF @CustomerID is null
		BEGIN RAISERROR('Nie znaleziono klienta',16,4) END

		DECLARE @DayID int
		SET @DayID = dbo.idOfDay(@ConferenceName,@Date)
		IF @DayID is null
		BEGIN RAISERROR('Nie znaleziono dnia konferencji',16,5) END

		DECLARE @DaysReservationID int
		SET @DaysReservationID = dbo.idOfDaysReservation(@CustomerID,@DayID)
		IF @DaysReservationID is null
		BEGIN RAISERROR('Nie znaleziono rezerwacji na podany dzieñ konferencji',16,6) END

		DECLARE @ParticipantID int
		SET @ParticipantID = dbo.idOfParticipant(@CustomerID,@Firstname,@Lastname,@DaysReservationID)
		IF @ParticipantID is null
		BEGIN RAISERROR('Nie znaleziono uczestnika',16,7) END

		DECLARE @WorkshopID int
		SET @WorkshopID = dbo.idOfWorkshop(@WorkshopName,@StartTime,@DayID)
		IF @WorkshopID is null
		BEGIN RAISERROR('Nie znaleziono warsztatu',16,5) END

		DECLARE @WorkshopReservationID int
		SET @WorkshopReservationID = ( 
			select top 1 WorkshopsReservationID from WorkshopsReservations 
			where WorkshopID = @WorkshopID and DaysReservationID = @DaysReservationID and ParticipantID is null and IsCanceled = 0
		)
		IF @WorkshopReservationID is null
		BEGIN RAISERROR('Nie znaleziono rezerwacji na podany warsztat',16,5) END

		IF exists ( 
			select * from WorkshopsReservations 
			where ParticipantID = @ParticipantID and dbo.isTheSameTimeOfWorkshops(WorkshopID,(select WorkshopID from WorkshopsReservations where WorkshopsReservationID = @WorkshopReservationID)) = 1 )
		BEGIN RAISERROR('Uczestnik jest juz zapisany na inny warsztat w tym samym czasie',16,5) END

		UPDATE WorkshopsReservations
		SET ParticipantID = @ParticipantID where WorkshopsReservationID = @WorkshopReservationID
		END TRY
		BEGIN CATCH
		DECLARE @ErrorMsg nvarchar (2048)
			= 'Cannot add ParticipantToWorkshopsReservation. Error message : '
				+ ERROR_MESSAGE () ;
		; THROW 50003 , @ErrorMsg ,1
		END CATCH
	END
GO


IF OBJECT_ID('DeleteParticipantFromWorkshopsReservation') IS NOT NULL
DROP PROC DeleteParticipantFromWorkshopsReservation
GO
CREATE PROCEDURE DeleteParticipantFromWorkshopsReservation
	@CustomerName nvarchar(64),
	@Firstname nvarchar(32),
	@Lastname nvarchar(32),
	@ConferenceName nvarchar(200),
	@Date date,
	@WorkshopName nvarchar(200),
	@StartTime time
	AS
	BEGIN
		SET NOCOUNT ON;
		BEGIN TRY
		DECLARE @CustomerID int
		SET @CustomerID = dbo.idOfCustomer(@CustomerName)
		IF @CustomerID is null
		BEGIN RAISERROR('Nie znaleziono klienta',16,4) END

		DECLARE @DayID int
		SET @DayID = dbo.idOfDay(@ConferenceName,@Date)
		IF @DayID is null
		BEGIN RAISERROR('Nie znaleziono dnia konferencji',16,5) END

		DECLARE @DaysReservationID int
		SET @DaysReservationID = dbo.idOfDaysReservation(@CustomerID,@DayID)
		IF @DaysReservationID is null
		BEGIN RAISERROR('Nie znaleziono rezerwacji na podany dzieñ konferencji',16,6) END

		DECLARE @ParticipantID int
		SET @ParticipantID = dbo.idOfParticipant(@CustomerID,@Firstname,@Lastname,@DaysReservationID)
		IF @ParticipantID is null
		BEGIN RAISERROR('Nie znaleziono uczestnika',16,7) END

		DECLARE @WorkshopID int
		SET @WorkshopID = dbo.idOfWorkshop(@WorkshopName,@StartTime,@DayID)
		IF @WorkshopID is null
		BEGIN RAISERROR('Nie znaleziono warsztatu',16,5) END

		DECLARE @WorkshopReservationID int
		SET @WorkshopReservationID = ( 
			select top 1 WorkshopsReservationID from WorkshopsReservations 
			where WorkshopID = @WorkshopID and DaysReservationID = @DaysReservationID and ParticipantID is null and IsCanceled = 0
		)
		IF @WorkshopReservationID is null
		BEGIN RAISERROR('Nie znaleziono rezerwacji na podany warsztat',16,5) END

		UPDATE WorkshopsReservations
		SET ParticipantID = null where WorkshopsReservationID = @WorkshopReservationID
		END TRY
		BEGIN CATCH
		DECLARE @ErrorMsg nvarchar (2048)
			= 'Cannot add ParticipantToWorkshopsReservation. Error message : '
				+ ERROR_MESSAGE () ;
		; THROW 50003 , @ErrorMsg ,1
		END CATCH
	END
GO


IF OBJECT_ID('AddParticipant') IS NOT NULL 
DROP PROC AddParticipant
GO
CREATE PROCEDURE AddParticipant
	@CustomerName nvarchar(64),
	@ConferenceName nvarchar(200),
	@Date date,
	@FirstName nvarchar(32),
	@LastName nvarchar(32),
	@StudentCardNr int
	AS
	BEGIN
		SET NOCOUNT ON;
		BEGIN TRY
		DECLARE @CustomerID int
		SET @CustomerID = dbo.idOfCustomer(@CustomerName)
		IF @CustomerID is null
		BEGIN RAISERROR('Nie znaleziono klienta',16,4) END

		DECLARE @DayID int
		SET @DayID = dbo.idOfDay(@ConferenceName,@Date)
		IF @DayID is null
		BEGIN RAISERROR('Nie znaleziono dnia konferencji',16,5) END

		DECLARE @DaysReservationID int
		SET @DaysReservationID = dbo.idOfDaysReservation(@CustomerID,@DayID)
		IF @DaysReservationID is null
		BEGIN RAISERROR('Nie znaleziono rezerwacji na podany dzieñ konferencji',16,5) END

		DECLARE @NumOfParticipants int
		IF @StudentCardNr is null
		BEGIN
			SET @NumOfParticipants = ( 
				select NumOfNormalParticipants from DaysReservations 
				where DaysReservationID = @DaysReservationID 
			) - ( 
				select count(*) from Participants 
				where DaysReservationID = @DaysReservationID and StudentCardNr is null
			)
			IF @NumOfParticipants < 1
			BEGIN RAISERROR('Rezerwacja zawiera juz pe³n¹ listê uczestników',16,8) END
		END
		ELSE
		BEGIN
			SET @NumOfParticipants = ( 
				select NumOfStudents from DaysReservations 
				where DaysReservationID = @DaysReservationID 
			) - ( 
				select count(*) from Participants 
				where DaysReservationID = @DaysReservationID and StudentCardNr is not null
			)
			IF @NumOfParticipants < 1
			BEGIN RAISERROR('Rezerwacja zawiera juz pe³n¹ listê uczestników',16,8) END
		END
		IF exists ( select * from Participants where FirstName = @FirstName and LastName = @LastName and CustomerID = @CustomerID and DaysReservationID = @DaysReservationID )
		BEGIN RAISERROR('Rezerwacja zawiera juz uczestnika o podanych danych',16,8) END

		INSERT INTO Participants(CustomerID, FirstName, LastName, StudentCardNr, DaysReservationID)
		VALUES (@CustomerID,@FirstName,@LastName,@StudentCardNr,@DaysReservationID)
		END TRY
		BEGIN CATCH
		DECLARE @ErrorMsg nvarchar (2048)
			= 'Cannot add Participant. Error message : '
				+ ERROR_MESSAGE () ;
		; THROW 50003 , @ErrorMsg ,1
		END CATCH
	END
GO


IF OBJECT_ID('AddCustomer') IS NOT NULL 
DROP PROC AddCustomer
GO
CREATE PROCEDURE AddCustomer
	@Name nvarchar(64),
	@Country nvarchar(32),
	@City nvarchar(32),
	@Street nvarchar(32),
	@Phone nvarchar(32),
	@Email nvarchar(32)
	AS
	BEGIN
		SET NOCOUNT ON;
		INSERT INTO Customers(Name,Country,City,Street,Phone,Email)
		VALUES (@Name,@Country,@City,@Street,@Phone,@Email)
	END
GO


IF OBJECT_ID('AddFirm') IS NOT NULL
DROP PROC AddFirm
GO
CREATE PROCEDURE AddFirm
	@CustomerName nvarchar(64),
	@NIP bigint,
	@Regon bigint
	AS
	BEGIN
		SET NOCOUNT ON;
		BEGIN TRY
		DECLARE @CustomerID int
		SET @CustomerID = dbo.idOfCustomer(@CustomerName)
		IF @CustomerID is null
		BEGIN RAISERROR('Nie znaleziono klienta',16,4) END

		INSERT INTO Firms(CustomerID,NIP,REGON)
		VALUES (@CustomerID,@NIP,@Regon)
		END TRY
		BEGIN CATCH
		DECLARE @ErrorMsg nvarchar (2048)
			= 'Cannot add Firm. Error message : '
				+ ERROR_MESSAGE () ;
		; THROW 50003 , @ErrorMsg ,1
		END CATCH
	END
GO


IF OBJECT_ID('CancelUnpaidReservation') IS NOT NULL 
DROP PROC CancelUnpaidReservation
GO
CREATE PROCEDURE CancelUnpaidReservation
	AS
	BEGIN
		SET NOCOUNT ON;
		UPDATE DaysReservations
		SET IsCanceled = 1 where IsCanceled = 0 and datediff(day,ReservationDate,getdate()) >= 7
	END
GO


IF OBJECT_ID('ChangeNumberOfDayPlaces') IS NOT NULL 
DROP PROC ChangeNumberOfDayPlaces
GO
CREATE PROCEDURE ChangeNumberOfDayPlaces
	@ConferenceName nvarchar(200),
	@Date date,
	@NewNumOfPlaces int 
	AS
	BEGIN
		SET NOCOUNT ON;
		BEGIN TRY
		DECLARE @DayID int
		SET @DayID = dbo.idOfDay(@ConferenceName,@Date)
		IF @DayID is null
		BEGIN RAISERROR('Nie znaleziono dnia konferencji',16,5) END

		UPDATE Days
		SET NumOfPlaces = @NewNumOfPlaces where DayID = @DayID
		END TRY
		BEGIN CATCH
		DECLARE @ErrorMsg nvarchar (2048)
			= 'Cannot change NumberOfDayPlaces. Error message : '
				+ ERROR_MESSAGE () ;
		; THROW 50003 , @ErrorMsg ,1
		END CATCH
	END
GO


IF OBJECT_ID('ChangeNumberOfWorkshopsPlaces') IS NOT NULL 
DROP PROC ChangeNumberOfWorkshopsPlaces
GO
CREATE PROCEDURE ChangeNumberOfWorkshopsPlaces
	@ConferenceName nvarchar(200),
	@Date date,
	@WorkshopName nvarchar(200),
	@StartTime time,
	@NewNumOfPlaces int
	AS
	BEGIN
		SET NOCOUNT ON;
		BEGIN TRY
		DECLARE @ConferenceID int
		SET @ConferenceID = dbo.idOfConferenceIncludingDate(@ConferenceName,@Date)

		DECLARE @DayID int
		SET @DayID = dbo.idOfDay(@ConferenceName,@Date)
		IF @DayID is null
		BEGIN RAISERROR('Nie znaleziono dnia konferencji',16,5) END

		UPDATE Workshops
		SET NumOfPlaces = @NewNumOfPlaces where DayID = @DayID and WorkshopName = @WorkshopName and StartTime = @StartTime
		END TRY
		BEGIN CATCH
		DECLARE @ErrorMsg nvarchar (2048)
			= 'Cannot change NumberOfWorkshopsPlaces. Error message : '
				+ ERROR_MESSAGE () ;
		; THROW 50003 , @ErrorMsg ,1
		END CATCH
	END
GO


IF OBJECT_ID('AddPaymentForDay') IS NOT NULL 
DROP PROC AddPaymentForDay
GO
CREATE PROCEDURE AddPaymentForDay
	@CustomerName nvarchar(64),
	@ConferenceName nvarchar(200),
	@Date date
	AS
	BEGIN
		SET NOCOUNT ON;
		BEGIN TRY
		DECLARE @CustomerID int
		SET @CustomerID = dbo.idOfCustomer(@CustomerName)
		IF @CustomerID is null
		BEGIN RAISERROR('Nie znaleziono klienta',16,4) END

		DECLARE @ConferenceID int
		SET @ConferenceID = dbo.idOfConferenceIncludingDate(@ConferenceName,@Date)
		IF @ConferenceID is null
		BEGIN RAISERROR('Nie znaleziono Konferencji',16,9) END

		DECLARE @DayID int
		SET @DayID = dbo.idOfDay(@ConferenceName,@Date)
		IF @DayID is null
		BEGIN RAISERROR('Nie znaleziono dnia konferencji',16,5) END

		DECLARE @DaysReservationID int
		SET @DaysReservationID = dbo.idOfDaysReservation(@CustomerID,@DayID)
		IF @DaysReservationID is null
		BEGIN RAISERROR('Nie znaleziono rezerwacji na podany dzieñ konferencji',16,5) END

		IF exists ( select * from Payments where DaysReservationID = @DaysReservationID )
		BEGIN RAISERROR('P³atnoœæ na podany dzieñ konferencji ju¿ istneieje',16,5) END

		DECLARE @Price money
		SET @Price = dbo.countPriceOfDayResrvation(@DaysReservationID)

		INSERT INTO Payments(DaysReservationID,value,Date)
		VALUES (@DaysReservationID,@Price,getdate())
		END TRY
		BEGIN CATCH
		DECLARE @ErrorMsg nvarchar (2048)
			= 'Cannot add PaymentForDay. Error message : '
				+ ERROR_MESSAGE () ;
		; THROW 50003 , @ErrorMsg ,1
		END CATCH
	END
GO


IF OBJECT_ID('AddPaymentForConference') IS NOT NULL
DROP PROC AddPaymentForConference
GO
CREATE PROCEDURE AddPaymentForConference
	@CustomerName nvarchar(64),
	@ConferenceName nvarchar(200),
	@StartDate date
	AS
	BEGIN
		SET NOCOUNT ON;
		DECLARE @EndDate date
		SET @EndDate = ( select EndDate from Conferences where ConferenceID = dbo.idOfConferenceIncludingDate(@ConferenceName,@StartDate)) 
		DECLARE @Date date
		SET @Date = @StartDate
		BEGIN TRANSACTION
			WHILE (@Date <= @EndDate)
			BEGIN
				BEGIN TRY
					exec AddPaymentForDay @CustomerName, @ConferenceName, @Date
					SET @Date = dateadd(day,1,@Date)
				END TRY
				BEGIN CATCH
					IF ERROR_MESSAGE() <> 'Cannot add PaymentForDay. Error message : Nie znaleziono rezerwacji na podany dzieñ konferencji'
					BEGIN
						DECLARE @ErrorMsg nvarchar (2048)
						= 'Cannot add PaymentForConference. Error message : '
						+ ERROR_MESSAGE () ;
						ROLLBACK TRANSACTION;
						THROW 50003 , @ErrorMsg ,1
					END
					ELSE
					BEGIN
						SET @Date = dateadd(day,1,@Date)
					END
				END CATCH
			END
		COMMIT TRANSACTION
	END
GO


--TRIGGERS
IF OBJECT_ID('CancelWorkshopsReservations') is not null
DROP TRIGGER CancelWorkshopsReservations
GO
CREATE TRIGGER CancelWorkshopsReservations
	ON DaysReservations
	FOR UPDATE
	AS
	BEGIN
		IF UPDATE(IsCanceled)
		BEGIN
			DECLARE @DaysReservationID AS int
			SET @DaysReservationID = (SELECT DaysReservationID FROM INSERTED)
			
			UPDATE WorkshopsReservations 
			SET IsCanceled = 1, ParticipantID = null
			WHERE DaysReservationID = @DaysReservationID and IsCanceled = 0
		END
	END
GO


IF OBJECT_ID('DeleteParticipantsWithoutActualReservation') is not null
DROP TRIGGER DeleteParticipantsWithoutActualReservation
GO
CREATE TRIGGER DeleteParticipantsWithoutActualReservation
	ON DaysReservations
	FOR UPDATE
	AS
	BEGIN
		IF UPDATE(IsCanceled)
		BEGIN
			DECLARE @DaysReservationID AS int
			SET @DaysReservationID = (SELECT DaysReservationID FROM INSERTED)
			DELETE Participants
			WHERE DaysReservationID = @DaysReservationID
		END
	END
GO


IF OBJECT_ID('checkDate') is not null
DROP TRIGGER checkDate
GO
CREATE TRIGGER checkDate 
	ON Conferences
	AFTER INSERT,UPDATE 
	AS 
	BEGIN 
		SET NOCOUNT ON; 
		DECLARE @Date date = (SELECT StartDate FROM inserted) 
		IF((DATEDIFF(day,GETDATE(),@Date) <= 0)) 
		BEGIN ;
			THROW 52000, 'Podana data jest z przesz³oœci', 2
		END 
	END
GO


IF OBJECT_ID('WorkshopsInTheSameTime') is not null
DROP TRIGGER WorkshopsInTheSameTime
GO
CREATE TRIGGER WorkshopsInTheSameTime 
	ON Workshops
	AFTER INSERT 
	AS 
	BEGIN 
		SET NOCOUNT ON;
		DECLARE @WorkshopID int
		SET @WorkshopID= ( select WorkshopID from INSERTED)
		DECLARE @WorkshopName nvarchar(200)
		SET @WorkshopName = ( select WorkshopName from INSERTED)
		IF exists (
			select * from Workshops as w
			where WorkshopName = @WorkshopName and WorkshopID <> @WorkshopID and dbo.isTheSameTimeOfWorkshops(WorkshopID,@WorkshopID) = 1 
		) 
		BEGIN;
			THROW 52000, 'Istniej¹ ju¿ takie warsztaty w podanym czasie', 2
		END 
	END
GO


IF OBJECT_ID('CancelPaidDayReservation') is not null
DROP TRIGGER CancelPaidDayReservation
GO
CREATE TRIGGER CancelPaidDayReservation
	ON DaysReservations
	FOR UPDATE
	AS
	BEGIN
		IF UPDATE(IsCanceled)
		BEGIN
			DECLARE @DaysReservationID AS int
			SET @DaysReservationID = (SELECT DaysReservationID FROM INSERTED)
			IF exists ( 
				select * from Payments 
				where DaysReservationID = @DaysReservationID
			)
			BEGIN;
				THROW 52000, 'Rezerwacja zosta³a ju¿ op³acona', 2 
			END	
		END
	END
GO


IF OBJECT_ID('CancelPaidWorkshopReservation') is not null
DROP TRIGGER CancelPaidWorkshopReservation
GO
CREATE TRIGGER CancelPaidWorkshopReservation
	ON WorkshopsReservations
	FOR UPDATE
	AS
	BEGIN
		IF UPDATE(IsCanceled)
		BEGIN
			DECLARE @DaysReservationID AS int
			SET @DaysReservationID = (SELECT top 1 DaysReservationID FROM INSERTED)
			IF exists ( 
				select * from Payments 
				where DaysReservationID = @DaysReservationID
			)
			BEGIN;
				THROW 52000, 'Rezerwacja zosta³a ju¿ op³acona', 2 
			END	
		END
	END
GO


IF OBJECT_ID('WorkshopWithBiggerNumberOfPlaces') is not null
DROP TRIGGER WorkshopWithBiggerNumberOfPlaces
GO
CREATE TRIGGER WorkshopWithBiggerNumberOfPlaces
	ON Days
	FOR UPDATE
	AS
	BEGIN
		IF UPDATE(NumOfPlaces)
		BEGIN
			DECLARE @DayID int
			SET @DayID = ( select DayID from inserted )
			DECLARE @NewNumOfPlaces int
			SET @NewNumOfPlaces = ( select NumOfPlaces from inserted )
			DECLARE @BiggestNumOfPlaces int
			SET @BiggestNumOfPlaces = ( 
				select max(NumOfPlaces) from Workshops 
				where DayID = @DayID
			)
			IF @NewNumOfPlaces < @BiggestNumOfPlaces
			BEGIN;
				THROW 52000, 'Dzieñ zawiera warsztaty z wiêksz¹ iloœci¹ miejsc ni¿ podana liczba', 2 
			END	
		END
	END
GO


IF OBJECT_ID('DayWithSmallerNumberOfPlaces') is not null
DROP TRIGGER DayWithSmallerNumberOfPlaces
GO
CREATE TRIGGER DayWithSmallerNumberOfPlaces
	ON Workshops
	FOR UPDATE
	AS
	BEGIN
		IF UPDATE(NumOfPlaces)
		BEGIN
			DECLARE @DayID int
			SET @DayID = ( select DayID from inserted )
			DECLARE @NewNumOfPlaces int
			SET @NewNumOfPlaces = ( select NumOfPlaces from inserted )
			IF @NewNumOfPlaces > ( select NumOfPlaces from Days where DayID = @DayID )
			BEGIN;
				THROW 52000, 'Dzieñ ma mniejsza iloœæ miejsc niz podana liczba', 2 
			END	
		END
	END
GO

IF OBJECT_ID('MoreDayReservationsThanNewNumOfPlaces') is not null
DROP TRIGGER MoreDayReservationsThanNewNumOfPlaces
GO
CREATE TRIGGER MoreDayReservationsThanNewNumOfPlaces
	ON Days
	FOR UPDATE
	AS
	BEGIN
		IF UPDATE(NumOfPlaces)
		BEGIN
			DECLARE @DayID int
			SET @DayID = ( select DayID from inserted )
			DECLARE @NewNumOfPlaces int
			SET @NewNumOfPlaces = ( select NumOfPlaces from inserted )
			IF @NewNumOfPlaces < (select SUM(NumOfNormalParticipants + NumOfStudents) from DaysReservations where DayID = @DayID and IsCanceled = 0)
			BEGIN;
				THROW 52000, 'Na ten dzieñ jest wiecej z³o¿onych rezerwacji ni¿ podana liczba miejsc', 2 
			END	
		END
	END
GO


IF OBJECT_ID('MoreWorkshopReservationsThanNewNumOfPlaces') is not null
DROP TRIGGER MoreWorkshopReservationsThanNewNumOfPlaces
GO
CREATE TRIGGER MoreWorkshopReservationsThanNewNumOfPlaces
	ON Workshops
	FOR UPDATE
	AS
	BEGIN
		IF UPDATE(NumOfPlaces)
		BEGIN
			DECLARE @WorkshopID int
			SET @WorkshopID = ( select WorkshopID from inserted )
			DECLARE @NewNumOfPlaces int
			SET @NewNumOfPlaces = ( select NumOfPlaces from inserted )
			IF @NewNumOfPlaces < ( select COUNT(*) from WorkshopsReservations where WorkshopID = @WorkshopID and IsCanceled = 0 )
			BEGIN;
				THROW 52000, 'Na ten warsztat jest wiecej z³o¿onych rezerwacji ni¿ podana liczba miejsc', 2 
			END	
		END
	END
GO


--VIEWS
IF OBJECT_ID('Payments_hist') is not null
DROP VIEW Payments_hist
GO
CREATE VIEW Payments_hist AS
select PaymentID, c.Name, ConferenceName, d.Date, value, p.Date as 'Date of payment'
from Payments as p
join DaysReservations as dr on p.DaysReservationID = dr.DaysReservationID
join Customers as c on c.CustomerID = dr.CustomerID
join Days as d on d.DayID = dr.DayID
join Conferences as con on d.ConferenceID = con.ConferenceID
GO


IF OBJECT_ID('Available_workshops') is not null
DROP VIEW Available_workshops
GO
CREATE VIEW Available_workshops AS
select WorkshopName, w.StartTime, d.Date, w.EndTime, w.Price, c.ConferenceName
from Workshops as w
join Days as d on d.DayID = w.DayID
join Conferences as c on c.ConferenceID = d.DayID
where w.NumOfPlaces > ( select count(*) from WorkshopsReservations where WorkshopID = w.WorkshopID) and d.Date > getdate()
GO


IF OBJECT_ID('workshops_participants') is not null
DROP VIEW workshops_participants
GO
CREATE VIEW workshops_participants AS
SELECT wr.WorkshopID, WorkshopName, Date, FirstName, LastName,p.ParticipantID
FROM WorkshopsReservations AS wr
JOIN Workshops AS w ON wr.WorkshopID = w.WorkshopID
JOIN Days AS d ON d.DayID=w.DayID
JOIN Participants AS p ON p.ParticipantID = wr.ParticipantID
GO


IF OBJECT_ID('Conferences_participants') is not null
DROP VIEW Conferences_participants
GO
CREATE VIEW Conferences_participants AS
SELECT DISTINCT ConferenceName, StartDate, EndDate, FirstName, LastName
FROM DaysReservations as dr
JOIN Days AS d on d.DayID=dr.DayID
JOIN Conferences as c on d.ConferenceID = c.ConferenceID
JOIN Participants as p on p.DaysReservationID=dr.DaysReservationID
GO


IF OBJECT_ID('Count_Reservation') is not null
DROP VIEW Count_Reservation
GO
CREATE VIEW Count_Reservation AS
select c.CustomerID, Name,	SUM (dr.NumOfNormalParticipants+NumOfStudents) as How
FROM Customers as c
JOIN DaysReservations as dr on dr.CustomerID=c.CustomerID
GROUP BY c.CustomerID, Name
GO


IF OBJECT_ID('not_pay') is not null
DROP VIEW not_pay
GO
CREATE VIEW not_pay AS
select c.CustomerID, Name
FROM Customers as c
JOIN DaysReservations as dr on dr.CustomerID=c.CustomerID
where not DaysReservationID in (select DaysReservationID from Payments)
GO


IF OBJECT_ID('Workshops_list') is not null
DROP VIEW Workshops_list
GO
CREATE VIEW Workshops_list AS
SELECT Date, ConferenceName, WorkshopName, StartTime, EndTime, w.Price, w.NumOfPlaces
FROM Workshops as w
JOIN Days as d ON d.DayID=w.DayID
JOIN Conferences as c ON c.ConferenceID=d.ConferenceID
GO


IF OBJECT_ID('Customers_view') is not null
DROP VIEW Customers_view
GO
CREATE VIEW Customers_view AS
SELECT Name,Country, City, Street, Phone, Email, NIP, REGON
FROM Customers as c
LEFT JOIN Firms as f on c.CustomerID=f.CustomerID
GO


IF OBJECT_ID('Participants_view') is not null
DROP VIEW Participants_view
GO
CREATE VIEW Participants_view AS
SELECT distinct Name as 'Zarejestrowany przez', FirstName,LastName, StudentCardNr
FROM Participants as p
JOIN  Customers as c ON c.CustomerID = p.CustomerID
GO


IF OBJECT_ID('Workshops_top') is not null
DROP VIEW Workshops_top
GO
CREATE VIEW Workshops_top AS
SELECT top 20 WorkShopName,  count (WorkShopsReservationID) as ile
FROM Workshops as w
JOIN WorkshopsReservations as wr on wr.WorkshopID=w.WorkshopID
GROUP BY WorkshopName
ORDER BY ile DESC 
GO


IF OBJECT_ID('Conference_top') is not null
DROP VIEW Conference_top
GO
CREATE VIEW Conference_top AS
SELECT top 20 ConferenceName, StartDate, count (DaysReservationID) as ile
FROM Conferences as c
JOIN Days as d on d.ConferenceID=c.ConferenceID
JOIN DaysReservations as dr on d.DayID=dr.DayID

GROUP BY StartDate,ConferenceName
ORDER BY ile DESC 
GO