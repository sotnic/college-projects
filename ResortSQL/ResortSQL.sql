---- Drop Tables
DROP TABLE BillPayment CASCADE CONSTRAINTS;
DROP TABLE Booking CASCADE CONSTRAINTS;
DROP TABLE Feedback CASCADE CONSTRAINTS;
DROP TABLE Guest CASCADE CONSTRAINTS;
DROP TABLE PaymentType CASCADE CONSTRAINTS;
DROP TABLE Resort CASCADE CONSTRAINTS;
DROP TABLE Resort_Address CASCADE CONSTRAINTS;
DROP TABLE Rooms CASCADE CONSTRAINTS;
DROP TABLE RoomStatus CASCADE CONSTRAINTS;
DROP TABLE RoomType CASCADE CONSTRAINTS;

DROP SEQUENCE Resort_Seq;
DROP SEQUENCE Room_Seq;

---- Tables Creation
CREATE TABLE BillPayment (
  BillPaymentId number(10) GENERATED AS IDENTITY,
  BookingId     number(10) NOT NULL,
  PaymentType   number(10) NOT NULL,
  CardNumber    number(16),
  ExpireDate    Date,
  AmountPaid    number(10) NOT NULL,
  PRIMARY KEY (BillPaymentId)
);

CREATE TABLE Booking (
  BookingId     number(10) GENERATED AS IDENTITY,
  GuestGuestId  number(10)    NOT NULL,
  RoomId        number(10)    NOT NULL,
  BookingDate   date          NOT NULL,
  EndDate       date          NOT NULL,
  DaysOfStay    number(10),
  BookingStatus varchar2(30),
  AmountDue     number(10, 2) NOT NULL,
  PRIMARY KEY (BookingId)
);

CREATE TABLE Feedback (
  FeedBackId   number(10) GENERATED AS IDENTITY,
  GuestGuestId number(10) NOT NULL,
  Feedback     varchar2(255),
  Rating       number(2),
  PRIMARY KEY (FeedBackId)
);

CREATE TABLE Guest (
  GuestId     number(10) GENERATED AS IDENTITY,
  FName       varchar2(30)  NOT NULL,
  Lname       varchar2(30)  NOT NULL,
  Phone       number(12)    NOT NULL,
  Email       varchar2(255) NOT NULL,
  DateOfBirth date,
  PRIMARY KEY (GuestId)
);

CREATE TABLE PaymentType (
  PaymentTypeId          number(10) GENERATED AS IDENTITY,
  PaymentTypeDescription varchar2(50) NOT NULL,
  PRIMARY KEY (PaymentTypeId)
);

CREATE TABLE Resort (
  ResortId       number(10)    NOT NULL,
  Resort_Name    varchar2(30)  NOT NULL,
  Contact_Person varchar2(30)  NOT NULL,
  Phone          number(12)    NOT NULL,
  eMail          varchar2(100) NOT NULL,
  URL            varchar2(255) NOT NULL,
  CONSTRAINT ResortId
  PRIMARY KEY (ResortId)
);

CREATE TABLE Resort_Address (
  AddressId        number(10) GENERATED AS IDENTITY,
  ResortId         number(10)    NOT NULL,
  "Street Address" varchar2(255) NOT NULL,
  City             varchar2(255) NOT NULL,
  Province         varchar2(255) NOT NULL,
  POSTALCODE       varchar2(10)  NOT NULL,
  CONSTRAINT Resort_Address
  PRIMARY KEY (AddressId)
);

CREATE TABLE Rooms (
  RoomId             number(10)    NOT NULL,
  RoomTypeId         number(10)    NOT NULL,
  ResortId           number(10)    NOT NULL,
  RoomStatusStatusId number(10)    NOT NULL,
  RoomName           varchar2(255) NOT NULL,
  Floor              varchar2(10)  NOT NULL,
  PricePerNight      number(10, 2) NOT NULL,
  Description        varchar2(255),
  PRIMARY KEY (RoomId)
);

CREATE TABLE RoomStatus (
  StatusId    number(10) GENERATED AS IDENTITY,
  Status      varchar2(50)  NOT NULL,
  Description varchar2(255) NOT NULL,
  PRIMARY KEY (StatusId)
);

