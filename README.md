# Tool "Đánh nhãn Khách Hàng Tự Động" (Auto Tagging)

Viết một câu SQL tự động xếp hạng độ trung thành của khách hàng dựa trên số đơn đã đặt (`total_orders`), xử lý an toàn những khách hàng mới có `total_orders` là `NULL`, để đội Marketing gửi email sinh nhật đúng nội dung.

## 1. Bối cảnh

- **Vấn đề:** Marketing muốn gửi email chúc mừng sinh nhật với nội dung khác nhau theo **độ trung thành**. Bảng `Users` chỉ lưu `total_orders`, và đội Marketing không biết code.
- **Yêu cầu đầu ra:** đúng **2 cột** là `Tên_Khách_Hàng` và cột mới `Xep_Hang`.
- **Nghiệp vụ rẽ nhánh:**

| Điều kiện | Xep_Hang |
|---|---|
| Trên 500 đơn (`> 500`) | Kim Cương |
| Từ 100 đến 500 đơn (`100 – 500`) | Vàng |
| Dưới 100 đơn (`< 100`) | Bạc |

- **Bẫy dữ liệu:** khách hàng vừa đăng ký có `total_orders` là `NULL`, chưa được gán số 0.

## 2. Giải pháp kiến trúc: biểu thức `CASE WHEN`

Để rẽ nhánh logic ngay trong câu lệnh `SELECT`, dùng biểu thức **`CASE WHEN ... THEN ... ELSE ... END`**, kết hợp **`AS`** để đặt tên cho cột mới:

```sql
CASE
    WHEN điều_kiện_1 THEN kết_quả_1
    WHEN điều_kiện_2 THEN kết_quả_2
    ELSE kết_quả_mặc_định
END AS Xep_Hang
```

- `CASE` hoạt động giống `if / else if / else` trong lập trình, nhưng chạy **cho từng dòng** dữ liệu.
- Các nhánh `WHEN` được xét **lần lượt từ trên xuống**. Gặp nhánh đầu tiên đúng thì trả về kết quả và **dừng lại**, không xét các nhánh sau.
- Nếu không nhánh nào đúng, `CASE` trả về giá trị của `ELSE`. Nếu không có `ELSE` thì trả về `NULL`.
- `AS Xep_Hang` đặt tên cho kết quả. Đây là **cột ảo (cột tính toán)**: chỉ tồn tại trong kết quả truy vấn, không làm thay đổi cấu trúc bảng `Users` và không cần lưu thêm dữ liệu.

### Thiết kế thứ tự nhánh

Vì `CASE` dừng ở nhánh đúng **đầu tiên**, các nhánh được sắp **từ ngưỡng cao xuống thấp**:

1. `total_orders > 500` cho ra **Kim Cương**.
2. `total_orders >= 100` cho ra **Vàng**. Đến được nhánh này nghĩa là đã chắc chắn `<= 500`, nên không cần viết `BETWEEN 100 AND 500`.
3. `total_orders >= 0` cho ra **Bạc**.

Nếu đảo thứ tự, ví dụ đặt `>= 100` lên đầu, khách 800 đơn sẽ khớp ngay nhánh "Vàng" và không bao giờ được xếp "Kim Cương".

Kiểm tra các giá trị biên:

| total_orders | Nhánh khớp | Xep_Hang |
|---|---|---|
| 501 | `> 500` | Kim Cương |
| 500 | `>= 100` | Vàng |
| 100 | `>= 100` | Vàng |
| 99 | `>= 0` | Bạc |
| 0 | `>= 0` | Bạc |

## 3. Xử lý ngoại lệ: luồng bắt dữ liệu `NULL`

### Chuyện gì xảy ra nếu không xử lý?

`NULL` nghĩa là "không xác định", nên mọi phép so sánh `NULL > 500`, `NULL >= 100`, `NULL < 100` đều cho kết quả **UNKNOWN**, không phải TRUE. Vì vậy **không nhánh `WHEN` nào khớp**, và kết quả phụ thuộc vào cách viết `ELSE`:

| Cách viết | Kết quả với `NULL` | Vấn đề |
|---|---|---|
| Không có `ELSE` | `NULL` | Email in ra "Hạng: (trống)" hoặc báo cáo bị lỗi |
| `WHEN total_orders < 100 THEN 'Bạc'` không có `ELSE` | `NULL` | `NULL < 100` là UNKNOWN, nên vẫn trống |
| `ELSE 'Bạc'` | Bạc | Trông có vẻ đúng nhưng là **đúng tình cờ**: mọi dữ liệu bất thường (số âm…) cũng bị gán "Bạc" mà không ai biết |

