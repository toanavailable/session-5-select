# Tối ưu bộ lọc "Đơn hàng thất bại"

So sánh hai cách lọc đơn hàng theo danh sách nguyên nhân thất bại (`OR` liên tiếp và `IN`), phân tích bẫy `NULL` trong `IN`, và viết câu truy vấn tốt nhất cho phòng Chăm sóc khách hàng (CSKH).

## 1. Bối cảnh

- **Yêu cầu của CSKH:** theo dõi toàn bộ đơn hàng (`Orders`) thất bại do 4 nguyên nhân: `'KHACH_HUY'`, `'QUAN_DONG_CUA'`, `'KHONG_CO_TAI_XE'`, `'BOM_HANG'`.
- **Nghiệp vụ:** hệ thống nhận vào một mảng các nguyên nhân và yêu cầu CSDL trả về danh sách đơn tương ứng.
- **Bẫy dữ liệu:** một số đơn bị hủy do rớt mạng nên cột `cancel_reason` bị trống (`NULL`). CSKH yêu cầu danh sách phải có cả những đơn này.

## 2. Đề xuất giải pháp

### Giải pháp 1: Dùng `=` kết hợp `OR`

```sql
SELECT order_id, customer_name, cancel_reason, created_at
FROM Orders
WHERE cancel_reason = 'KHACH_HUY'
   OR cancel_reason = 'QUAN_DONG_CUA'
   OR cancel_reason = 'KHONG_CO_TAI_XE'
   OR cancel_reason = 'BOM_HANG';
```

### Giải pháp 2: Dùng toán tử tập hợp `IN (...)`

```sql
SELECT order_id, customer_name, cancel_reason, created_at
FROM Orders
WHERE cancel_reason IN ('KHACH_HUY', 'QUAN_DONG_CUA', 'KHONG_CO_TAI_XE', 'BOM_HANG');
```

Với dữ liệu không có `NULL`, hai cách viết cho **kết quả giống hệt nhau**: `x IN (a, b, c)` tương đương `x = a OR x = b OR x = c`. Khác biệt nằm ở độ sạch của code, khả năng mở rộng và cách SQL Engine xử lý.

## 3. Bảng so sánh

| Tiêu chí | Giải pháp 1: `=` + `OR` | Giải pháp 2: `IN (...)` |
|---|---|---|
| **Mức độ code sạch** | ❌ Lặp lại tên cột `cancel_reason` ở mỗi điều kiện, câu lệnh dài và rối. Dễ gõ sai tên cột ở một dòng mà khó phát hiện. | ✅ Tên cột chỉ viết một lần, danh sách giá trị gom gọn trong ngoặc. Đọc vào là hiểu ngay "nguyên nhân thuộc danh sách này". |
| **Khả năng mở rộng (20 nguyên nhân)** | ❌ Cần 20 điều kiện và 19 lần `OR`. Khi ghép thêm điều kiện khác bằng `AND` (ví dụ lọc theo ngày), rất dễ quên ngoặc đơn và dính lỗi ưu tiên `AND` hơn `OR`. Tầng ứng dụng phải tự nối chuỗi `OR` từ mảng, dễ sinh lỗi. | ✅ Chỉ cần thêm giá trị vào danh sách. Toàn bộ `IN (...)` là **một điều kiện duy nhất**, nên ghép với `AND` không bị lỗi ưu tiên toán tử. Ánh xạ trực tiếp từ mảng đầu vào: mảng có bao nhiêu phần tử thì truyền bấy nhiêu tham số `?`. |
| **Hiệu năng biên dịch của SQL Engine** | ⚠️ Câu lệnh dài hơn nên bộ phân tích cú pháp (parser) phải xử lý nhiều nút điều kiện hơn. Khi chạy, mỗi dòng có thể phải so sánh lần lượt với từng điều kiện. Các bộ tối ưu hiện đại thường viết lại các `OR` trên cùng một cột thành dạng tương đương `IN`, nhưng đó là việc thêm mà Engine phải làm. | ✅ Engine nhận ra ngay đây là một danh sách hằng số. MySQL **sắp xếp sẵn danh sách và tìm bằng tìm kiếm nhị phân** (binary search), nên khi danh sách dài, mỗi dòng chỉ cần khoảng log₂(n) lần so sánh. Nếu có Index trên `cancel_reason`, Engine dùng các khoảng tra cứu (range) trên Index. |

**Kết luận:** chọn **Giải pháp 2 (`IN`)** vì code sạch hơn, mở rộng dễ hơn, an toàn hơn khi kết hợp với `AND`, và hiệu năng ít nhất là ngang bằng (thường tốt hơn khi danh sách dài).

## 4. Xử lý bẫy `NULL`

### Nhét `NULL` vào trong `IN` có lấy được đơn hàng không?

```sql
WHERE cancel_reason IN ('KHACH_HUY', 'QUAN_DONG_CUA', 'KHONG_CO_TAI_XE', 'BOM_HANG', NULL)
```

**Không lấy được.** Lý do: `IN` thực chất là chuỗi phép so sánh `=`:

```sql
cancel_reason = 'KHACH_HUY' OR ... OR cancel_reason = NULL
```

