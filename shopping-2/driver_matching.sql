-- =====================================================
-- Logic gán đơn tự động cho Tài xế (Driver Matching)
-- =====================================================

-- 1. Tạo bảng tài xế
CREATE TABLE Drivers (
    driver_id    INT PRIMARY KEY,
    driver_name  VARCHAR(100),
    phone        VARCHAR(15),
    status       VARCHAR(20),     -- AVAILABLE / BUSY / BANNED / OFFLINE
    trust_score  INT,
    distance_km  DECIMAL(5, 2)    -- khoảng cách tới quán
);

-- 2. Chèn dữ liệu mẫu (có đủ các trường hợp bẫy)
INSERT INTO Drivers (driver_id, driver_name, phone, status, trust_score, distance_km)
VALUES
    (1, 'Nguyễn Văn An',  '0903000001', 'AVAILABLE', 92, 1.5),
    (2, 'Trần Thị Bình',  '0903000002', 'AVAILABLE', 85, 1.5),   -- trùng khoảng cách với An
    (3, 'Lê Văn Cường',   '0903000003', 'AVAILABLE', 88, 0.8),
    (4, 'Phạm Minh Đức',  '0903000004', 'BANNED',    95, 0.5),   -- bị khóa
    (5, 'Hoàng Văn Em',   '0903000005', 'AVAILABLE', 60, 0.3),   -- điểm thấp nhưng gần nhất
    (6, 'Võ Thị Phương',  '0903000006', 'BUSY',      90, 1.0),   -- đang bận
    (7, 'Đặng Văn Giang', '0903000007', 'AVAILABLE', 80, 3.2),   -- đúng 80 điểm
    (8, 'Bùi Thị Hoa',    '0903000008', 'AVAILABLE', 99, NULL),  -- chưa có vị trí
    (9, 'Đỗ Văn Khoa',    '0903000009', 'AVAILABLE', 30, 2.0);   -- điểm rất thấp

-- 3. Index cho các cột lọc và sắp xếp
CREATE INDEX idx_drivers_matching
ON Drivers (status, distance_km, trust_score);

-- 4. Tham số cấu hình (giả lập Admin nhập nhầm số âm)
SET @min_trust_score = -10;

-- -----------------------------------------------------
-- 5. CÁCH VIẾT NGUY HIỂM (KHÔNG DÙNG)
-- trust_score >= -10 đúng với mọi tài xế -> bộ lọc điểm mất tác dụng
-- -----------------------------------------------------
-- SELECT driver_id, driver_name, phone, distance_km, trust_score
-- FROM Drivers
-- WHERE status = 'AVAILABLE'
--   AND trust_score >= @min_trust_score
-- ORDER BY distance_km ASC, trust_score DESC;

-- -----------------------------------------------------
-- 6. CÂU LỆNH HOÀN CHỈNH CÓ CHỐT CHẶN AN TOÀN
-- -----------------------------------------------------
SELECT driver_id, driver_name, phone, distance_km, trust_score
FROM Drivers
WHERE status = 'AVAILABLE'
  AND trust_score >= GREATEST(COALESCE(@min_trust_score, 80), 80)  -- mức sàn 80
  AND distance_km IS NOT NULL
ORDER BY distance_km ASC,     -- tầng 1: gần quán nhất
         trust_score DESC,    -- tầng 2: trùng khoảng cách -> điểm cao hơn
         driver_id ASC;       -- tầng 3: đảm bảo thứ tự cố định

-- Kết quả mong đợi:
-- 3 Lê Văn Cường   0.8  88
-- 1 Nguyễn Văn An  1.5  92
-- 2 Trần Thị Bình  1.5  85
-- 7 Đặng Văn Giang 3.2  80
