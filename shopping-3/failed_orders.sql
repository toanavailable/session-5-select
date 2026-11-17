-- =====================================================
-- Tối ưu bộ lọc "Đơn hàng thất bại"
-- =====================================================

-- 1. Tạo bảng đơn hàng
CREATE TABLE Orders (
    order_id      INT PRIMARY KEY,
    customer_name VARCHAR(100),
    status        VARCHAR(20),    -- COMPLETED / FAILED
    cancel_reason VARCHAR(50),    -- NULL nếu thành công hoặc chưa kịp ghi nhận
    created_at    DATETIME
);

-- 2. Chèn dữ liệu mẫu
INSERT INTO Orders (order_id, customer_name, status, cancel_reason, created_at)
VALUES
    (1, 'Nguyễn Văn An',  'FAILED',    'KHACH_HUY',       '2026-11-17 08:10:00'),
    (2, 'Trần Thị Bình',  'FAILED',    'QUAN_DONG_CUA',   '2026-11-17 09:25:00'),
    (3, 'Lê Văn Cường',   'FAILED',    'KHONG_CO_TAI_XE', '2026-11-17 10:40:00'),
    (4, 'Phạm Minh Đức',  'FAILED',    'BOM_HANG',        '2026-11-17 11:05:00'),
    (5, 'Hoàng Văn Em',   'FAILED',    NULL,              '2026-11-17 11:50:00'), -- rớt mạng
    (6, 'Võ Thị Phương',  'FAILED',    NULL,              '2026-11-17 12:30:00'), -- rớt mạng
    (7, 'Đặng Văn Giang', 'FAILED',    'SAI_DIA_CHI',     '2026-11-17 13:15:00'), -- ngoài danh sách
    (8, 'Bùi Thị Hoa',    'COMPLETED', NULL,              '2026-11-17 14:00:00'), -- thành công
    (9, 'Đỗ Văn Khoa',    'COMPLETED', NULL,              '2026-11-17 15:20:00'); -- thành công

-- 3. Index hỗ trợ lọc
CREATE INDEX idx_orders_status_reason ON Orders (status, cancel_reason);

-- -----------------------------------------------------
-- 4. GIẢI PHÁP 1: = kết hợp OR
-- -----------------------------------------------------
SELECT order_id, customer_name, cancel_reason, created_at
FROM Orders
WHERE cancel_reason = 'KHACH_HUY'
   OR cancel_reason = 'QUAN_DONG_CUA'
   OR cancel_reason = 'KHONG_CO_TAI_XE'
   OR cancel_reason = 'BOM_HANG';

-- -----------------------------------------------------
-- 5. GIẢI PHÁP 2: toán tử tập hợp IN
-- -----------------------------------------------------
SELECT order_id, customer_name, cancel_reason, created_at
FROM Orders
WHERE cancel_reason IN ('KHACH_HUY', 'QUAN_DONG_CUA', 'KHONG_CO_TAI_XE', 'BOM_HANG');

-- -----------------------------------------------------
-- 6. BẪY: nhét NULL vào IN -> KHÔNG lấy được đơn 5 và 6
-- cancel_reason = NULL luôn là UNKNOWN, WHERE chỉ giữ dòng TRUE
-- -----------------------------------------------------
SELECT order_id, customer_name, cancel_reason
FROM Orders
WHERE cancel_reason IN ('KHACH_HUY', 'QUAN_DONG_CUA', 'KHONG_CO_TAI_XE', 'BOM_HANG', NULL);
-- Kết quả: chỉ đơn 1, 2, 3, 4

-- -----------------------------------------------------
-- 7. CÂU TRUY VẤN TỐT NHẤT
-- -----------------------------------------------------
SELECT order_id, customer_name, status, cancel_reason, created_at
FROM Orders
WHERE status = 'FAILED'
  AND (
        cancel_reason IN ('KHACH_HUY', 'QUAN_DONG_CUA', 'KHONG_CO_TAI_XE', 'BOM_HANG')
        OR cancel_reason IS NULL
      )
ORDER BY created_at DESC;
-- Kết quả mong đợi: đơn 6, 5, 4, 3, 2, 1
