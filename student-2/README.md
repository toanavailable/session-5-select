# Giới hạn và Phân trang Kết quả Truy vấn với LIMIT và OFFSET

Thực hành giới hạn số bản ghi trả về bằng `LIMIT` và phân trang dữ liệu bảng `Employees` bằng `LIMIT` kết hợp `OFFSET`.

## 1. Mục tiêu

- Dùng `LIMIT` để giới hạn số bản ghi trả về, giúp xử lý các bảng có nhiều dữ liệu.
- Kết hợp `LIMIT` và `OFFSET` để bỏ qua một số bản ghi, phục vụ phân trang (pagination).

## 2. Chuẩn bị dữ liệu

```sql
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
```

## 3. Bước 1: Giới hạn dữ liệu cơ bản

```sql
SELECT *
FROM Employees
LIMIT 3;
```

`LIMIT 3` lấy đúng **3 bản ghi đầu tiên**. Đây là dữ liệu của **trang 1**:

| EmpId | FullName | Position | Salary |
|---|---|---|---|
| 101 | Nguyễn Văn Tuấn | Developer | 1500 |
| 102 | Trần Mai Phương | Designer | 1200 |
| 103 | Lê Quốc Bảo | Tester | 1000 |

## 4. Bước 2: Phân trang dữ liệu (OFFSET)

```sql
SELECT *
FROM Employees
LIMIT 3 OFFSET 3;
```

- `OFFSET 3`: **bỏ qua** 3 bản ghi đầu tiên (101, 102, 103 của trang 1).
- `LIMIT 3`: lấy **3 bản ghi tiếp theo**, bắt đầu từ bản ghi thứ 4.

| EmpId | FullName | Position | Salary |
|---|---|---|---|
| 104 | Phạm Hải Yến | HR Manager | 1800 |
| 105 | Hoàng Minh Trí | Marketing | 1300 |
| 106 | Đặng Thị Hoa | Accountant | 1400 |

### Công thức phân trang

```
OFFSET = (Số trang − 1) × Số bản ghi mỗi trang
```

| Trang | Câu lệnh | Bản ghi lấy ra |
|---|---|---|
| 1 | `LIMIT 3 OFFSET 0` (hoặc `LIMIT 3`) | 101, 102, 103 |
| 2 | `LIMIT 3 OFFSET 3` | 104, 105, 106 |
| 3 | `LIMIT 3 OFFSET 6` | 107 (chỉ còn 1 bản ghi) |
| 4 | `LIMIT 3 OFFSET 9` | Rỗng (không báo lỗi) |

Trong MySQL còn có cú pháp rút gọn `LIMIT 3, 3`. Lưu ý thứ tự ngược lại: **số đầu là OFFSET, số sau là LIMIT**.

## 5. Mở rộng: phân trang ổn định với ORDER BY

Nếu không có `ORDER BY`, MySQL **không đảm bảo** thứ tự các bản ghi. Với bảng nhỏ vừa tạo, kết quả thường tình cờ theo thứ tự khóa chính, nhưng khi dữ liệu lớn hoặc đã bị xóa và sửa nhiều lần, các trang có thể bị **trùng hoặc sót** bản ghi. Trong thực tế, nên luôn sắp xếp trước khi phân trang:

```sql
SELECT *
FROM Employees
ORDER BY EmpId
LIMIT 3 OFFSET 3;
```

Kết quả vẫn là 104, 105, 106, nhưng giờ được **đảm bảo** cố định ở mọi lần chạy.

## 6. Tự đánh giá

| Tiêu chí | Kết quả |
|---|---|
| `LIMIT` và `OFFSET` đặt ở vị trí cuối cùng của câu lệnh | ✅ |
| Bước 2 dùng `OFFSET 3`, bắt đầu lấy từ bản ghi thứ 4 | ✅ |
| Kết quả Bước 2 khớp Output mong đợi, đã loại bỏ 101, 102, 103 | ✅ |

## 7. Bài học rút ra

- `LIMIT n` lấy `n` bản ghi, còn `OFFSET m` bỏ qua `m` bản ghi đầu tiên.
- Công thức phân trang: `OFFSET = (trang − 1) × số bản ghi mỗi trang`.
- `LIMIT` / `OFFSET` luôn đứng **cuối cùng** trong câu truy vấn, và chạy sau `ORDER BY`.
- Nên kết hợp với **`ORDER BY`** theo một cột duy nhất (như khóa chính) để kết quả phân trang ổn định.
- Phân trang tại Database giúp chỉ trả về đúng số bản ghi cần hiển thị, tiết kiệm băng thông và bộ nhớ của ứng dụng.