CREATE TABLE RoomType (
  RoomTypeId      number(10) GENERATED AS IDENTITY,
  RoomType        varchar2(100) NOT NULL,
  RoomDescription varchar2(255) NOT NULL,
  RoomRate        number(10)    NOT NULL,
  PRIMARY KEY (RoomTypeId)
);

----Add constraints
ALTER TABLE Rooms
  ADD CONSTRAINT RoomType_Room_FK FOREIGN KEY (RoomTypeId) REFERENCES RoomType (RoomTypeId);
ALTER TABLE Rooms
  ADD CONSTRAINT Resort_Room_FK FOREIGN KEY (ResortId) REFERENCES Resort (ResortId);
ALTER TABLE Booking
  ADD CONSTRAINT Guest_Booking_FK FOREIGN KEY (GuestGuestId) REFERENCES Guest (GuestId);
ALTER TABLE Feedback
  ADD CONSTRAINT Guest_FeedBack_FK FOREIGN KEY (GuestGuestId) REFERENCES Guest (GuestId);
ALTER TABLE BillPayment
  ADD CONSTRAINT PaymentType_BillPayment_FK FOREIGN KEY (PaymentType) REFERENCES PaymentType (PaymentTypeId);
ALTER TABLE Resort_Address
  ADD CONSTRAINT Resort_ResortAddress_FK FOREIGN KEY (ResortId) REFERENCES Resort (ResortId);
ALTER TABLE Booking
  ADD CONSTRAINT Room_Booking_FK FOREIGN KEY (RoomId) REFERENCES Rooms (RoomId);
ALTER TABLE Rooms
  ADD CONSTRAINT RoomStatus_Room_FK FOREIGN KEY (RoomStatusStatusId) REFERENCES RoomStatus (StatusId);
ALTER TABLE BillPayment
  ADD CONSTRAINT Booking_BIllPayment_FK FOREIGN KEY (BookingId) REFERENCES Booking (BookingId);

----Sequence Creation
CREATE SEQUENCE Resort_Seq
  START WITH 1000
  INCREMENT BY 1
  NOCACHE
  NOCYCLE;

CREATE SEQUENCE Room_Seq
  START WITH 1
  INCREMENT BY 1
  NOCACHE
  NOCYCLE;

--Index Creation
--------------------------------------------Make more indexes
CREATE INDEX rooms_resort_roomtype_idx
  ON Rooms (ResortId, RoomTypeId);

CREATE INDEX resort_address_city_idx
  ON Resort_Address (City);

CREATE INDEX booking_idx
  ON Booking(GuestGuestId, BookingStatus);
--------------------------------------------------------------------------Trigger Creation
DROP TRIGGER billpayment_trg;

-- CREATE OR REPLACE TRIGGER billpayment_trg
--   AFTER DELETE
--   ON BillPayment
-- --   FOR EACH ROW
--   REFERENCING new AS newROW
-- --   WHEN (BILL_PAYMENT_FUN(newROW.BookingId) >= 0)
--   BEGIN
--       UPDATE Booking SET BookingStatus = 'FULLY PAID' WHERE Booking.BookingId = newROW.;
--   END;

CREATE OR REPLACE TRIGGER billpayment_trg
  AFTER INSERT
  ON BillPayment

----Function Creation

--This function is used to calculate total payment for room rental for a specific dates
CREATE OR REPLACE FUNCTION BOOKING_PAYMENT_FUN(room_no IN NUMBER, startDate IN DATE, endDate IN DATE)
  RETURN number IS
  total number := 0;
  BEGIN
    SELECT TO_NUMBER(Rooms.PricePerNight * (TO_DATE(endDate) - TO_DATE(startDate))) into total
    FROM Rooms
    WHERE Rooms.RoomId = room_no;
    RETURN total;
  END;

