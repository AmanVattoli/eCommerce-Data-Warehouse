CREATE DATABASE sales;

CREATE SCHEMA sales_schema;

-- Dimension Table: DimDate
CREATE TABLE DimDates (
    DateID INT PRIMARY KEY,
    Date DATE,
    DayOfWeek VARCHAR(10),
    DayName VARCHAR(10),
    Month INT,
    MonthName VARCHAR(20),
    Quarter INT,
    Year INT,
    IsWeekend BOOLEAN
);

-- Dimension Table: DimLoyaltyInfo
CREATE TABLE DimLoyaltyInfo (
    LoyaltyProgramID INT PRIMARY KEY,
    ProgramName VARCHAR(100),
    ProgramTier VARCHAR(50),
    PointsAccrued INT
);

-- Dimension Table: DimCustomers
CREATE TABLE DimCustomers (
    CustomerID INT PRIMARY KEY AUTOINCREMENT START 1 INCREMENT 1,
    FirstName VARCHAR(50),
    LastName VARCHAR(50),
    Gender VARCHAR(20),
    DateOfBirth DATE,
    Email VARCHAR(100),
    PhoneNumber VARCHAR(20),
    Address VARCHAR(255),
    City VARCHAR(50),
    State VARCHAR(50),
    ZipCode VARCHAR(10),
    Country VARCHAR(100),
    LoyaltyProgramID INT,
    FOREIGN KEY (LoyaltyProgramID) REFERENCES DimLoyaltyInfo(LoyaltyProgramID)
);

-- Dimension Table: DimProducts
CREATE TABLE DimProducts (
    ProductID INT PRIMARY KEY AUTOINCREMENT START 1 INCREMENT 1,
    ProductName VARCHAR(100),
    Category VARCHAR(50),
    Brand VARCHAR(50),
    UnitPrice DECIMAL(10, 2)
);

-- Dimension Table: DimStores
CREATE TABLE DimStores (
    StoreID INT PRIMARY KEY AUTOINCREMENT START 1 INCREMENT 1,
    StoreName VARCHAR(100),
    StoreType VARCHAR(50),
    StoreOpeningDate DATE,
    Address VARCHAR(255),
    City VARCHAR(50),
    State VARCHAR(50),
    Country VARCHAR(50),
    Region VARCHAR(50),
    ManagerName VARCHAR(100)
);

-- Fact Table: FactOrders
CREATE TABLE FactOrders (
    OrderID INT PRIMARY KEY AUTOINCREMENT START 1 INCREMENT 1,
    DateID INT,
    CustomerID INT,
    ProductID INT,
    StoreID INT,
    QuantityOrdered INT,
    OrderAmount DECIMAL(10, 2),
    DiscountAmount DECIMAL(10, 2),
    ShippingCost DECIMAL(10, 2),
    TotalAmount DECIMAL(10, 2),
    FOREIGN KEY (DateID) REFERENCES DimDates(DateID),
    FOREIGN KEY (CustomerID) REFERENCES DimCustomers(CustomerID),
    FOREIGN KEY (ProductID) REFERENCES DimProducts(ProductID),
    FOREIGN KEY (StoreID) REFERENCES DimStores(StoreID)
);

-- Create file format for CSV loading
CREATE OR REPLACE FILE FORMAT CSV_SOURCE_FILE_FORMAT
TYPE = 'CSV'
SKIP_HEADER = 1
FIELD_OPTIONALLY_ENCLOSED_BY = '"'
DATE_FORMAT = 'YYYY-MM-DD';

-- Create stage for data loading
CREATE OR REPLACE STAGE SALES_STAGE;

-- Verify staged files before loading
LIST @SALES.SALES_SCHEMA.SALES_STAGE;

-- Load DimLoyaltyInfo data
COPY INTO DimLoyaltyInfo (LoyaltyProgramID, ProgramName, ProgramTier, PointsAccrued)
FROM @SALES.SALES_SCHEMA.SALES_STAGE/DimLoyaltyInfo.csv
FILE_FORMAT = (FORMAT_NAME = 'CSV_SOURCE_FILE_FORMAT');

SELECT * FROM DimLoyaltyInfo;

-- Load DimCustomers data
COPY INTO DimCustomers (FirstName, LastName, Gender, DateOfBirth, Email, PhoneNumber, Address, City, State, ZipCode, Country, LoyaltyProgramID)
FROM @SALES.SALES_SCHEMA.SALES_STAGE/DimCustomers.csv
FILE_FORMAT = (FORMAT_NAME = 'CSV_SOURCE_FILE_FORMAT');

SELECT * FROM DimCustomers;

-- Load DimDates data
COPY INTO DimDates (DateID, Date, DayOfWeek, DayName, Month, MonthName, Quarter, Year, IsWeekend)
FROM @SALES.SALES_SCHEMA.SALES_STAGE/DimDates.csv
FILE_FORMAT = (FORMAT_NAME = 'CSV_SOURCE_FILE_FORMAT');

SELECT * FROM DimDates;

-- Load DimProducts data
COPY INTO DimProducts (ProductName, Category, Brand, UnitPrice)
FROM @SALES.SALES_SCHEMA.SALES_STAGE/DimProducts.csv
FILE_FORMAT = (FORMAT_NAME = 'CSV_SOURCE_FILE_FORMAT');

SELECT * FROM DimProducts;

-- Load DimStores data
COPY INTO DimStores (StoreName, StoreType, StoreOpeningDate, Address, City, State, Country, Region, ManagerName)
FROM @SALES.SALES_SCHEMA.SALES_STAGE/DimStores.csv
FILE_FORMAT = (FORMAT_NAME = 'CSV_SOURCE_FILE_FORMAT');

SELECT * FROM DimStores;

-- Load FactOrders data
COPY INTO FactOrders (DateID, ProductID, StoreID, CustomerID, QuantityOrdered, OrderAmount, DiscountAmount, ShippingCost, TotalAmount)
FROM @SALES.SALES_SCHEMA.SALES_STAGE/FactOrders.csv
FILE_FORMAT = (FORMAT_NAME = 'CSV_SOURCE_FILE_FORMAT');

SELECT * FROM FactOrders; 