Trong SQL, `NULL` nghĩa là "không xác định". Mọi phép so sánh với `NULL` bằng `=` đều cho kết quả **UNKNOWN**, không phải TRUE, kể cả `NULL = NULL`. Với một đơn có `cancel_reason` là `NULL`:

- `NULL = 'KHACH_HUY'` cho ra UNKNOWN, và tương tự với 3 nguyên nhân còn lại.
- `NULL = NULL` cũng cho ra UNKNOWN.

Gộp lại, toàn bộ biểu thức là UNKNOWN. `WHERE` chỉ giữ lại dòng có điều kiện **TRUE**, nên các đơn "vô định" **bị loại**. Câu lệnh vẫn chạy không báo lỗi, nên lỗi này rất khó phát hiện.

> Bẫy ngược lại còn nguy hiểm hơn: `NOT IN (..., NULL)` sẽ trả về **0 dòng** với mọi dữ liệu, vì điều kiện `cancel_reason <> NULL` luôn là UNKNOWN.

### Cách đúng: tách riêng `IS NULL`

Phải kiểm tra `NULL` bằng toán tử `IS NULL` và nối với `IN` bằng `OR`, **đặt cả hai trong ngoặc đơn**.

### Bẫy phụ: đơn thành công cũng có `cancel_reason` là `NULL`

Đơn giao thành công không có lý do hủy, nên cột `cancel_reason` của chúng **cũng là `NULL`**. Nếu chỉ viết `cancel_reason IS NULL`, danh sách sẽ lẫn toàn bộ đơn thành công. Vì vậy phải lọc thêm theo trạng thái đơn `status = 'FAILED'` để chỉ lấy đơn thất bại.

## 5. Câu truy vấn tốt nhất

```sql
SELECT order_id, customer_name, status, cancel_reason, created_at
FROM Orders
WHERE status = 'FAILED'
  AND (
        cancel_reason IN ('KHACH_HUY', 'QUAN_DONG_CUA', 'KHONG_CO_TAI_XE', 'BOM_HANG')
        OR cancel_reason IS NULL
      )
ORDER BY created_at DESC;
```

- `status = 'FAILED'`: chỉ lấy đơn thất bại, loại đơn thành công có `cancel_reason` là `NULL`.
- `IN (...)`: lấy đơn có nguyên nhân thuộc danh sách. Ở tầng ứng dụng, truyền mảng đầu vào dưới dạng tham số `IN (?, ?, ?, ?)` thay vì nối chuỗi trực tiếp, để tránh lỗi SQL Injection.
- `OR cancel_reason IS NULL`: lấy thêm các đơn "vô định" do rớt mạng.
- **Ngoặc đơn bắt buộc:** nếu thiếu, `AND` được ưu tiên hơn `OR`, câu lệnh bị hiểu thành `(status = 'FAILED' AND cancel_reason IN (...)) OR cancel_reason IS NULL`, và lại lẫn toàn bộ đơn thành công.
- `ORDER BY created_at DESC`: đơn mới nhất lên đầu để CSKH xử lý trước.

### Dò luồng (trace) với dữ liệu mẫu

| order_id | status | cancel_reason | `IN` có `NULL` | Câu truy vấn tốt nhất |
|---|---|---|---|---|
| 1 | FAILED | KHACH_HUY | ✅ Lấy | ✅ Lấy |
| 2 | FAILED | QUAN_DONG_CUA | ✅ Lấy | ✅ Lấy |
| 3 | FAILED | KHONG_CO_TAI_XE | ✅ Lấy | ✅ Lấy |
| 4 | FAILED | BOM_HANG | ✅ Lấy | ✅ Lấy |
| 5 | FAILED | NULL (rớt mạng) | ❌ Bỏ sót | ✅ Lấy |
| 6 | FAILED | NULL (rớt mạng) | ❌ Bỏ sót | ✅ Lấy |
| 7 | FAILED | SAI_DIA_CHI | Loại | Loại (không thuộc danh sách) |
| 8 | COMPLETED | NULL | Loại | Loại (đơn thành công) |
| 9 | COMPLETED | NULL | Loại | Loại (đơn thành công) |

Câu truy vấn tốt nhất trả về đúng 6 đơn: 4 đơn có nguyên nhân thuộc danh sách và 2 đơn "vô định".

## 6. Bài học rút ra

- Khi so sánh **một cột với nhiều giá trị**, ưu tiên `IN (...)` thay cho chuỗi `OR`: code sạch hơn, dễ mở rộng và an toàn hơn khi kết hợp với `AND`.
- **`NULL` không bao giờ "bằng" thứ gì**, kể cả trong `IN`. Luôn dùng `IS NULL` / `IS NOT NULL`.
- Đừng dùng `NOT IN` với danh sách có thể chứa `NULL`, vì kết quả sẽ luôn rỗng.
- Khi trộn `AND` và `OR`, **luôn dùng ngoặc đơn**.
- Cột có thể `NULL` vì nhiều lý do khác nhau (đơn thành công, lỗi ghi nhận…). Cần thêm điều kiện khác, như `status`, để phân biệt đúng ý nghĩa của `NULL`.