--This function is calculation total amount paid for a specific booking
CREATE OR REPLACE FUNCTION BILL_PAYMENT_FUN(operationId in NUMBER)
  RETURN number IS
  total number := 0;
  BEGIN
    SELECT TO_NUMBER(SUM(BillPayment.AmountPaid) - Booking.AmountDue) into total
    from BillPayment
           JOIN Booking ON Booking.BookingId = BillPayment.BookingId
    WHERE BillPayment.BookingId = operationId
    GROUP BY BillPayment.AmountPaid,Booking.AmountDue ;
    RETURN total;
  END;

--   --Testing
--   DELETE from BillPayment where BookingId = 1;
--
-- insert into BillPayment (BookingId, PaymentType, AmountPaid)
-- values (1, 1, 1000);
--
-- select  * from BillPayment;
-- select * from Booking;

----Procedure Creation

--This procedure is changing a status of a specific room of a hotel.
CREATE OR REPLACE PROCEDURE UPDATE_ROOM_STATUS_PROC(
p_resort_id IN ROOMS.RESORTID%TYPE,
p_room_name IN ROOMS.ROOMNAME%TYPE,
p_status_id IN ROOMSTATUS.STATUSID%TYPE
)
IS
  BEGIN
    UPDATE ROOMS SET ROOMSTATUSSTATUSID = p_status_id WHERE ROOMNAME = p_room_name AND RESORTID = p_resort_id ;
  END;

--   CREATE OR REPLACE PROCEDURE
----Table population

--Room Type
INSERT INTO RoomType (RoomType, RoomDescription, RoomRate)
VALUES ('Single', 'A room assigned to one person.', '3');

INSERT INTO RoomType (RoomType, RoomDescription, RoomRate)
VALUES ('Double', 'A room assigned to two people.', '3');

INSERT INTO RoomType (RoomType, RoomDescription, RoomRate)
VALUES ('Triple', 'A room assigned to three person.', '3');

INSERT INTO RoomType (RoomType, RoomDescription, RoomRate)
VALUES ('Quad', 'A room assigned to four person.', '3');

INSERT INTO RoomType (RoomType, RoomDescription, RoomRate)
VALUES ('Queen', 'A room with a queen-sized bed.', '4');

INSERT INTO RoomType (RoomType, RoomDescription, RoomRate)
VALUES ('King', 'A room with a king-sized bed.', '4');

INSERT INTO RoomType (RoomType, RoomDescription, RoomRate)
VALUES ('Twin', 'A room with two beds.', '3');

INSERT INTO RoomType (RoomType, RoomDescription, RoomRate)
VALUES ('Double-double', 'A room with two double or queen beds.', '4');

INSERT INTO RoomType (RoomType, RoomDescription, RoomRate)
VALUES ('Studio',
        'A room with a studio bed – a couch that can be converted into a bed. May also have an additional bed.',
        '4');

INSERT INTO RoomType (RoomType, RoomDescription, RoomRate)
VALUES ('Executive suite', 'One of the most fine looking and comfortable suits', '5');

INSERT INTO RoomType (RoomType, RoomDescription, RoomRate)
VALUES ('Presidential suite',
        'wo-bedroom suite, surrounded by local artisanal décor and spectacular views at every turn. Perched up on our fourth floor with extra-tall ceilings and an abundance of natural light.',
        '5');

--Room Status
INSERT INTO RoomStatus (Status, Description)
VALUES ('Vacant', 'The room has been cleaned and inspected and is ready for an arriving guest.');

INSERT INTO RoomStatus (Status, Description)
VALUES ('Occupied', 'A guest is currently occupied in the room');

INSERT INTO RoomStatus (Status, Description)
VALUES ('On-Change', 'The guest has departed, but the room has not yet been cleaned and ready for sale.');

INSERT INTO RoomStatus (Status, Description)
VALUES ('Cleaning in progress', 'Room attendant is currently cleaning this room.');

INSERT INTO RoomStatus (Status, Description)
VALUES ('On-Queue', 'Guest has arrived at the hotel, but the room assigned is not yet ready.');

INSERT INTO RoomStatus (Status, Description)
VALUES ('Out of Order',
        'Rooms kept under out of order are not sellable and these rooms are deducted from the hotel''s inventory.');

INSERT INTO RoomStatus (Status, Description)
VALUES ('Out of Service', 'Temporary not in use.');

