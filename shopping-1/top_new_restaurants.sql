-- =====================================================
-- "Top Quán Ăn Mới Nổi" trên Trang chủ - Bản sửa lỗi
-- =====================================================

-- 1. Tạo bảng nhà hàng
CREATE TABLE Restaurants (
    restaurant_id   INT PRIMARY KEY,
    restaurant_name VARCHAR(100),
    created_at      DATETIME
);

-- 2. Chèn dữ liệu mẫu (thêm vào theo thứ tự từ cũ đến mới)
INSERT INTO Restaurants (restaurant_id, restaurant_name, created_at)
VALUES
    (1, 'Phở Hùng',          '2025-03-10 09:00:00'),
    (2, 'Cơm Tấm Sài Gòn',   '2025-06-22 10:30:00'),
    (3, 'Bún Bò Cô Ba',      '2025-09-05 14:15:00'),
    (4, 'Ốc Đào',            '2025-12-18 08:45:00'),
    (5, 'Lẩu Dê 404',        '2026-02-14 19:00:00'),
    (6, 'Bánh Mì Huỳnh Hoa', '2026-05-01 07:20:00'),
    (7, 'Gà Rán Ông Tám',    '2026-08-09 11:10:00'),
    (8, 'Trà Sữa Mây',       '2026-10-20 16:40:00'),
    (9, 'Bò Né 3 Ngon',      '2026-11-15 06:30:00');

-- -----------------------------------------------------
-- 3. ĐOẠN CODE LỖI (KHÔNG DÙNG)
-- LIMIT không có ORDER BY -> thứ tự không được đảm bảo,
-- thường trả về 5 quán CŨ NHẤT hoặc 5 quán bất kỳ
-- -----------------------------------------------------
-- SELECT restaurant_name, created_at
-- FROM Restaurants
-- LIMIT 5;

-- -----------------------------------------------------
-- 4. CODE ĐÃ SỬA
-- -----------------------------------------------------

-- 4.1 Index giúp lấy Top-N nhanh khi bảng lớn
CREATE INDEX idx_restaurants_created_at
ON Restaurants (created_at DESC, restaurant_id DESC);

-- 4.2 Sắp xếp mới nhất lên đầu, rồi mới lấy 5 dòng
SELECT restaurant_name, created_at
FROM Restaurants
ORDER BY created_at DESC, restaurant_id DESC
LIMIT 5;

-- Kết quả mong đợi:
-- Bò Né 3 Ngon, Trà Sữa Mây, Gà Rán Ông Tám, Bánh Mì Huỳnh Hoa, Lẩu Dê 404
