
USE master;
GO

IF DB_ID('TourismDB') IS NOT NULL
BEGIN
    ALTER DATABASE TourismDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE TourismDB;
END
GO

CREATE DATABASE TourismDB;
GO
USE TourismDB;
GO

CREATE TABLE Users (
    id BIGINT PRIMARY KEY IDENTITY(1,1),
    name NVARCHAR(255) NOT NULL,
    email NVARCHAR(255) UNIQUE NOT NULL,
    password NVARCHAR(255) NOT NULL,
    phone NVARCHAR(20) UNIQUE,
    user_type NVARCHAR(20) CHECK (user_type IN ('Tourist', 'Guide', 'Agency', 'Admin','host')),
    registration_date DATETIME2 DEFAULT GETDATE(),
    status NVARCHAR(20) CHECK (status IN ('Active', 'Suspended', 'Banned'))
);
CREATE NONCLUSTERED INDEX idx_user_email ON Users(email);

CREATE TABLE Destinations (
    id BIGINT PRIMARY KEY IDENTITY(1,1),
    name NVARCHAR(255) NOT NULL,
    country NVARCHAR(100) NOT NULL,
    city NVARCHAR(100) NOT NULL,
    description NVARCHAR(MAX),
    popular BIT DEFAULT 0
);
CREATE NONCLUSTERED INDEX idx_destination_city ON Destinations(city);

CREATE TABLE Tours (
    id BIGINT PRIMARY KEY IDENTITY(1,1),
    name NVARCHAR(255) NOT NULL,
    destination_id BIGINT,
    price DECIMAL(12,2) NOT NULL,
    capacity INT NOT NULL,
    description NVARCHAR(MAX),
    created_at DATETIME2 DEFAULT GETDATE(),
    CONSTRAINT FK_Tours_Destinations FOREIGN KEY (destination_id) REFERENCES Destinations(id)
);
CREATE NONCLUSTERED INDEX idx_tour_search ON Tours(destination_id, price);

CREATE TABLE Accommodations (
    id BIGINT PRIMARY KEY IDENTITY(1,1),
    name NVARCHAR(255) NOT NULL,
    type NVARCHAR(20) CHECK (type IN ('EcoLodge', 'Hotel', 'Hostel', 'Camp')),
    owner_id BIGINT,
    city NVARCHAR(100) NOT NULL,
    address NVARCHAR(MAX),
    description NVARCHAR(MAX),
    amenities NVARCHAR(MAX),
    price_per_night DECIMAL(12,2),
    capacity INT,
    contact_phone NVARCHAR(20),
    rating_average DECIMAL(3,1),
    created_at DATETIME2 DEFAULT GETDATE(),
    status NVARCHAR(20) CHECK (status IN ('Active', 'Inactive', 'Pending')),
    CONSTRAINT FK_Accommodations_Users FOREIGN KEY (owner_id) REFERENCES Users(id)
);
CREATE NONCLUSTERED INDEX idx_accommodation_search ON Accommodations(city, type, price_per_night);

CREATE TABLE AccommodationAvailability (
    id BIGINT PRIMARY KEY IDENTITY(1,1),
    accommodation_id BIGINT,
    available_from DATETIME2 NOT NULL,
    available_to DATETIME2 NOT NULL,
    available_capacity INT NOT NULL,
    CONSTRAINT FK_AccommodationAvailability_Accommodations FOREIGN KEY (accommodation_id) REFERENCES Accommodations(id) ON DELETE CASCADE
);

CREATE TABLE Images (
    id BIGINT PRIMARY KEY IDENTITY(1,1),
    target_type NVARCHAR(20) CHECK (target_type IN ('Tour', 'Accommodation')),
    target_id BIGINT,
    image_url NVARCHAR(255) NOT NULL,
    caption NVARCHAR(255),
    created_at DATETIME2 DEFAULT GETDATE()
);
CREATE NONCLUSTERED INDEX idx_images_target ON Images(target_type, target_id);

CREATE TABLE DescriptionsTranslations (
    id BIGINT PRIMARY KEY IDENTITY(1,1),
    target_type NVARCHAR(20) CHECK (target_type IN ('Tour', 'Accommodation')),
    target_id BIGINT,
    language_code NVARCHAR(10) NOT NULL,
    description NVARCHAR(MAX),
    amenities NVARCHAR(MAX)
);