INSERT INTO RoomStatus (Status, Description)
VALUES ('Late Check out',
        'he guest has requested and is being allowed to check out later than the normal / standard departure time of the hotel.');

INSERT INTO RoomStatus (Status, Description)
VALUES ('Check-Out', 'The guest has settled his or her account, returned the room keys, and left the hotel');

select * from RoomStatus;
--Resort
INSERT INTO Resort (ResortId, Resort_Name, Contact_Person, Phone, eMail, URL)
VALUES (RESORT_SEQ.nextval,
        'Hilton Toronto',
        'Gor Ezikyan',
        6473252525,
        'HolidayScarborough@hollidayInn.ca',
        'https://www3.hilton.com/en/hotels/ontario/hilton-toronto-TORHIHH/index.html');

INSERT INTO Resort (ResortId, Resort_Name, Contact_Person, Phone, eMail, URL)
VALUES (RESORT_SEQ.nextval,
        'Holiday Inn Express',
        'Jake Norman',
        4164399666,
        'HolidayScarborough@hollidayInn.ca',
        'https://www.ihg.com/holidayinnexpress/hotels/us/en/scarborough/yyzex/hoteldetail');

INSERT INTO Resort (ResortId, Resort_Name, Contact_Person, Phone, eMail, URL)
VALUES (RESORT_SEQ.nextval,
        'Fairmont Royal York',
        'Peter Parker',
        4163728372,
        'FairmontRoyale@gmail.com',
        'https://www.fairmont.com/royal-york-toronto/?genid=tripadvisor_ryh_ta_business_advantage&utm_source=tripadvisor&utm_medium=paid_referrer&utm_content=ryh&utm_campaign=ta_business_advantage');

INSERT INTO Resort (ResortId, Resort_Name, Contact_Person, Phone, eMail, URL)
VALUES (RESORT_SEQ.nextval,
        'RADISSON ADMIRAL HOTEL',
        'Mike Callahan',
        4169877878,
        'RadissonHarbourToronto@radison.com',
        'https://www.radisson.com/toronto-hotel-on-m5j2n5/ontoront');

INSERT INTO Resort (ResortId, Resort_Name, Contact_Person, Phone, eMail, URL)
VALUES (RESORT_SEQ.nextval,
        'Centennial Place',
        'Mike Jagger',
        416777777,
        'CentennailPlace@centennial.ca',
        'https://www.centennial-place.ca');

--Resort Address
INSERT INTO Resort_Address (ResortId, "Street Address", City, Province, POSTALCODE)
VALUES (1000, '145 RICHMOND STREET WEST', 'Toronto', 'ON', 'M5H 2L2');

INSERT INTO Resort_Address (ResortId, "Street Address", City, Province, POSTALCODE)
VALUES (1001, '930 Progress Ave', 'Scarborough', 'ON', 'M1G 3T1');

INSERT INTO Resort_Address (ResortId, "Street Address", City, Province, POSTALCODE)
VALUES (1002, '100 Front Street W ', 'Toronto', 'ON', 'M5J 1E3');

INSERT INTO Resort_Address (ResortId, "Street Address", City, Province, POSTALCODE)
VALUES (1003, '249 Queen''s Quay West', 'Toronto', 'ON', 'N5J 2N5');

INSERT INTO Resort_Address (ResortId, "Street Address", City, Province, POSTALCODE)
VALUES (1004, '937 Progress Ave', 'Scarborough', 'ON', 'M1G 3T8');

--Rooms
INSERT INTO Rooms (RoomId, RoomTypeId, ResortId, RoomStatusStatusId, RoomName, Floor, PricePerNight)
VALUES (Room_Seq.nextval, 1, 1000, 1, '101', '1', 90);

INSERT INTO Rooms (RoomId, RoomTypeId, ResortId, RoomStatusStatusId, RoomName, Floor, PricePerNight)
VALUES (Room_Seq.nextval, 2, 1000, 1, '102', '1', 100);

INSERT INTO Rooms (RoomId, RoomTypeId, ResortId, RoomStatusStatusId, RoomName, Floor, PricePerNight)
VALUES (Room_Seq.nextval, 3, 1000, 1, '103', '1', 120);

