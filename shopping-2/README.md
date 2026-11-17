# Logic gán đơn tự động cho Tài xế (Driver Matching)

Phân tích và viết câu lệnh SQL lọc, sắp xếp đa tầng để chọn tài xế phù hợp cho đơn hàng mới, đồng thời đặt "chốt chặn an toàn" chống lỗi cấu hình điểm tín nhiệm âm.

## 1. Bối cảnh

- **Vấn đề:** khách hàng phàn nàn đồ ăn nguội vì app hay gán đơn cho tài xế **ở quá xa** hoặc **đang bị khóa tài khoản**.
- **Yêu cầu nghiệp vụ:** khi có đơn mới, quét bảng `Drivers` và trả về các tài xế thỏa mãn **MỌI** điều kiện:
  1. `status` là `'AVAILABLE'`.
  2. `trust_score` từ **80 điểm trở lên**.
  3. Sắp xếp tài xế **gần quán nhất** (`distance_km`) lên đầu. Nếu trùng khoảng cách, ai có **điểm tín nhiệm cao hơn** xếp trên.
- **Bẫy dữ liệu:** ngưỡng `min_trust_score` được lấy từ cấu hình hệ thống. Nếu Admin nhập nhầm thành số âm (ví dụ `-10`) thì sao?

## 2. Phân tích Logic & Dữ liệu

### Input và Output

| Vai trò | Cột | Mục đích |
|---|---|---|
| Lọc | `status` | Chỉ lấy tài xế `'AVAILABLE'`, loại tài xế bị khóa, đang bận, offline |
| Lọc | `trust_score` | Chỉ lấy tài xế có điểm tín nhiệm đạt ngưỡng |
| Lọc | `distance_km` | Loại dòng chưa có vị trí (`NULL`), vì không tính được khoảng cách |
| Sắp xếp | `distance_km` | Tầng 1: gần nhất lên đầu (`ASC`) |
| Sắp xếp | `trust_score` | Tầng 2: điểm cao hơn xếp trên khi trùng khoảng cách (`DESC`) |
| Sắp xếp | `driver_id` | Tầng 3: phân định cuối cùng để kết quả luôn cố định |
| Tham số | `@min_trust_score` | Ngưỡng điểm lấy từ cấu hình hệ thống |

**Output:** `driver_id` (để gán đơn), `driver_name`, `phone` (để liên hệ), `distance_km` và `trust_score` (để hiển thị và kiểm tra lý do được chọn). Chỉ lấy đúng các cột cần thiết, không dùng `SELECT *`.

### Luồng thực thi của Database Engine

```
FROM Drivers → WHERE (lọc) → SELECT (chọn cột) → ORDER BY (sắp xếp đa tầng) → LIMIT
```

**Bước 1: `WHERE` gom nhóm điều kiện.** Tất cả điều kiện nối với nhau bằng `AND`, nên một tài xế phải đạt **cùng lúc** mọi điều kiện mới được giữ lại. Chỉ cần sai một điều kiện là bị loại ngay. Câu lệnh không có `OR`, nên không bị lỗi ưu tiên toán tử `AND`/`OR`. Lọc ở `WHERE` trước giúp bước sắp xếp phía sau chỉ phải làm việc trên tập dữ liệu nhỏ.

**Bước 2: `ORDER BY` phân giải trùng lặp (tie-breaker).** `ORDER BY` sắp xếp theo từng tầng, mỗi tầng sau chỉ được dùng khi các dòng **bằng nhau ở tất cả các tầng trước**:

1. `distance_km ASC`: quyết định chính, tài xế gần quán nhất đứng đầu.
2. `trust_score DESC`: chỉ dùng khi hai tài xế trùng `distance_km`. Ví dụ hai người cùng cách 1.5 km thì người điểm 95 đứng trên người điểm 85.
3. `driver_id ASC`: chỉ dùng khi trùng cả khoảng cách lẫn điểm. Nếu thiếu tầng này, Database có thể trả về hai tài xế đó theo thứ tự khác nhau ở mỗi lần chạy, khiến đơn bị gán không nhất quán.

### Bẫy điểm âm

Nếu viết thẳng `WHERE trust_score >= @min_trust_score` và Admin nhập `-10`, điều kiện trở thành `trust_score >= -10`. Điều kiện này **đúng với mọi tài xế**, nên bộ lọc điểm tín nhiệm **mất tác dụng hoàn toàn**: tài xế 30 điểm, 50 điểm đều lọt vào danh sách và có thể được xếp đầu chỉ vì đứng gần quán. Câu lệnh vẫn chạy bình thường, không báo lỗi gì.

Tương tự, nếu cấu hình bị trống (`NULL`), điều kiện `trust_score >= NULL` luôn cho kết quả UNKNOWN, nên **không tài xế nào** được trả về và toàn bộ đơn hàng bị kẹt.

### Chốt chặn an toàn

