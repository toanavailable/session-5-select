-- =====================================================
-- Lọc dữ liệu với WHERE và phân loại dữ liệu với CASE WHEN
-- =====================================================

-- 0. Chuẩn bị dữ liệu
CREATE TABLE Employees (
    EmpId   INT PRIMARY KEY,
    EmpName VARCHAR(100),
    Salary  DECIMAL(10, 2),   -- mức lương (USD)
    DeptId  INT,
    Phone   VARCHAR(15)       -- VARCHAR để giữ số 0 ở đầu
);

INSERT INTO Employees (EmpId, EmpName, Salary, DeptId, Phone)
VALUES
    (101, 'Nguyễn Thị Mai',  800,  1, '0901112233'),
    (102, 'Trần Văn Hùng',   400,  2, '0912223344'),
    (103, 'Lê Hoàng Phúc',   1500, 1, '0923334455'),
    (104, 'Nguyễn Tuấn Anh', 2500, 3, '0934445566'),
    (105, 'Phạm Trà My',     600,  2, '0945556677');

-- Bước 1: Lọc cơ bản - lương lớn hơn 800
SELECT *
FROM Employees
WHERE Salary > 800;

-- Bước 2: Lọc theo khoảng - lương từ 500 đến 1500 (gồm cả 2 biên)
SELECT *
FROM Employees
WHERE Salary BETWEEN 500 AND 1500;

-- Bước 3: Lọc theo tập hợp - phòng ban số 1 và số 3
SELECT *
FROM Employees
WHERE DeptId IN (1, 3);

-- Bước 4: Lọc theo chuỗi - nhân viên mang họ "Nguyễn"
SELECT *
FROM Employees
WHERE EmpName LIKE 'Nguyễn%';

-- Bước 5: Phân loại mức lương bằng CASE WHEN
SELECT EmpId,
       EmpName,
       Salary,
       CASE
           WHEN Salary < 500  THEN 'Thực tập'
           WHEN Salary < 1000 THEN 'Nhân viên'
           WHEN Salary < 2000 THEN 'Trưởng nhóm'
           ELSE 'Quản lý'
       END AS SalaryLevel
FROM Employees;
