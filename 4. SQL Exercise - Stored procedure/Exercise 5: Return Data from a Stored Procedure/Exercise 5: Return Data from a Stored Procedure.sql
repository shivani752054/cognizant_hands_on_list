-- ============================================================
-- EXERCISE 5: Return Data from a Stored Procedure
-- Goal: Return the total number of employees in a department
-- ============================================================

CREATE PROCEDURE sp_GetEmployeeCountByDepartment
    @DepartmentID INT
AS
BEGIN
    SELECT
        @DepartmentID       AS DepartmentID,
        COUNT(EmployeeID)   AS TotalEmployees
    FROM Employees
    WHERE DepartmentID = @DepartmentID;
END;
GO
