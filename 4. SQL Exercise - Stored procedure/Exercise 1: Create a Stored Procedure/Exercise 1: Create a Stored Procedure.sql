-- ============================================================
-- EXERCISE 1: Create a Stored Procedure
-- Goal: Retrieve employee details by department, and insert a new employee
-- ============================================================

-- Step 1 & 2: Stored procedure to retrieve employee details by DepartmentID
CREATE PROCEDURE sp_GetEmployeesByDepartment
    @DepartmentID INT
AS
BEGIN
    SELECT
        EmployeeID,
        FirstName,
        LastName,
        DepartmentID,
        JoinDate
    FROM Employees
    WHERE DepartmentID = @DepartmentID;
END;
GO

-- Step 3: Stored procedure to insert a new employee
CREATE PROCEDURE sp_InsertEmployee
    @FirstName VARCHAR(50),
    @LastName VARCHAR(50),
    @DepartmentID INT,
    @Salary DECIMAL(10,2),
    @JoinDate DATE
AS
BEGIN
    INSERT INTO Employees (FirstName, LastName, DepartmentID, Salary, JoinDate)
    VALUES (@FirstName, @LastName, @DepartmentID, @Salary, @JoinDate);
END;
GO

-- Example executions
EXEC sp_GetEmployeesByDepartment @DepartmentID = 3;

EXEC sp_InsertEmployee
    @FirstName   = 'Sarah',
    @LastName    = 'Connor',
    @DepartmentID = 3,
    @Salary      = 6500.00,
    @JoinDate    = '2024-06-01';



