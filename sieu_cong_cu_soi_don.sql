-- =====================================================
-- Module "Siêu Công Cụ Soi Đơn" cho Admin
-- =====================================================

-- 1. Khởi tạo bảng Orders
CREATE TABLE Orders (
    order_id     INT AUTO_INCREMENT PRIMARY KEY,
    user_id      INT NULL,
    total_amount DECIMAL(15, 2) NOT NULL,
    status       VARCHAR(50) NOT NULL,
    note         TEXT,
    created_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. Dữ liệu mẫu
INSERT INTO Orders (user_id, total_amount, status, note) VALUES
    (101,  4500000, 'PENDING',    'Giao hàng gấp trong ngày'),
    (NULL, 3000000, 'COMPLETED',  'Đơn hàng tự động'),
    (103,  2500000, 'PROCESSING', 'Khách báo cần gấp nhé'),
    (NULL, 4800000, 'SHIPPING',   NULL),
    (105,  3500000, 'CANCELLED',  'Hủy gấp do sai địa chỉ'),
    (NULL, 2500000, 'CANCELLED',  'Hệ thống tự hủy gấp'),       -- bẫy: CANCELLED + đơn ảo
    (NULL, 10000000, 'PENDING',   'Đơn sỉ'),                    -- bẫy: 10 triệu + đơn ảo
    (106,  1500000, 'PROCESSING', 'Giao gấp'),
    (107,  3000000, 'COMPLETED',  'Giao giờ hành chính'),
    (108,  4100000, 'PENDING',    'gấp'),
    (NULL, 2200000, 'PROCESSING', ''),
    (109,  4900000, 'SHIPPING',   'gấp, gọi trước khi giao');

-- 3. Index hỗ trợ lọc và sắp xếp theo giá
CREATE INDEX idx_orders_amount ON Orders (total_amount);

-- -----------------------------------------------------
-- 4. CÁCH VIẾT SAI (KHÔNG DÙNG)
-- AND ưu tiên hơn OR -> "OR user_id IS NULL" đứng một mình
-- => lọt đơn 6 (CANCELLED) và đơn 7 (10.000.000đ)
-- -----------------------------------------------------
-- SELECT order_id, user_id, total_amount, status, note
-- FROM Orders
-- WHERE total_amount BETWEEN 2000000 AND 5000000
--   AND status <> 'CANCELLED'
--   AND note LIKE '%gấp%'
--    OR user_id IS NULL;

-- -----------------------------------------------------
-- 5. SIÊU CÂU LỆNH HOÀN CHỈNH (TRANG 3, 20 DÒNG/TRANG)
-- -----------------------------------------------------
SELECT
    order_id,
    user_id,
    total_amount,
    status,
    note,
    CASE
        WHEN total_amount > 4000000 THEN 'Nguy hiểm'
        ELSE 'Bình thường'
    END AS Alert_Level
FROM Orders
WHERE total_amount BETWEEN 2000000 AND 5000000      -- Yêu cầu 1
  AND status <> 'CANCELLED'                         -- Yêu cầu 2
  AND (note LIKE '%gấp%' OR user_id IS NULL)        -- Yêu cầu 3: khóa bằng ngoặc đơn
ORDER BY total_amount DESC,                         -- Yêu cầu 5: đắt nhất lên đầu
         order_id ASC                               -- thứ tự cố định khi trùng giá
LIMIT 20 OFFSET 40;                                 -- Trang 3 = bỏ qua 40 dòng
-- Với dữ liệu mẫu (7 đơn hợp lệ) trang 3 trả về rỗng.
-- Đổi thành LIMIT 20 OFFSET 0 để xem trang 1: đơn 12, 4, 1, 10, 2, 3, 11

-- -----------------------------------------------------
-- 6. CHỐNG BẪY OFFSET ÂM (phân trang động bằng prepared statement)
-- OFFSET -20 viết trực tiếp sẽ báo lỗi cú pháp (ERROR 1064)
-- -----------------------------------------------------
SET @page      = -1;                                     -- người dùng nhập sai
SET @page_size = 20;
SET @offset    = GREATEST((GREATEST(@page, 1) - 1) * @page_size, 0);

PREPARE stmt FROM
'SELECT order_id, user_id, total_amount, status, note,
        CASE WHEN total_amount > 4000000 THEN ''Nguy hiểm'' ELSE ''Bình thường'' END AS Alert_Level
 FROM Orders
 WHERE total_amount BETWEEN 2000000 AND 5000000
   AND status <> ''CANCELLED''
   AND (note LIKE ''%gấp%'' OR user_id IS NULL)
 ORDER BY total_amount DESC, order_id ASC
 LIMIT ? OFFSET ?';
EXECUTE stmt USING @page_size, @offset;                  -- page -1 được kẹp về trang 1
DEALLOCATE PREPARE stmt;