INSERT INTO Rooms (RoomId, RoomTypeId, ResortId, RoomStatusStatusId, RoomName, Floor, PricePerNight)
VALUES (Room_Seq.nextval, 4, 1000, 1, '104', '1', 150);

INSERT INTO Rooms (RoomId, RoomTypeId, ResortId, RoomStatusStatusId, RoomName, Floor, PricePerNight)
VALUES (Room_Seq.nextval, 5, 1000, 1, '301', '3', 220);

INSERT INTO Rooms (RoomId, RoomTypeId, ResortId, RoomStatusStatusId, RoomName, Floor, PricePerNight)
VALUES (Room_Seq.nextval, 6, 1000, 1, '302', '3', 250);

INSERT INTO Rooms (RoomId, RoomTypeId, ResortId, RoomStatusStatusId, RoomName, Floor, PricePerNight)
VALUES (Room_Seq.nextval, 7, 1000, 1, '201', '2', 200);

INSERT INTO Rooms (RoomId, RoomTypeId, ResortId, RoomStatusStatusId, RoomName, Floor, PricePerNight)
VALUES (Room_Seq.nextval, 8, 1000, 1, '202', '2', 200);

INSERT INTO Rooms (RoomId, RoomTypeId, ResortId, RoomStatusStatusId, RoomName, Floor, PricePerNight)
VALUES (Room_Seq.nextval, 10, 1000, 1, '501', '5', 350);

INSERT INTO Rooms (RoomId, RoomTypeId, ResortId, RoomStatusStatusId, RoomName, Floor, PricePerNight)
VALUES (Room_Seq.nextval, 11, 1000, 1, '601', '6', 400);

-- Guest
INSERT INTO Guest (FName, Lname, Phone, Email, DateOfBirth)
VALUES ('Artur', 'Fundukyan', '6473252525', 'Afunduky@my.centennialcollege.ca', '15-APR-98');

INSERT INTO Guest (FName, Lname, Phone, Email, DateOfBirth)
VALUES ('Nicole', 'Lawsone', '6478766773', 'Lawson@gmail.com', '20-MAY-90');

INSERT INTO Guest (FName, Lname, Phone, Email, DateOfBirth)
VALUES ('James', 'Hetfield', '325252525', 'Hetfield@metallica.com', '3-aug-63');

INSERT INTO Guest (FName, Lname, Phone, Email, DateOfBirth)
VALUES ('Marilyn', 'Manson', '100000001', 'Manson@gmail.com', '5-Jan-69');

INSERT INTO Guest (FName, Lname, Phone, Email, DateOfBirth)
VALUES ('Saul', 'Hudson', '7777777777', 'Slash@myself.com', '23-Jul-65');

INSERT INTO Guest (FName, Lname, Phone, Email, DateOfBirth)
VALUES ('Michael', 'Jackson', '100101010', 'JAckson@gmail.com', '23-SEp-1965');

INSERT INTO Guest (FName, Lname, Phone, Email, DateOfBirth)
VALUES ('Steaven', 'Portman', '6473564352', 'Portman@gmail.com', '15-MAY-73');

INSERT INTO Guest (FName, Lname, Phone, Email, DateOfBirth)
VALUES ('Kevin', 'Spade', '5647352632', 'spade@kevin.com', '3-sep-71');

INSERT INTO Guest (FName, Lname, Phone, Email, DateOfBirth)
VALUES ('Stone', 'Island', '380505616851', 'IslandStone@mail.ru', '8-Mar-89');

INSERT INTO Guest (FName, Lname, Phone, Email, DateOfBirth)
VALUES ('Volodimyr', 'Leninskiy', '+380503239999', 'Lenin@mycountry.ru', '10-sep-88');