CREATE TABLE Articles (
    id BIGINT PRIMARY KEY IDENTITY(1,1),
    title NVARCHAR(255) NOT NULL,
    content NVARCHAR(MAX) NOT NULL,
    city NVARCHAR(100),
    created_at DATETIME2 DEFAULT GETDATE()
);
CREATE NONCLUSTERED INDEX idx_article_city ON Articles(city);

CREATE TABLE CancellationPolicies (
    id BIGINT PRIMARY KEY IDENTITY(1,1),
    accommodation_id BIGINT NULL,
    tour_id BIGINT NULL,
    hours_before INT NOT NULL,
    refund_percent DECIMAL(5,2) NOT NULL,
    CONSTRAINT FK_CancellationPolicies_Accommodations FOREIGN KEY (accommodation_id) REFERENCES Accommodations(id),
    CONSTRAINT FK_CancellationPolicies_Tours FOREIGN KEY (tour_id) REFERENCES Tours(id),
    CONSTRAINT CHK_Cancellation_Type CHECK (accommodation_id IS NOT NULL OR tour_id IS NOT NULL)
);

CREATE TABLE TourInstances (
    id BIGINT PRIMARY KEY IDENTITY(1,1),
    tour_id BIGINT,
    start_date DATETIME2 NOT NULL,
    end_date DATETIME2 NOT NULL,
    status NVARCHAR(20) CHECK (status IN ('Scheduled', 'Ongoing', 'Completed', 'Cancelled')),
    CONSTRAINT FK_TourInstances_Tours FOREIGN KEY (tour_id) REFERENCES Tours(id)
);
CREATE NONCLUSTERED INDEX idx_tourinstance_dates ON TourInstances(start_date, end_date);

CREATE TABLE Reservations (
    id BIGINT PRIMARY KEY IDENTITY(1,1),
    user_id BIGINT,
    tour_instance_id BIGINT NULL,
    accommodation_id BIGINT NULL,
    check_in_date DATETIME2 NOT NULL,
    check_out_date DATETIME2 NOT NULL,
    total_cost DECIMAL(12,2),
    status NVARCHAR(20) CHECK (status IN ('Pending', 'Confirmed', 'Cancelled')),
    num_guests INT,
    CONSTRAINT FK_Reservations_Users FOREIGN KEY (user_id) REFERENCES Users(id),
    CONSTRAINT FK_Reservations_TourInstances FOREIGN KEY (tour_instance_id) REFERENCES TourInstances(id),
    CONSTRAINT FK_Reservations_Accommodations FOREIGN KEY (accommodation_id) REFERENCES Accommodations(id),
    CONSTRAINT CHK_Reservation_Type CHECK (tour_instance_id IS NOT NULL OR accommodation_id IS NOT NULL)
);

CREATE TABLE GuideAgencyRelation (
    id BIGINT PRIMARY KEY IDENTITY(1,1),
    guide_id BIGINT,
    agency_id BIGINT,
    start_date DATETIME2 NOT NULL,
    end_date DATETIME2,
    CONSTRAINT FK_GuideAgencyRelation_Users_Guide FOREIGN KEY (guide_id) REFERENCES Users(id),
    CONSTRAINT FK_GuideAgencyRelation_Users_Agency FOREIGN KEY (agency_id) REFERENCES Users(id)
);

CREATE TABLE GuideAvailability (
    id BIGINT PRIMARY KEY IDENTITY(1,1),
    guide_id BIGINT,
    available_from DATETIME2 NOT NULL,
    available_to DATETIME2 NOT NULL,
    CONSTRAINT FK_GuideAvailability_Users FOREIGN KEY (guide_id) REFERENCES Users(id)
);

CREATE TABLE TourInstanceGuides (
    id BIGINT PRIMARY KEY IDENTITY(1,1),
    tour_instance_id BIGINT,
    guide_id BIGINT,
    CONSTRAINT FK_TourInstanceGuides_TourInstances FOREIGN KEY (tour_instance_id) REFERENCES TourInstances(id),
    CONSTRAINT FK_TourInstanceGuides_Users FOREIGN KEY (guide_id) REFERENCES Users(id)
);

CREATE TABLE Payments (
    id BIGINT PRIMARY KEY IDENTITY(1,1),
    reservation_id BIGINT,
    amount DECIMAL(12,2),
    status NVARCHAR(20) CHECK (status IN ('Pending', 'Completed', 'Failed')),
    payment_date DATETIME2 DEFAULT GETDATE(),
    CONSTRAINT FK_Payments_Reservations FOREIGN KEY (reservation_id) REFERENCES Reservations(id)
);

