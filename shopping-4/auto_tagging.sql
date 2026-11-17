-- =====================================================
-- Tool "Đánh nhãn Khách Hàng Tự Động" (Auto Tagging)
-- =====================================================

-- 1. Tạo bảng khách hàng
CREATE TABLE Users (
    user_id      INT PRIMARY KEY,
    full_name    VARCHAR(100),
    total_orders INT              -- NULL với khách vừa đăng ký
);

-- 2. Chèn dữ liệu mẫu (có giá trị biên, NULL và dữ liệu dị biệt)
INSERT INTO Users (user_id, full_name, total_orders)
VALUES
    (1, 'Nguyễn Văn An',  1200),
    (2, 'Trần Thị Bình',  501),   -- biên Kim Cương
    (3, 'Lê Văn Cường',   500),   -- biên trên của Vàng
    (4, 'Phạm Minh Đức',  100),   -- biên dưới của Vàng
    (5, 'Hoàng Văn Em',   99),    -- biên trên của Bạc
    (6, 'Võ Thị Phương',  0),
    (7, 'Đặng Văn Giang', NULL),  -- khách mới đăng ký
    (8, 'Bùi Thị Hoa',    NULL),  -- khách mới đăng ký
    (9, 'Đỗ Văn Khoa',    -5);    -- dữ liệu lỗi

-- -----------------------------------------------------
-- 3. CÁCH VIẾT CHƯA AN TOÀN (KHÔNG DÙNG)
-- Không có ELSE -> khách có total_orders NULL bị trống nhãn
-- -----------------------------------------------------
-- SELECT full_name AS `Tên_Khách_Hàng`,
--        CASE
--            WHEN total_orders > 500  THEN 'Kim Cương'
--            WHEN total_orders >= 100 THEN 'Vàng'
--            WHEN total_orders < 100  THEN 'Bạc'
--        END AS Xep_Hang
-- FROM Users;

-- -----------------------------------------------------
-- 4. CODE HOÀN CHỈNH
-- -----------------------------------------------------
SELECT
    full_name AS `Tên_Khách_Hàng`,
    CASE
        WHEN total_orders IS NULL THEN 'Bạc'          -- khách mới đăng ký, chưa có đơn
        WHEN total_orders > 500   THEN 'Kim Cương'
        WHEN total_orders >= 100  THEN 'Vàng'         -- 100 đến 500
        WHEN total_orders >= 0    THEN 'Bạc'          -- 0 đến 99
        ELSE 'Kiểm tra lại'                           -- dữ liệu dị biệt (số âm)
    END AS Xep_Hang
FROM Users;

-- -----------------------------------------------------
-- 5. ĐỀ XUẤT SỬA THIẾT KẾ BẢNG VỀ LÂU DÀI
-- -----------------------------------------------------
-- UPDATE Users SET total_orders = 0 WHERE total_orders IS NULL;
-- ALTER TABLE Users
--     MODIFY total_orders INT NOT NULL DEFAULT 0,
--     ADD CONSTRAINT chk_total_orders CHECK (total_orders >= 0);
