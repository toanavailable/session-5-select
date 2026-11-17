# Truy vấn Dữ liệu Cơ bản và Đặt tên Định danh (Alias)

Thực hành câu lệnh `SELECT ... FROM`: lấy toàn bộ dữ liệu bằng `*`, chọn và sắp xếp thứ tự cột, và dùng `AS` để đặt tên hiển thị tiếng Việt cho các cột trong bảng `Employees`.

## 1. Mục tiêu

- Viết câu lệnh truy vấn đơn giản với `SELECT` và `FROM`.
- Dùng `*` để lấy dữ liệu của tất cả các cột.
- Chỉ định các cột cần lấy và thứ tự hiển thị theo ý muốn.
- Dùng `AS` để đặt tên định danh (Alias) cho các cột.

## 2. Chuẩn bị dữ liệu

```sql
CREATE TABLE Employees (
    ID         INT PRIMARY KEY,
    EmpName    VARCHAR(100),
    Phone      VARCHAR(15),
    Department VARCHAR(50)
);

INSERT INTO Employees (ID, EmpName, Phone, Department)
VALUES
    (101, 'Nguyen Van Anh', '0901234567', 'IT'),
    (102, 'Tran Thi Bich',  '0912345678', 'HR'),
    (103, 'Le Van Chi',     '0923456789', 'Marketing');
```

Cột `Phone` dùng kiểu `VARCHAR` thay vì `INT`, vì nếu lưu dạng số thì số `0` ở đầu sẽ bị mất (`0901234567` thành `901234567`).

## 3. Bước 1: Lấy toàn bộ dữ liệu

```sql
SELECT *
FROM Employees;
```

Dấu `*` nghĩa là "tất cả các cột". Kết quả hiển thị đủ 4 cột theo thứ tự đã khai báo khi tạo bảng:

| ID | EmpName | Phone | Department |
|---|---|---|---|
| 101 | Nguyen Van Anh | 0901234567 | IT |
| 102 | Tran Thi Bich | 0912345678 | HR |
| 103 | Le Van Chi | 0923456789 | Marketing |

## 4. Bước 2: Chọn cột cụ thể

```sql
SELECT EmpName, Phone, ID, Department
FROM Employees;
```

Thay `*` bằng danh sách tên cột, cách nhau bởi dấu phẩy. **Thứ tự cột trong kết quả giống đúng thứ tự viết sau `SELECT`**, không phụ thuộc vào thứ tự cột trong bảng:

| EmpName | Phone | ID | Department |
|---|---|---|---|
| Nguyen Van Anh | 0901234567 | 101 | IT |
| Tran Thi Bich | 0912345678 | 102 | HR |
| Le Van Chi | 0923456789 | 103 | Marketing |

## 5. Bước 3: Đặt tên định danh (Alias)

```sql
SELECT EmpName    AS 'Tên nhân viên',
       Phone      AS 'Số điện thoại',
       ID         AS 'Mã nhân viên',
       Department AS 'Phòng ban'
FROM Employees;
```

- `AS` chỉ đổi **tên tiêu đề hiển thị** trong kết quả, không đổi tên cột thật trong bảng.
- Tên tiếng Việt có **khoảng trắng** nên phải bọc trong dấu nháy đơn `' '` hoặc nháy kép `" "`. Trong MySQL cũng có thể dùng dấu backtick `` ` ` ``.

Kết quả:

| Tên nhân viên | Số điện thoại | Mã nhân viên | Phòng ban |
|---|---|---|---|
| Nguyen Van Anh | 0901234567 | 101 | IT |
| Tran Thi Bich | 0912345678 | 102 | HR |
| Le Van Chi | 0923456789 | 103 | Marketing |

### Lưu ý về thứ tự cột trong Output mong đợi

Bảng Output mong đợi của đề bài đặt cột **Mã nhân viên** lên đầu, khác với thứ tự `EmpName, Phone, ID, Department` của Bước 2. Nếu cần khớp chính xác bảng Output đó, chỉ cần đổi thứ tự các cột sau `SELECT`:

```sql
SELECT ID         AS 'Mã nhân viên',
       EmpName    AS 'Tên nhân viên',
       Phone      AS 'Số điện thoại',
       Department AS 'Phòng ban'
FROM Employees;
```

| Mã nhân viên | Tên nhân viên | Số điện thoại | Phòng ban |
|---|---|---|---|
| 101 | Nguyen Van Anh | 0901234567 | IT |
| 102 | Tran Thi Bich | 0912345678 | HR |
| 103 | Le Van Chi | 0923456789 | Marketing |

## 6. Tự đánh giá

| Tiêu chí | Kết quả |
|---|---|
| Đúng cú pháp Alias: có `AS` sau mỗi cột, tên tiếng Việt bọc trong dấu nháy | ✅ |
| Đúng thứ tự mệnh đề: `SELECT` đứng trước `FROM` | ✅ |
| Đúng kết quả: tiêu đề cột và dữ liệu khớp với Output mong đợi | ✅ |

## 7. Bài học rút ra

- `SELECT *` tiện để xem nhanh dữ liệu, nhưng trong ứng dụng thực tế nên **liệt kê rõ các cột cần dùng** để giảm dữ liệu truyền đi và tránh lỗi khi bảng thêm cột mới.
- Thứ tự cột hiển thị do **thứ tự viết sau `SELECT`** quyết định.
- `AS` giúp kết quả dễ đọc hơn với người dùng cuối mà không phải sửa cấu trúc bảng.
- Alias có khoảng trắng hoặc ký tự đặc biệt phải được bọc trong dấu nháy.