CREATE TABLE Reviews (
    id BIGINT PRIMARY KEY IDENTITY(1,1),
    user_id BIGINT,
    tour_instance_id BIGINT NULL,
    accommodation_id BIGINT NULL,
    rating INT CHECK (rating BETWEEN 1 AND 5),
    comment NVARCHAR(MAX),
    review_date DATETIME2 DEFAULT GETDATE(),
    status NVARCHAR(20) CHECK (status IN ('Approved', 'Pending', 'Rejected')),
    CONSTRAINT FK_Reviews_Users FOREIGN KEY (user_id) REFERENCES Users(id),
    CONSTRAINT FK_Reviews_TourInstances FOREIGN KEY (tour_instance_id) REFERENCES TourInstances(id),
    CONSTRAINT FK_Reviews_Accommodations FOREIGN KEY (accommodation_id) REFERENCES Accommodations(id),
    CONSTRAINT CHK_Review_Type CHECK (tour_instance_id IS NOT NULL OR accommodation_id IS NOT NULL)
);

CREATE TABLE Discounts (
    id BIGINT PRIMARY KEY IDENTITY(1,1),
    tour_id BIGINT NULL,
    accommodation_id BIGINT NULL,
    discount_code NVARCHAR(50) UNIQUE,
    discount_percent DECIMAL(5,2),
    valid_from DATETIME2 NOT NULL,
    valid_to DATETIME2 NOT NULL,
    CONSTRAINT FK_Discounts_Tours FOREIGN KEY (tour_id) REFERENCES Tours(id),
    CONSTRAINT FK_Discounts_Accommodations FOREIGN KEY (accommodation_id) REFERENCES Accommodations(id),
    CONSTRAINT CHK_Discount_Type CHECK (tour_id IS NOT NULL OR accommodation_id IS NOT NULL)
);

CREATE TABLE Reports (
    id BIGINT PRIMARY KEY IDENTITY(1,1),
    user_id BIGINT,
    target_id BIGINT,
    reason NVARCHAR(MAX),
    status NVARCHAR(20) CHECK (status IN ('Pending', 'Resolved', 'Rejected')),
    created_at DATETIME2 DEFAULT GETDATE(),
    CONSTRAINT FK_Reports_Users FOREIGN KEY (user_id) REFERENCES Users(id)
);

CREATE TABLE Wallets (
    id BIGINT PRIMARY KEY IDENTITY(1,1),
    user_id BIGINT,
    balance DECIMAL(12,2) DEFAULT 0,
    last_updated DATETIME2 DEFAULT GETDATE(),
    CONSTRAINT FK_Wallets_Users FOREIGN KEY (user_id) REFERENCES Users(id)
);

CREATE TABLE PromoCodes (
    id BIGINT PRIMARY KEY IDENTITY(1,1),
    code NVARCHAR(50) UNIQUE NOT NULL,
    target_type NVARCHAR(20) CHECK (target_type IN ('Tour', 'Accommodation', 'Both')),
    target_id BIGINT NULL,
    discount_percent DECIMAL(5,2),
    max_usage INT,
    used_count INT DEFAULT 0,
    valid_from DATETIME2 NOT NULL,
    valid_to DATETIME2 NOT NULL,
    status NVARCHAR(20) CHECK (status IN ('Active', 'Expired'))
);

CREATE TABLE SystemSettings (
    id BIGINT PRIMARY KEY IDENTITY(1,1),
    [key] NVARCHAR(255) UNIQUE NOT NULL,
    value NVARCHAR(MAX),
    updated_at DATETIME2 DEFAULT GETDATE()
);

CREATE TABLE SupportTickets (
    id BIGINT PRIMARY KEY IDENTITY(1,1),
    user_id BIGINT,
    subject NVARCHAR(255) NOT NULL,
    description NVARCHAR(MAX),
    status NVARCHAR(20) CHECK (status IN ('Open', 'InProgress', 'Closed')),
    created_at DATETIME2 DEFAULT GETDATE(),
    updated_at DATETIME2 DEFAULT GETDATE(),
    CONSTRAINT FK_SupportTickets_Users FOREIGN KEY (user_id) REFERENCES Users(id)
);

GO
CREATE TRIGGER UpdateSupportTicketsUpdatedAt
ON SupportTickets
AFTER UPDATE
AS
BEGIN
    UPDATE SupportTickets
    SET updated_at = GETDATE()
    FROM SupportTickets
    INNER JOIN inserted ON SupportTickets.id = inserted.id;
END;
GO

