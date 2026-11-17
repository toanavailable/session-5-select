# Sắp xếp Kết quả Truy vấn với ORDER BY

Thực hành sắp xếp bảng `Students` theo điểm `Gpa` bằng `ORDER BY`, kiểm chứng chiều sắp xếp mặc định và sử dụng `ASC` / `DESC`.

## 1. Mục tiêu

- Dùng `ORDER BY` kết hợp `SELECT *` để sắp xếp toàn bộ bảng theo một cột.
- Kiểm chứng chiều sắp xếp mặc định khi không ghi từ khóa là **tăng dần**.
- Dùng `DESC` (giảm dần) và `ASC` (tăng dần) để đổi chiều sắp xếp.

## 2. Chuẩn bị dữ liệu

```sql
CREATE TABLE Students (
    StudentId INT PRIMARY KEY,
    FullName  VARCHAR(100),
    Major     VARCHAR(50),
    Gpa       DECIMAL(3, 1)
);

INSERT INTO Students (StudentId, FullName, Major, Gpa)
VALUES
    (101, 'Lê Quốc Bảo',     'IT',        8.5),
    (102, 'Trần Mai Phương', 'Design',    7.2),
    (103, 'Nguyễn Văn Tuấn', 'IT',        9.1),
    (104, 'Phạm Hải Yến',    'Design',    8.8),
    (105, 'Hoàng Minh Trí',  'Marketing', 7.5);
```

Cột `Gpa` dùng kiểu số `DECIMAL(3, 1)` để điểm được sắp xếp **theo giá trị số**. Nếu lưu điểm dạng chuỗi, kết quả sẽ sắp theo thứ tự từ điển và có thể sai, ví dụ `'10.0'` đứng trước `'9.1'`.

## 3. Bước 1: Kiểm chứng sắp xếp mặc định

```sql
SELECT *
FROM Students
ORDER BY Gpa;
```

Không ghi `ASC` hay `DESC`, hệ thống **mặc định sắp xếp tăng dần**, tức điểm thấp nhất đứng đầu:

| StudentId | FullName | Major | Gpa |
|---|---|---|---|
| 102 | Trần Mai Phương | Design | 7.2 |
| 105 | Hoàng Minh Trí | Marketing | 7.5 |
| 101 | Lê Quốc Bảo | IT | 8.5 |
| 104 | Phạm Hải Yến | Design | 8.8 |
| 103 | Nguyễn Văn Tuấn | IT | 9.1 |

## 4. Bước 2: Sắp xếp giảm dần (DESC)

```sql
SELECT *
FROM Students
ORDER BY Gpa DESC;
```

`DESC` đảo chiều sắp xếp, điểm **cao nhất** nằm ở dòng số 1:

| StudentId | FullName | Major | Gpa |
|---|---|---|---|
| 103 | Nguyễn Văn Tuấn | IT | 9.1 |
| 104 | Phạm Hải Yến | Design | 8.8 |
| 101 | Lê Quốc Bảo | IT | 8.5 |
| 105 | Hoàng Minh Trí | Marketing | 7.5 |
| 102 | Trần Mai Phương | Design | 7.2 |

## 5. Bước 3: Sắp xếp tăng dần (ASC)

```sql
SELECT *
FROM Students
ORDER BY Gpa ASC;
```

| StudentId | FullName | Major | Gpa |
|---|---|---|---|
| 102 | Trần Mai Phương | Design | 7.2 |
| 105 | Hoàng Minh Trí | Marketing | 7.5 |
| 101 | Lê Quốc Bảo | IT | 8.5 |
| 104 | Phạm Hải Yến | Design | 8.8 |
| 103 | Nguyễn Văn Tuấn | IT | 9.1 |

### So sánh Bước 1 và Bước 3

Kết quả của Bước 3 **giống hệt** Bước 1. Điều này chứng minh `ORDER BY Gpa` và `ORDER BY Gpa ASC` là tương đương: khi không ghi gì, SQL tự hiểu là `ASC`.

| Câu lệnh | Chiều sắp xếp | Dòng đầu tiên |
|---|---|---|
| `ORDER BY Gpa` | Tăng dần (mặc định) | Trần Mai Phương, 7.2 |
| `ORDER BY Gpa DESC` | Giảm dần | Nguyễn Văn Tuấn, 9.1 |
| `ORDER BY Gpa ASC` | Tăng dần | Trần Mai Phương, 7.2 |

## 6. Tự đánh giá

| Tiêu chí | Kết quả |
|---|---|
| `ORDER BY` đặt ở cuối câu lệnh, sau `FROM` | ✅ |
| Bước 1 sắp xếp tăng dần, giống hệt Bước 3 dùng `ASC` | ✅ |
| Bước 2 khớp Output mong đợi, người điểm cao nhất ở dòng số 1 | ✅ |

## 7. Bài học rút ra

- `ORDER BY` luôn đứng **cuối** câu truy vấn, sau `FROM` (và sau `WHERE` nếu có).
- Chiều sắp xếp mặc định là **`ASC`** (tăng dần). Muốn giảm dần phải ghi rõ **`DESC`**.
- `ORDER BY` chỉ đổi **thứ tự các dòng**, không thêm, bớt hay thay đổi dữ liệu.
- Cột dùng để sắp xếp nên có **kiểu số** nếu là điểm, lương, số lượng… để tránh sắp xếp theo thứ tự từ điển.
