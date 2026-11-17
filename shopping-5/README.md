# Module "Siêu Công Cụ Soi Đơn" cho Admin

Lắp ráp một câu lệnh SQL duy nhất kết hợp lọc khoảng giá, loại trạng thái, bộ lọc kép `OR`, cột ảo cảnh báo, sắp xếp và phân trang. Đồng thời mổ xẻ bẫy ưu tiên toán tử `AND`/`OR` và bẫy `OFFSET` âm.

## 1. Bối cảnh

Trưởng phòng Vận hành (Admin) cần một màn hình để điều tra các đơn hàng đáng ngờ trong bảng `Orders` với 5 yêu cầu:

| # | Yêu cầu | Kỹ thuật SQL |
|---|---|---|
| 1 | `total_amount` từ 2.000.000đ đến 5.000.000đ | `BETWEEN ... AND ...` |
| 2 | `status` tuyệt đối không phải `'CANCELLED'` | `<>` |
| 3 | Ghi chú chứa "gấp" **HOẶC** đơn ảo (`user_id` là `NULL`) | `LIKE '%gấp%'` `OR` `IS NULL`, **bọc trong ngoặc đơn** |
| 4 | Cột ảo `Alert_Level`: > 4.000.000đ là 'Nguy hiểm', còn lại 'Bình thường' | `CASE WHEN ... END AS` |
| 5 | Đơn đắt nhất lên đầu, lấy **trang 3**, mỗi trang 20 dòng | `ORDER BY ... DESC` + `LIMIT 20 OFFSET 40` |

## 2. Bản vẽ Logic: mổ xẻ bẫy toán tử

### Cách viết sai mà nhiều Dev mắc phải

```sql
WHERE total_amount BETWEEN 2000000 AND 5000000
  AND status <> 'CANCELLED'
  AND note LIKE '%gấp%'
   OR user_id IS NULL
```

### Vì sao `OR` phá hỏng yêu cầu 1 và 2?

Trong SQL, **`AND` được ưu tiên cao hơn `OR`**, giống như phép nhân được tính trước phép cộng. Database gom tất cả các `AND` thành một khối trước, rồi mới xét `OR`. Câu lệnh trên thực chất được hiểu là:

```
(   total_amount BETWEEN 2000000 AND 5000000
AND status <> 'CANCELLED'
AND note LIKE '%gấp%'   )
OR
(   user_id IS NULL   )        ← nhánh này đứng một mình, không có điều kiện giá và trạng thái
```

`WHERE` chỉ cần **một trong hai nhánh đúng** là giữ lại dòng. Nhánh thứ hai `user_id IS NULL` **không bị ràng buộc** bởi điều kiện giá và trạng thái, nên **mọi đơn ảo đều lọt lưới**, kể cả:

- đơn **`CANCELLED`** (đơn số 6: 2.500.000đ, `CANCELLED`, `user_id` là `NULL`), phá yêu cầu 2;
- đơn **10.000.000đ** (đơn số 7: `PENDING`, `user_id` là `NULL`), phá yêu cầu 1.

Đây chính xác là "nỗi đau kỹ thuật" Admin mô tả. Câu lệnh vẫn đúng cú pháp nên không báo lỗi gì.

### Kỹ thuật khóa bẫy: dấu ngoặc đơn `( )`

Bọc bộ lọc kép trong **ngoặc đơn** để biến nó thành **một điều kiện duy nhất**, rồi nối với các điều kiện bắt buộc bằng `AND`:

```
[Điều kiện giá]  AND  [Điều kiện trạng thái]  AND  ( [ghi chú có "gấp"]  OR  [đơn ảo] )
```

Ngoặc đơn được tính **trước tiên**, nên `OR` chỉ có tác dụng **bên trong** ngoặc. Kết quả của cả khối ngoặc sau đó vẫn phải `AND` với điều kiện giá và trạng thái, nên không đơn nào thoát được yêu cầu 1 và 2.

> **Ghi chú phụ:** với đơn có `note` là `NULL` (đơn số 4), `note LIKE '%gấp%'` cho ra UNKNOWN. Nhờ vế `OR user_id IS NULL` là TRUE, cả khối ngoặc vẫn là TRUE nên đơn này được giữ lại đúng như yêu cầu.