Biến ngưỡng điểm thành **mức sàn không thể thấp hơn 80**:

```sql
trust_score >= GREATEST(COALESCE(@min_trust_score, 80), 80)
```

- `COALESCE(@min_trust_score, 80)`: nếu cấu hình bị `NULL` thì dùng mặc định 80.
- `GREATEST(..., 80)`: lấy giá trị **lớn hơn** giữa cấu hình và 80.

| `@min_trust_score` | Ngưỡng thực tế | Ý nghĩa |
|---|---|---|
| `-10` (nhập nhầm) | 80 | Bị chặn, vẫn giữ mức sàn nghiệp vụ |
| `NULL` (trống) | 80 | Dùng giá trị mặc định |
| `50` (quá thấp) | 80 | Không cho phép hạ dưới mức sàn |
| `90` (siết chặt) | 90 | Admin vẫn được phép nâng ngưỡng cao hơn |

Chốt chặn này nằm ngay trong câu lệnh SQL, nên dù tầng ứng dụng có quên kiểm tra dữ liệu đầu vào thì nghiệp vụ "từ 80 điểm trở lên" vẫn luôn được đảm bảo.

## 3. Triển khai

```sql
SET @min_trust_score = -10;   -- giá trị lấy từ cấu hình (giả lập Admin nhập nhầm)

SELECT driver_id, driver_name, phone, distance_km, trust_score
FROM Drivers
WHERE status = 'AVAILABLE'
  AND trust_score >= GREATEST(COALESCE(@min_trust_score, 80), 80)
  AND distance_km IS NOT NULL
ORDER BY distance_km ASC,
         trust_score DESC,
         driver_id ASC;
```

Để truy vấn chạy nhanh khi có nhiều tài xế, nên tạo Index cho các cột dùng để lọc và sắp xếp:

```sql
CREATE INDEX idx_drivers_matching
ON Drivers (status, distance_km, trust_score);
```

### Dò luồng (trace) với dữ liệu mẫu

`@min_trust_score = -10`, ngưỡng thực tế sau chốt chặn là 80.

| driver_id | driver_name | status | trust_score | distance_km | Kết quả |
|---|---|---|---|---|---|
| 1 | Nguyễn Văn An | AVAILABLE | 92 | 1.5 | ✅ Hạng 2 |
| 2 | Trần Thị Bình | AVAILABLE | 85 | 1.5 | ✅ Hạng 3 (trùng 1.5 km, điểm thấp hơn An) |
| 3 | Lê Văn Cường | AVAILABLE | 88 | 0.8 | ✅ Hạng 1 (gần nhất) |
| 4 | Phạm Minh Đức | BANNED | 95 | 0.5 | Loại (bị khóa) |
| 5 | Hoàng Văn Em | AVAILABLE | 60 | 0.3 | Loại (điểm < 80, chỉ lọt nếu không có chốt chặn) |
| 6 | Võ Thị Phương | BUSY | 90 | 1.0 | Loại (đang giao đơn khác) |
| 7 | Đặng Văn Giang | AVAILABLE | 80 | 3.2 | ✅ Hạng 4 (đúng 80 điểm vẫn đạt) |
| 8 | Bùi Thị Hoa | AVAILABLE | 99 | NULL | Loại (chưa có vị trí) |
| 9 | Đỗ Văn Khoa | AVAILABLE | 30 | 2.0 | Loại (điểm < 80, chỉ lọt nếu không có chốt chặn) |

Kết quả:

| driver_id | driver_name | phone | distance_km | trust_score |
|---|---|---|---|---|
| 3 | Lê Văn Cường | 0903000003 | 0.8 | 88 |
| 1 | Nguyễn Văn An | 0903000001 | 1.5 | 92 |
| 2 | Trần Thị Bình | 0903000002 | 1.5 | 85 |
| 7 | Đặng Văn Giang | 0903000007 | 3.2 | 80 |

Nếu **không có chốt chặn**, tài xế Hoàng Văn Em (60 điểm, 0.3 km) sẽ lọt vào và được xếp **hạng 1**, đúng là kiểu lỗi khiến khách hàng phàn nàn.

## 4. Bài học rút ra

- Nối các điều kiện bắt buộc bằng **`AND`** để tài xế phải đạt **mọi** điều kiện cùng lúc.
- **`ORDER BY` nhiều cột** hoạt động theo tầng: cột sau chỉ dùng để phân định khi các cột trước bị trùng. Luôn thêm một cột duy nhất (như `driver_id`) ở tầng cuối để kết quả ổn định.
- **Không tin tưởng tuyệt đối dữ liệu cấu hình.** Dùng `GREATEST` và `COALESCE` để đặt mức sàn và giá trị mặc định ngay trong SQL.
- Nhớ xử lý **`NULL`**: so sánh với `NULL` luôn cho kết quả UNKNOWN, nên cần `COALESCE` cho tham số và `IS NOT NULL` cho dữ liệu.
