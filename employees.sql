-- =====================================================
-- Truy vấn dữ liệu cơ bản và đặt tên định danh (Alias)
-- =====================================================

-- 0. Chuẩn bị dữ liệu
CREATE TABLE Employees (
    ID         INT PRIMARY KEY,
    EmpName    VARCHAR(100),
    Phone      VARCHAR(15),   -- VARCHAR để giữ số 0 ở đầu
    Department VARCHAR(50)
);

INSERT INTO Employees (ID, EmpName, Phone, Department)
VALUES
    (101, 'Nguyen Van Anh', '0901234567', 'IT'),
    (102, 'Tran Thi Bich',  '0912345678', 'HR'),
    (103, 'Le Van Chi',     '0923456789', 'Marketing');

-- Bước 1: Lấy toàn bộ dữ liệu
SELECT *
FROM Employees;

-- Bước 2: Chọn cột cụ thể theo thứ tự EmpName, Phone, ID, Department
SELECT EmpName, Phone, ID, Department
FROM Employees;

-- Bước 3: Đặt tên định danh (Alias) tiếng Việt
SELECT EmpName    AS 'Tên nhân viên',
       Phone      AS 'Số điện thoại',
       ID         AS 'Mã nhân viên',
       Department AS 'Phòng ban'
FROM Employees;

-- Bước 3 (theo đúng thứ tự cột của bảng Output mong đợi)
SELECT ID         AS 'Mã nhân viên',
       EmpName    AS 'Tên nhân viên',
       Phone      AS 'Số điện thoại',
       Department AS 'Phòng ban'
FROM Employees;