### Luồng xử lý đề xuất

Bắt `NULL` **chủ động** ngay từ đầu, thay vì để nó rơi tự nhiên vào `ELSE`:

1. **Nhánh đầu tiên `WHEN total_orders IS NULL`:** khách vừa đăng ký và chưa có đơn nào, về nghiệp vụ là **0 đơn**, nên được xếp **Bạc**. Phải dùng `IS NULL`, vì `= NULL` không bao giờ đúng.
2. **Các nhánh nghiệp vụ** `> 500`, `>= 100`, `>= 0` xử lý dữ liệu hợp lệ.
3. **`ELSE 'Kiểm tra lại'`:** chỉ còn bắt các **dữ liệu dị biệt thực sự** như số đơn âm do lỗi hệ thống. Những khách này không bị gán nhầm nhãn mà được đánh dấu để đội kỹ thuật kiểm tra.

Cách này đảm bảo:

- Khách mới **luôn có nhãn**, không có ô trống trong báo cáo.
- Lý do khách mới được xếp "Bạc" được viết **rõ ràng trong code**, không phụ thuộc vào `ELSE`.
- Dữ liệu lỗi được **phát hiện** thay vì bị che giấu.

> **Cách thay thế:** nếu Marketing muốn email riêng cho khách mới, chỉ cần đổi nhánh đầu thành `WHEN total_orders IS NULL THEN 'Khách Mới'`. Một cách khác là dùng `COALESCE(total_orders, 0)` để đổi `NULL` thành 0 trước khi so sánh, nhưng khi đó số âm vẫn cần được bắt riêng.

## 4. Code hoàn chỉnh

```sql
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
```

- Tên cột `Tên_Khách_Hàng` có dấu tiếng Việt nên được đặt trong dấu backtick `` ` `` để MySQL đọc đúng.
- Câu lệnh chỉ trả về đúng **2 cột** theo yêu cầu.

### Dò luồng (trace) với dữ liệu mẫu

| user_id | full_name | total_orders | Nhánh khớp | Xep_Hang |
|---|---|---|---|---|
| 1 | Nguyễn Văn An | 1200 | `> 500` | Kim Cương |
| 2 | Trần Thị Bình | 501 | `> 500` | Kim Cương |
| 3 | Lê Văn Cường | 500 | `>= 100` | Vàng |
| 4 | Phạm Minh Đức | 100 | `>= 100` | Vàng |
| 5 | Hoàng Văn Em | 99 | `>= 0` | Bạc |
| 6 | Võ Thị Phương | 0 | `>= 0` | Bạc |
| 7 | Đặng Văn Giang | NULL | `IS NULL` | Bạc |
| 8 | Bùi Thị Hoa | NULL | `IS NULL` | Bạc |
| 9 | Đỗ Văn Khoa | -5 | `ELSE` | Kiểm tra lại |

Kết quả trả về cho Marketing:

| Tên_Khách_Hàng | Xep_Hang |
|---|---|
| Nguyễn Văn An | Kim Cương |
| Trần Thị Bình | Kim Cương |
| Lê Văn Cường | Vàng |
| Phạm Minh Đức | Vàng |
| Hoàng Văn Em | Bạc |
| Võ Thị Phương | Bạc |
| Đặng Văn Giang | Bạc |
| Bùi Thị Hoa | Bạc |
| Đỗ Văn Khoa | Kiểm tra lại |

## 5. Bài học rút ra

- Dùng **`CASE WHEN`** để rẽ nhánh và tạo **cột ảo** ngay trong `SELECT`, không cần sửa cấu trúc bảng.
- `CASE` dừng ở nhánh đúng **đầu tiên**, nên phải sắp các nhánh **từ ngưỡng cao xuống thấp** và kiểm tra kỹ các giá trị biên (100, 500).
- **Bắt `NULL` chủ động** bằng `IS NULL` ở nhánh đầu tiên, đừng để nó "tình cờ" rơi vào `ELSE`.
- Dành `ELSE` để **phát hiện dữ liệu bất thường**, thay vì gán bừa một nhãn hợp lệ.
- Về lâu dài, nên sửa thiết kế bảng: `total_orders INT NOT NULL DEFAULT 0` để khách mới luôn có giá trị 0, và thêm `CHECK (total_orders >= 0)` để chặn số âm.