## 3. Quy trình chống bẫy đầu vào: `OFFSET` âm

### Hệ quản trị CSDL phản ứng thế nào với `OFFSET -20`?

**Báo lỗi, không trả về kết quả rỗng.** Câu lệnh bị từ chối và không chạy.

- **MySQL:** `LIMIT` và `OFFSET` chỉ chấp nhận **số nguyên không âm**. Viết trực tiếp `LIMIT 20 OFFSET -20` sẽ bị báo **lỗi cú pháp** (`ERROR 1064 ... You have an error in your SQL syntax`). Truyền số âm qua tham số của prepared statement cũng bị từ chối.
- **SQL Server:** cú pháp phân trang là `OFFSET ... ROWS FETCH NEXT ... ROWS ONLY`. Khi giá trị âm, câu lệnh báo lỗi **Msg 10742: "The offset specified in a OFFSET clause may not be negative."**

Điều này nghĩa là: nếu tầng ứng dụng tính `offset = (page - 1) * 20` và người dùng nhập `page = 0` hoặc `page = -1`, màn hình của Admin sẽ **bị lỗi** thay vì hiển thị dữ liệu.

### Quy trình chống bẫy

1. **Kiểm tra và chuẩn hóa đầu vào ở tầng ứng dụng:** ép `page` về số nguyên, nếu `page < 1` thì gán `page = 1`. Giới hạn `page_size` trong khoảng hợp lý, ví dụ 1 đến 100.
2. **Tính `OFFSET` từ dữ liệu đã chuẩn hóa:** `offset = (page - 1) * page_size`, luôn lớn hơn hoặc bằng 0.
3. **Chốt chặn thứ hai trong SQL:** khi dùng prepared statement, kẹp giá trị bằng `GREATEST(..., 0)` trước khi truyền vào `LIMIT`/`OFFSET`, để dù tầng ứng dụng có quên kiểm tra thì câu lệnh vẫn an toàn.
4. **Luôn truyền tham số** (`?`) thay vì nối chuỗi, để tránh SQL Injection.

```sql
SET @page      = -1;    -- giả lập người dùng nhập sai
SET @page_size = 20;
SET @offset    = GREATEST((@page - 1) * @page_size, 0);   -- kẹp về 0

PREPARE stmt FROM 'SELECT order_id, total_amount FROM Orders ORDER BY total_amount DESC LIMIT ? OFFSET ?';
EXECUTE stmt USING @page_size, @offset;
DEALLOCATE PREPARE stmt;
```

## 4. Mã nguồn Database: siêu câu lệnh

```sql
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
         order_id ASC                               -- phân định khi trùng giá, giữ thứ tự cố định giữa các trang
LIMIT 20 OFFSET 40;                                 -- Trang 3: bỏ qua (3 - 1) × 20 = 40 dòng
```

Giải thích từng phần:

- **Yêu cầu 1:** `BETWEEN` lấy **cả hai biên** 2.000.000đ và 5.000.000đ.
- **Yêu cầu 2:** `status` có ràng buộc `NOT NULL` trong bảng, nên dùng `<> 'CANCELLED'` là đủ an toàn.
- **Yêu cầu 3:** ngoặc đơn khóa `OR` lại, không cho phá vỡ yêu cầu 1 và 2.
- **Yêu cầu 4:** `CASE WHEN` tạo cột ảo `Alert_Level`. Đơn **đúng** 4.000.000đ là 'Bình thường', vì điều kiện là **lớn hơn** 4.000.000đ.
- **Yêu cầu 5:** `ORDER BY` chạy **trước** `LIMIT`, nên phân trang trên danh sách đã sắp xếp. Cột phụ `order_id` giúp các đơn trùng giá luôn có thứ tự cố định, không bị nhảy trang hoặc lặp lại giữa các trang. Công thức `OFFSET = (trang − 1) × 20 = 40`.

Thứ tự thực thi logic:

```
FROM Orders → WHERE (yêu cầu 1, 2, 3) → SELECT + CASE (yêu cầu 4) → ORDER BY → LIMIT/OFFSET (yêu cầu 5)
```

## 5. Dò luồng (trace) với dữ liệu mẫu

