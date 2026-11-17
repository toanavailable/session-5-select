# Vá lỗi "Top Quán Ăn Mới Nổi" trên Trang chủ

Phân tích lỗi câu lệnh `SELECT ... LIMIT 5` khiến dải banner "Top 5 quán mới lên sàn" hiển thị ngẫu nhiên các quán cũ, và viết lại câu lệnh đúng yêu cầu của Product Owner (PO).

## 1. Bối cảnh

- **Yêu cầu của PO:** lấy đúng **5 nhà hàng được thêm vào hệ thống gần đây nhất**, dựa trên cột `created_at`.
- **Thực tế:** mỗi lần khách hàng tải lại app, danh sách 5 quán lại hiển thị ngẫu nhiên các quán từ năm ngoái, không cố định và không phải quán mới nhất.

Đoạn code gây lỗi:

```sql
SELECT restaurant_name, created_at
FROM Restaurants
LIMIT 5;
```

## 2. Phân tích nguyên nhân

### `LIMIT` không có `ORDER BY` để neo giữ thứ tự

`LIMIT 5` chỉ có nghĩa là **"cắt lấy 5 dòng đầu tiên"** của kết quả. Nó **không** biết "mới nhất" là gì. Câu hỏi quan trọng là "5 dòng đầu" tính theo thứ tự nào?

Theo chuẩn SQL, một bảng là **tập hợp không có thứ tự**. Khi không có `ORDER BY`, Database **không cam kết** trả về dòng theo bất kỳ thứ tự nào. Nó trả về theo cách nào tiện nhất lúc đó, và cách này phụ thuộc vào:

- thứ tự lưu vật lý trên ổ đĩa (thường là quán thêm vào **sớm nhất** nằm đầu, tức các quán từ năm ngoái);
- Index mà bộ tối ưu truy vấn (query optimizer) chọn dùng;
- dữ liệu đang có sẵn trong bộ nhớ đệm (cache), các thao tác `INSERT`/`DELETE`/`UPDATE` làm phân mảnh trang dữ liệu, truy vấn chạy song song…

Vì vậy kết quả **không ổn định** giữa các lần refresh và **không phải** 5 quán mới nhất. Câu lệnh vẫn **đúng cú pháp** nên Database không báo lỗi gì, đây là một lỗi **logic** khó phát hiện ở môi trường test có ít dữ liệu.

### Thứ tự thực thi logic

```
FROM → WHERE → SELECT → ORDER BY → LIMIT
```

`LIMIT` chạy **sau cùng**, cắt trên kết quả mà bước `ORDER BY` để lại. Nếu bỏ `ORDER BY`, `LIMIT` cắt trên một danh sách **chưa được sắp xếp**, nên 5 dòng lấy ra là 5 dòng bất kỳ.

### Dò luồng (trace) với dữ liệu mẫu

Dữ liệu được thêm vào theo thứ tự `restaurant_id` tăng dần:

| restaurant_id | restaurant_name | created_at | Code lỗi (thường gặp) | Mong muốn |
|---|---|---|---|---|
| 1 | Phở Hùng | 2025-03-10 | ❌ Lấy | Loại |
| 2 | Cơm Tấm Sài Gòn | 2025-06-22 | ❌ Lấy | Loại |
| 3 | Bún Bò Cô Ba | 2025-09-05 | ❌ Lấy | Loại |
| 4 | Ốc Đào | 2025-12-18 | ❌ Lấy | Loại |
| 5 | Lẩu Dê 404 | 2026-02-14 | ✅ Lấy | ✅ Lấy |
| 6 | Bánh Mì Huỳnh Hoa | 2026-05-01 | Loại | ✅ Lấy |
| 7 | Gà Rán Ông Tám | 2026-08-09 | Loại | ✅ Lấy |
| 8 | Trà Sữa Mây | 2026-10-20 | Loại | ✅ Lấy |
| 9 | Bò Né 3 Ngon | 2026-11-15 | Loại | ✅ Lấy |

Code lỗi thường lấy 5 quán **cũ nhất** (theo thứ tự lưu), và khi dữ liệu bị xóa hoặc sửa, nó có thể trả về 5 quán bất kỳ khác.

## 3. Mã lệnh đã sửa

Thêm `ORDER BY created_at DESC` để sắp xếp quán **mới nhất lên đầu**, sau đó `LIMIT 5` mới cắt lấy 5 dòng:

```sql
SELECT restaurant_name, created_at
FROM Restaurants
ORDER BY created_at DESC, restaurant_id DESC
LIMIT 5;
```

Cột phụ `restaurant_id DESC` dùng để **phân định thứ tự** khi có nhiều quán trùng `created_at`, ví dụ khi được import cùng lúc. Nhờ vậy kết quả luôn cố định giữa các lần refresh.

Để truy vấn chạy nhanh khi bảng có hàng triệu dòng, nên tạo Index trên cột sắp xếp. Database khi đó chỉ cần đọc 5 dòng đầu của Index thay vì sắp xếp toàn bộ bảng:

```sql
CREATE INDEX idx_restaurants_created_at
ON Restaurants (created_at DESC, restaurant_id DESC);
```

Kết quả sau khi chạy với dữ liệu mẫu:

| restaurant_name | created_at |
|---|---|
| Bò Né 3 Ngon | 2026-11-15 |
| Trà Sữa Mây | 2026-10-20 |
| Gà Rán Ông Tám | 2026-08-09 |
| Bánh Mì Huỳnh Hoa | 2026-05-01 |
| Lẩu Dê 404 | 2026-02-14 |

## 4. Bài học rút ra

- **`LIMIT` luôn phải đi kèm `ORDER BY`**. Không có `ORDER BY` thì "N dòng đầu tiên" là vô nghĩa, vì thứ tự không được đảm bảo.
- Dùng **cột phụ có giá trị duy nhất** (như khóa chính) trong `ORDER BY` để kết quả ổn định khi cột chính bị trùng.
- Tạo **Index** trên cột dùng để sắp xếp, để truy vấn Top-N vẫn nhanh khi dữ liệu lớn.
- Kiểm thử với **dữ liệu đủ lớn và đã qua xóa/sửa**. Bảng nhỏ, mới tạo thường "tình cờ" trả về đúng thứ tự, khiến lỗi không bị phát hiện ở môi trường test.
