-- =====================================================
-- Module "Khuyến mãi ngẫu nhiên" - Bản sửa lỗi
-- =====================================================

-- 1. Tạo bảng nhà hàng
CREATE TABLE Restaurants (
    restaurant_id   INT PRIMARY KEY,
    restaurant_name VARCHAR(100),
    address         VARCHAR(255),
    district        VARCHAR(50),
    rating          DECIMAL(2, 1)
);

-- 2. Chèn dữ liệu mẫu (có cả trường hợp đúng quận nhưng rating thấp)
INSERT INTO Restaurants (restaurant_id, restaurant_name, address, district, rating)
VALUES
    (1, 'Phở Hùng',          '12 Lê Lợi, Quận 1',          'Quận 1', 4.5),
    (2, 'Cơm Tấm Sài Gòn',   '45 Nguyễn Trãi, Quận 1',     'Quận 1', 2.5),
    (3, 'Bún Bò Cô Ba',      '8 Pasteur, Quận 1',          'Quận 1', 3.0),
    (4, 'Bánh Mì Huỳnh Hoa', '26 Lê Thị Riêng, Quận 3',    'Quận 3', 4.8),
    (5, 'Ốc Đào',            '212 Nguyễn Trãi, Quận 3',    'Quận 3', 3.5),
    (6, 'Lẩu Dê 404',        '404 Trần Hưng Đạo, Quận 5',  'Quận 5', 4.9);

-- -----------------------------------------------------
-- 3. ĐOẠN CODE LỖI CỦA FRESHER (KHÔNG DÙNG)
-- AND ưu tiên hơn OR -> được hiểu là:
-- district = 'Quận 1' OR (district = 'Quận 3' AND rating > 4.0)
-- => lấy TẤT CẢ quán Quận 1, bất kể rating
-- -----------------------------------------------------
-- SELECT restaurant_name, address, rating
-- FROM Restaurants
-- WHERE district = 'Quận 1' OR district = 'Quận 3' AND rating > 4.0;

-- -----------------------------------------------------
-- 4. CODE ĐÃ SỬA
-- -----------------------------------------------------

-- Cách 1: dùng ngoặc đơn để nhóm điều kiện quận
SELECT restaurant_name, address, rating
FROM Restaurants
WHERE (district = 'Quận 1' OR district = 'Quận 3')
  AND rating > 4.0;

-- Cách 2: dùng IN cho gọn, tránh lỗi ưu tiên toán tử
SELECT restaurant_name, address, rating
FROM Restaurants
WHERE district IN ('Quận 1', 'Quận 3')
  AND rating > 4.0;

-- Kết quả mong đợi: Phở Hùng (4.5), Bánh Mì Huỳnh Hoa (4.8)