--Feedback
INSERT INTO Feedback (GuestGuestId, Feedback, Rating)
values (1, 'This hotel was one of the most amazing places I''ve ever visited!', 10);
INSERT INTO Feedback (GuestGuestId, Feedback, Rating)
values (2, 'THis room was better than I expected, but not the best experience', 7);
INSERT INTO Feedback (GuestGuestId, Feedback, Rating)
values (3, 'I don'' know what to say...', 5);
INSERT INTO Feedback (GuestGuestId, Feedback, Rating)
values (4, 'Hilton hotel was as good as usual!', 10);
INSERT INTO Feedback (GuestGuestId, Feedback, Rating)
values (5, 'This was my first king room type and I loved it so much...', 10);
INSERT INTO Feedback (GuestGuestId, Feedback, Rating)
values (6, 'The only problem was in price of drinks, but everything else was awesome.', 9);
INSERT INTO Feedback (GuestGuestId, Feedback, Rating)
values (7, 'As an administrator of another Hilton hotel I have noticed some issues.', 8);
INSERT INTO Feedback (GuestGuestId, Feedback, Rating)
values (8, 'I am so thankful to hotel administrator that made our journey just incredible...', 10);
INSERT INTO Feedback (GuestGuestId, Feedback, Rating)
values (9, 'More words... More words... More words...', 8);
INSERT INTO Feedback (GuestGuestId, Feedback, Rating)
values (10, 'Feedback? 5 stars out of 5.', 10);

--PaymentType
INSERT INTO PaymentType (PaymentTypeDescription)
values ('Visa');
INSERT INTO PaymentType (PaymentTypeDescription)
values ('Master Card');
INSERT INTO PaymentType (PaymentTypeDescription)
values ('Amex');
INSERT INTO PaymentType (PaymentTypeDescription)
values ('Bank Transfer');
INSERT INTO PaymentType (PaymentTypeDescription)
values ('Cash');

--Booking
INSERT INTO Booking (GuestGuestId, RoomId, BookingDate, EndDate, AmountDue)
values (1, 9, '10-mar-2018', '30-mar-2018', BOOKING_PAYMENT_FUN(9, '10-mar-2018', '20-mar-2018'));

INSERT INTO Booking (GuestGuestId, RoomId, BookingDate, EndDate, AmountDue)
values (2, 3, '10-apr-2018', '15-apr-2018', BOOKING_PAYMENT_FUN(3, '10-apr-2018', '15-apr-2018'));

INSERT INTO Booking (GuestGuestId, RoomId, BookingDate, EndDate, AmountDue)
values (3, 4, '23-jun-2018', '15-jul-2018', BOOKING_PAYMENT_FUN(4, '23-jun-2018', '15-jul-2018'));

INSERT INTO Booking (GuestGuestId, RoomId, BookingDate, EndDate, AmountDue)
values (4, 10, '17-sep-2018', '23-sep-2018', BOOKING_PAYMENT_FUN(10, '17-sep-2018', '23-sep-2018'));

INSERT INTO Booking (GuestGuestId, RoomId, BookingDate, EndDate, AmountDue)
values (5, 7, '2-oct-2018', '5-oct-2018', BOOKING_PAYMENT_FUN(7, '5-oct-2018', '7-oct-2018'));

INSERT INTO Booking (GuestGuestId, RoomId, BookingDate, EndDate, AmountDue)
values (6, 6, '10-mar-2018', '30-mar-2018', BOOKING_PAYMENT_FUN(6, '10-mar-2018', '20-mar-2018'));

INSERT INTO Booking (GuestGuestId, RoomId, BookingDate, EndDate, AmountDue)
values (7, 7, '1-jan-2017', '30-jan-2017', BOOKING_PAYMENT_FUN(7, '1-jan-2017', '30-jan-2017'));

INSERT INTO Booking (GuestGuestId, RoomId, BookingDate, EndDate, AmountDue)
values (8, 1, '1-mar-2018', '2-mar-2018', BOOKING_PAYMENT_FUN(1, '1-mar-2018', '2-mar-2018'));

INSERT INTO Booking (GuestGuestId, RoomId, BookingDate, EndDate, AmountDue)
values (9, 3, '10-may-2018', '20-jun-2018', BOOKING_PAYMENT_FUN(3, '10-may-2018', '20-jun-2018'));

INSERT INTO Booking (GuestGuestId, RoomId, BookingDate, EndDate, AmountDue)
values (10, 7, '8-dec-2018', '13-dec-2018', BOOKING_PAYMENT_FUN(7, '8-dec-2018', '13-dec-2018'));

COMMIT;

