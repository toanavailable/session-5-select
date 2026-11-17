# Sửa lỗi Module "Khuyến mãi ngẫu nhiên"

Phân tích lỗi câu lệnh `SELECT` khiến danh sách "Freeship Bữa Trưa" lẫn cả những quán ở Quận 1 bị đánh giá thấp, và viết lại câu lệnh đúng nghiệp vụ của phòng Marketing.

## 1. Bối cảnh

- **Yêu cầu của Marketing:** lấy các nhà hàng nằm ở **'Quận 1' HOẶC 'Quận 3'**, **ĐỒNG THỜI** có điểm đánh giá `rating` **lớn hơn 4.0**.
- **Thực tế:** danh sách hiển thị cả những quán ở Quận 1 có rating rất thấp (2.0 – 3.0), gây phẫn nộ cho khách hàng VIP.

Đoạn code gây lỗi:

```sql
SELECT restaurant_name, address, rating
FROM Restaurants
WHERE district = 'Quận 1' OR district = 'Quận 3' AND rating > 4.0;
```

## 2. Phân tích nguyên nhân

### Thứ tự ưu tiên của toán tử `AND` và `OR`

Trong SQL, **`AND` có độ ưu tiên cao hơn `OR`**, giống như phép nhân được tính trước phép cộng trong toán học. Khi không có ngoặc đơn, MySQL sẽ gom `AND` lại trước, nên câu lệnh trên thực chất được hiểu là:

```sql
WHERE district = 'Quận 1'
   OR (district = 'Quận 3' AND rating > 4.0);
```

Hệ quả:

- **Quận 3:** chỉ lấy quán có rating > 4.0, **đúng** yêu cầu.
- **Quận 1:** lấy **tất cả** các quán, **bất kể rating**, vì điều kiện `rating > 4.0` chỉ gắn với Quận 3.

Câu lệnh vẫn **đúng cú pháp**, nên MySQL chạy mà không báo lỗi gì. Lỗi nằm ở **logic**: Fresher viết theo thứ tự đọc của tiếng Việt ("Quận 1 hoặc Quận 3, và rating > 4"), nhưng SQL lại không đọc theo thứ tự đó.

### Dò luồng (trace) với dữ liệu mẫu

| restaurant_name | district | rating | Code lỗi | Mong muốn |
|---|---|---|---|---|
| Phở Hùng | Quận 1 | 4.5 | ✅ Lấy | ✅ Lấy |
| Cơm Tấm Sài Gòn | Quận 1 | 2.5 | ❌ Lấy | Loại |
| Bún Bò Cô Ba | Quận 1 | 3.0 | ❌ Lấy | Loại |
| Bánh Mì Huỳnh Hoa | Quận 3 | 4.8 | ✅ Lấy | ✅ Lấy |
| Ốc Đào | Quận 3 | 3.5 | Loại | Loại |
| Lẩu Dê 404 | Quận 5 | 4.9 | Loại | Loại |

Hai quán Quận 1 có rating 2.5 và 3.0 lọt vào danh sách, đúng như Marketing báo cáo.

## 3. Mã lệnh đã sửa

Dùng **ngoặc đơn** để buộc MySQL xét điều kiện quận trước, sau đó mới kết hợp với điều kiện rating:

```sql
SELECT restaurant_name, address, rating
FROM Restaurants
WHERE (district = 'Quận 1' OR district = 'Quận 3')
  AND rating > 4.0;
```

Cách viết gọn và dễ đọc hơn là dùng `IN`. Cách này không cần nhớ thứ tự ưu tiên của `OR`:

```sql
SELECT restaurant_name, address, rating
FROM Restaurants
WHERE district IN ('Quận 1', 'Quận 3')
  AND rating > 4.0;
```

Kết quả sau khi chạy với dữ liệu mẫu:

| restaurant_name | address | rating |
|---|---|---|
| Phở Hùng | 12 Lê Lợi, Quận 1 | 4.5 |
| Bánh Mì Huỳnh Hoa | 26 Lê Thị Riêng, Quận 3 | 4.8 |

## 4. Bài học rút ra

- **`AND` được ưu tiên hơn `OR`.** Khi một điều kiện có cả `AND` lẫn `OR`, **luôn dùng ngoặc đơn** để thể hiện rõ ý định, kể cả khi bạn nghĩ là không cần.
- Khi so sánh một cột với nhiều giá trị, ưu tiên dùng **`IN (...)`** thay cho chuỗi `OR`, vừa gọn vừa tránh lỗi ưu tiên toán tử.
- Trước khi đưa lên môi trường thật, hãy **trace với dữ liệu mẫu có cả trường hợp biên**, ví dụ quán đúng quận nhưng rating thấp, hoặc rating cao nhưng sai quận.
