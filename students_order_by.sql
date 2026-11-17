-- =====================================================
-- Sắp xếp kết quả truy vấn với ORDER BY
-- =====================================================

-- 0. Chuẩn bị dữ liệu
CREATE TABLE Students (
    StudentId INT PRIMARY KEY,
    FullName  VARCHAR(100),
    Major     VARCHAR(50),
    Gpa       DECIMAL(3, 1)
);

INSERT INTO Students (StudentId, FullName, Major, Gpa)
VALUES
    (101, 'Lê Quốc Bảo',     'IT',        8.5),
    (102, 'Trần Mai Phương', 'Design',    7.2),
    (103, 'Nguyễn Văn Tuấn', 'IT',        9.1),
    (104, 'Phạm Hải Yến',    'Design',    8.8),
    (105, 'Hoàng Minh Trí',  'Marketing', 7.5);

-- Bước 1: Kiểm chứng sắp xếp mặc định (không ghi ASC/DESC)
SELECT *
FROM Students
ORDER BY Gpa;

-- Bước 2: Sắp xếp giảm dần - điểm cao nhất lên đầu
SELECT *
FROM Students
ORDER BY Gpa DESC;

-- Bước 3: Sắp xếp tăng dần - kết quả giống hệt Bước 1
SELECT *
FROM Students
ORDER BY Gpa ASC;
