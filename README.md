# Lọc dữ liệu với WHERE và Phân loại dữ liệu với CASE WHEN

Thực hành lọc dữ liệu bảng `Employees` bằng `WHERE` với các toán tử so sánh, `BETWEEN`, `IN`, `LIKE`, và phân loại mức lương sang cột mới bằng `CASE WHEN`.

## 1. Mục tiêu

- Dùng `WHERE` với toán tử so sánh (`>`, `<`).
- Dùng `BETWEEN` để lọc trong một khoảng.
- Dùng `IN` để lọc theo một tập hợp giá trị.
- Dùng `LIKE` với ký tự đại diện `%` để tìm chuỗi theo mẫu.
- Dùng `CASE WHEN` để phân loại dữ liệu sang một cột mới có Alias.

## 2. Chuẩn bị dữ liệu

```sql
CREATE TABLE Employees (
    EmpId   INT PRIMARY KEY,
    EmpName VARCHAR(100),
    Salary  DECIMAL(10, 2),
    DeptId  INT,
    Phone   VARCHAR(15)
);

INSERT INTO Employees (EmpId, EmpName, Salary, DeptId, Phone)
VALUES
    (101, 'Nguyễn Thị Mai',  800,  1, '0901112233'),
    (102, 'Trần Văn Hùng',   400,  2, '0912223344'),
    (103, 'Lê Hoàng Phúc',   1500, 1, '0923334455'),
    (104, 'Nguyễn Tuấn Anh', 2500, 3, '0934445566'),
    (105, 'Phạm Trà My',     600,  2, '0945556677');
```

Cột `Phone` dùng kiểu `VARCHAR` để giữ số `0` ở đầu.

## 3. Bước 1: Lọc cơ bản

```sql
SELECT *
FROM Employees
WHERE Salary > 800;
```

`>` là **lớn hơn hẳn**, nên nhân viên có lương đúng 800 (Nguyễn Thị Mai) **không** được lấy.

| EmpId | EmpName | Salary | DeptId | Phone |
|---|---|---|---|---|
| 103 | Lê Hoàng Phúc | 1500 | 1 | 0923334455 |
| 104 | Nguyễn Tuấn Anh | 2500 | 3 | 0934445566 |

## 4. Bước 2: Lọc theo khoảng (BETWEEN)

```sql
SELECT *
FROM Employees
WHERE Salary BETWEEN 500 AND 1500;
```

`BETWEEN` lấy **cả hai giá trị biên**, tương đương `Salary >= 500 AND Salary <= 1500`. Vì vậy lương 1500 (Lê Hoàng Phúc) vẫn được lấy.

| EmpId | EmpName | Salary | DeptId | Phone |
|---|---|---|---|---|
| 101 | Nguyễn Thị Mai | 800 | 1 | 0901112233 |
| 103 | Lê Hoàng Phúc | 1500 | 1 | 0923334455 |
| 105 | Phạm Trà My | 600 | 2 | 0945556677 |

## 5. Bước 3: Lọc theo tập hợp (IN)

```sql
SELECT *
FROM Employees
WHERE DeptId IN (1, 3);
```

`IN (1, 3)` tương đương `DeptId = 1 OR DeptId = 3`, nhưng gọn hơn và dễ mở rộng hơn.

| EmpId | EmpName | Salary | DeptId | Phone |
|---|---|---|---|---|
| 101 | Nguyễn Thị Mai | 800 | 1 | 0901112233 |
| 103 | Lê Hoàng Phúc | 1500 | 1 | 0923334455 |
| 104 | Nguyễn Tuấn Anh | 2500 | 3 | 0934445566 |

## 6. Bước 4: Lọc theo chuỗi (LIKE)

```sql
SELECT *
FROM Employees
WHERE EmpName LIKE 'Nguyễn%';
```

Mẫu `'Nguyễn%'` nghĩa là chuỗi **bắt đầu bằng** "Nguyễn", còn `%` đại diện cho **0 hoặc nhiều ký tự** bất kỳ phía sau. Không dùng `'%Nguyễn%'`, vì mẫu đó sẽ lấy cả những người có chữ "Nguyễn" ở giữa tên (ví dụ tên đệm), không đúng yêu cầu "mang họ Nguyễn".

| EmpId | EmpName | Salary | DeptId | Phone |
|---|---|---|---|---|
| 101 | Nguyễn Thị Mai | 800 | 1 | 0901112233 |
| 104 | Nguyễn Tuấn Anh | 2500 | 3 | 0934445566 |

## 7. Bước 5: Phân loại (CASE WHEN)

```sql
SELECT EmpId,
       EmpName,
       Salary,
       CASE
           WHEN Salary < 500  THEN 'Thực tập'
           WHEN Salary < 1000 THEN 'Nhân viên'
           WHEN Salary < 2000 THEN 'Trưởng nhóm'
           ELSE 'Quản lý'
       END AS SalaryLevel
FROM Employees;
```

- `CASE` xét các nhánh `WHEN` **lần lượt từ trên xuống** và **dừng ở nhánh đúng đầu tiên**. Ví dụ lương 400 thỏa cả `< 500`, `< 1000`, `< 2000`, nhưng chỉ nhận nhãn của nhánh đầu tiên là "Thực tập".
- Vì vậy các nhánh phải sắp **từ ngưỡng nhỏ đến lớn**. Nếu đặt `< 2000` lên đầu, mọi nhân viên lương dưới 2000 đều thành "Trưởng nhóm".
- Từ khóa **`END`** kết thúc khối `CASE`, sau đó mới đặt tên cột bằng `AS SalaryLevel`.

| EmpId | EmpName | Salary | SalaryLevel |
|---|---|---|---|
| 101 | Nguyễn Thị Mai | 800 | Nhân viên |
| 102 | Trần Văn Hùng | 400 | Thực tập |
| 103 | Lê Hoàng Phúc | 1500 | Trưởng nhóm |
| 104 | Nguyễn Tuấn Anh | 2500 | Quản lý |
| 105 | Phạm Trà My | 600 | Nhân viên |

## 8. Tự đánh giá

| Tiêu chí | Kết quả |
|---|---|
| Bước 4 dùng đúng mẫu chuỗi `'Nguyễn%'` | ✅ |
| Bước 5 có từ khóa `END` trước `AS SalaryLevel` | ✅ |
| Kết quả Bước 4 và Bước 5 khớp với Output mong đợi | ✅ |

## 9. Bài học rút ra

- `>` không lấy giá trị bằng, còn `BETWEEN` lấy cả hai biên.
- Dùng `IN` thay cho chuỗi `OR` khi so sánh một cột với nhiều giá trị.
- Vị trí `%` trong `LIKE` quyết định ý nghĩa: `'Nguyễn%'` là bắt đầu bằng, `'%Nguyễn'` là kết thúc bằng, `'%Nguyễn%'` là chứa.
- Trong `CASE WHEN`, thứ tự các nhánh rất quan trọng vì `CASE` dừng ở nhánh đúng đầu tiên.
