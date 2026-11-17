-- =====================================================
-- Giới hạn và phân trang kết quả truy vấn với LIMIT và OFFSET
-- =====================================================

-- 0. Chuẩn bị dữ liệu
CREATE TABLE Employees (
    EmpId    INT PRIMARY KEY,
    FullName VARCHAR(100),
    Position VARCHAR(50),
    Salary   DECIMAL(10, 2)
);

INSERT INTO Employees (EmpId, FullName, Position, Salary)
VALUES
    (101, 'Nguyễn Văn Tuấn', 'Developer',  1500),
    (102, 'Trần Mai Phương', 'Designer',   1200),
    (103, 'Lê Quốc Bảo',     'Tester',     1000),
    (104, 'Phạm Hải Yến',    'HR Manager', 1800),
    (105, 'Hoàng Minh Trí',  'Marketing',  1300),
    (106, 'Đặng Thị Hoa',    'Accountant', 1400),
    (107, 'Vũ Hoàng Anh',    'Sales',      1100);

-- Bước 1: Lấy 3 bản ghi đầu tiên (trang 1)
SELECT *
FROM Employees
LIMIT 3;

-- Bước 2: Lấy dữ liệu trang 2 - bỏ qua 3 bản ghi đầu, lấy 3 bản ghi tiếp theo
SELECT *
FROM Employees
LIMIT 3 OFFSET 3;

-- Mở rộng: phân trang ổn định, luôn sắp xếp theo khóa chính trước khi cắt trang
SELECT *
FROM Employees
ORDER BY EmpId
LIMIT 3 OFFSET 3;

-- Mở rộng: trang 3 chỉ còn 1 bản ghi (EmpId 107)
SELECT *
FROM Employees
ORDER BY EmpId
LIMIT 3 OFFSET 6;