CREATE TABLE MultiRatings (
    id BIGINT PRIMARY KEY IDENTITY(1,1),
    user_id BIGINT,
    target_type NVARCHAR(20) CHECK (target_type IN ('Tour', 'Accommodation', 'Guide', 'Agency')),
    target_id BIGINT,
    guide_quality INT NULL CHECK (guide_quality BETWEEN 1 AND 5),
    tour_program_quality INT NULL CHECK (tour_program_quality BETWEEN 1 AND 5),
    accommodation_quality INT NULL CHECK (accommodation_quality BETWEEN 1 AND 5),
    service_quality INT NULL CHECK (service_quality BETWEEN 1 AND 5),
    overall_satisfaction INT CHECK (overall_satisfaction BETWEEN 1 AND 5),
    comment NVARCHAR(MAX),
    created_at DATETIME2 DEFAULT GETDATE(),
    CONSTRAINT FK_MultiRatings_Users FOREIGN KEY (user_id) REFERENCES Users(id)
);
CREATE NONCLUSTERED INDEX idx_multiratings_target ON MultiRatings(target_type, target_id);

CREATE TABLE ExtraServices (
    id BIGINT PRIMARY KEY IDENTITY(1,1),
    name NVARCHAR(255) NOT NULL,
    description NVARCHAR(MAX),
    price DECIMAL(12,2),
    available_for NVARCHAR(20) CHECK (available_for IN ('Tour', 'Accommodation')),
    created_at DATETIME2 DEFAULT GETDATE()
);

CREATE TABLE TourExtraServices (
    id BIGINT PRIMARY KEY IDENTITY(1,1),
    tour_id BIGINT,
    extra_service_id BIGINT,
    CONSTRAINT FK_TourExtraServices_Tours FOREIGN KEY (tour_id) REFERENCES Tours(id),
    CONSTRAINT FK_TourExtraServices_ExtraServices FOREIGN KEY (extra_service_id) REFERENCES ExtraServices(id)
);

CREATE TABLE Referrals (
    id BIGINT PRIMARY KEY IDENTITY(1,1),
    referrer_id BIGINT,
    referred_email NVARCHAR(255) UNIQUE NOT NULL,
    referral_code NVARCHAR(50) UNIQUE NOT NULL,
    reward_amount DECIMAL(12,2),
    status NVARCHAR(20) CHECK (status IN ('Pending', 'Rewarded', 'Expired')),
    created_at DATETIME2 DEFAULT GETDATE(),
    CONSTRAINT FK_Referrals_Users FOREIGN KEY (referrer_id) REFERENCES Users(id)
);

CREATE TABLE Admins (
    id BIGINT PRIMARY KEY IDENTITY(1,1),
    user_id BIGINT,
    role NVARCHAR(20) CHECK (role IN ('SuperAdmin', 'SupportAdmin', 'ContentAdmin', 'FinanceAdmin')),
    created_at DATETIME2 DEFAULT GETDATE(),
    status NVARCHAR(20) CHECK (status IN ('Active', 'Inactive')),
    CONSTRAINT FK_Admins_Users FOREIGN KEY (user_id) REFERENCES Users(id)
);

CREATE TABLE AdminPermissions (
    id BIGINT PRIMARY KEY IDENTITY(1,1),
    admin_id BIGINT,
    module_name NVARCHAR(20) CHECK (module_name IN ('Users', 'Tours', 'TourInstances', 'Reservations', 'Payments', 'Reviews', 'Reports', 'Accommodations', 'PromoCodes', 'SupportTickets', 'Notifications', 'Wallets', 'SystemSettings')),
    permission_level NVARCHAR(20) CHECK (permission_level IN ('ReadOnly', 'FullAccess', 'NoAccess')),
    created_at DATETIME2 DEFAULT GETDATE(),
    CONSTRAINT FK_AdminPermissions_Admins FOREIGN KEY (admin_id) REFERENCES Admins(id)
);

CREATE TABLE Notifications (
    id BIGINT PRIMARY KEY IDENTITY(1,1),
    user_id BIGINT,
    title NVARCHAR(255) NOT NULL,
    message NVARCHAR(MAX),
    is_read BIT DEFAULT 0,
    created_at DATETIME2 DEFAULT GETDATE(),
    CONSTRAINT FK_Notifications_Users FOREIGN KEY (user_id) REFERENCES Users(id)
);

SELECT name AS TABLE_NAME
FROM sys.tables
WHERE type = 'U' AND SCHEMA_NAME(schema_id) = 'dbo';
GO