| order_id | user_id | total_amount | status | note | Kết quả |
|---|---|---|---|---|---|
| 1 | 101 | 4.500.000 | PENDING | Giao hàng gấp trong ngày | ✅ Nguy hiểm |
| 2 | NULL | 3.000.000 | COMPLETED | Đơn hàng tự động | ✅ Bình thường (đơn ảo) |
| 3 | 103 | 2.500.000 | PROCESSING | Khách báo cần gấp nhé | ✅ Bình thường |
| 4 | NULL | 4.800.000 | SHIPPING | NULL | ✅ Nguy hiểm (đơn ảo) |
| 5 | 105 | 3.500.000 | CANCELLED | Hủy gấp do sai địa chỉ | Loại (CANCELLED) |
| 6 | NULL | 2.500.000 | CANCELLED | Hệ thống tự hủy gấp | Loại (CANCELLED), **lọt lưới nếu thiếu ngoặc** |
| 7 | NULL | 10.000.000 | PENDING | Đơn sỉ | Loại (vượt 5 triệu), **lọt lưới nếu thiếu ngoặc** |
| 8 | 106 | 1.500.000 | PROCESSING | Giao gấp | Loại (dưới 2 triệu) |
| 9 | 107 | 3.000.000 | COMPLETED | Giao giờ hành chính | Loại (không "gấp", không phải đơn ảo) |
| 10 | 108 | 4.100.000 | PENDING | gấp | ✅ Nguy hiểm |
| 11 | NULL | 2.200.000 | PROCESSING | (rỗng) | ✅ Bình thường (đơn ảo) |
| 12 | 109 | 4.900.000 | SHIPPING | gấp, gọi trước khi giao | ✅ Nguy hiểm |

### So sánh kết quả

| Cách viết | Số đơn trả về | Đơn lọt lưới |
|---|---|---|
| Thiếu ngoặc đơn | 9 | Đơn 6 (CANCELLED) và đơn 7 (10.000.000đ) |
| Có ngoặc đơn | 7 | Không có |

Toàn bộ 7 đơn hợp lệ, sắp theo giá giảm dần (đây là kết quả trang 1):

| order_id | user_id | total_amount | status | note | Alert_Level |
|---|---|---|---|---|---|
| 12 | 109 | 4.900.000 | SHIPPING | gấp, gọi trước khi giao | Nguy hiểm |
| 4 | NULL | 4.800.000 | SHIPPING | NULL | Nguy hiểm |
| 1 | 101 | 4.500.000 | PENDING | Giao hàng gấp trong ngày | Nguy hiểm |
| 10 | 108 | 4.100.000 | PENDING | gấp | Nguy hiểm |
| 2 | NULL | 3.000.000 | COMPLETED | Đơn hàng tự động | Bình thường |
| 3 | 103 | 2.500.000 | PROCESSING | Khách báo cần gấp nhé | Bình thường |
| 11 | NULL | 2.200.000 | PROCESSING | (rỗng) | Bình thường |

**Trang 3** (`LIMIT 20 OFFSET 40`) trả về **rỗng**, vì dữ liệu mẫu chỉ có 7 đơn hợp lệ, ít hơn 40 dòng cần bỏ qua. Đây là hành vi đúng: `OFFSET` vượt quá số dòng thì trả về rỗng, không báo lỗi. Ngược lại, `OFFSET` **âm** thì báo lỗi.

## 6. Bài học rút ra

- **`AND` được ưu tiên hơn `OR`.** Khi một bộ lọc có `OR` nằm chung với các điều kiện bắt buộc, **luôn bọc `OR` trong ngoặc đơn**.
- Kiểm thử bằng **dữ liệu bẫy** như đơn vừa thỏa nhánh `OR` vừa vi phạm điều kiện bắt buộc (đơn 6, đơn 7). Dữ liệu "đẹp" sẽ không lộ ra lỗi.
- `LIKE` với cột `NULL` cho kết quả UNKNOWN. Hiểu rõ điều này khi kết hợp với `OR`.
- **`ORDER BY` phải đi kèm phân trang**, và nên có cột phụ duy nhất để thứ tự cố định giữa các trang.
- **Không tin dữ liệu người dùng nhập:** chuẩn hóa `page` ở tầng ứng dụng và kẹp `OFFSET` bằng `GREATEST(..., 0)`, vì `OFFSET` âm làm câu lệnh báo lỗi.
