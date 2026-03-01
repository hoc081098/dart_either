Chuẩn. Nếu muốn Dart API “nghe giống Arrow/Kotlin” hơn nhưng vẫn hợp Dart, mình gợi ý như sau:

| Dart hiện tại        | Gợi ý tên mới                     | Vì sao                                               | Status |
|----------------------|-----------------------------------|------------------------------------------------------|--------|
| `tap`                | `onRight`                         | Trùng mental model Arrow                             | DONE   | 
| `tapLeft`            | `onLeft`                          | Trùng mental model Arrow                             | DONE   | 
| `orNull`             | `getOrNull`                       | Đồng bộ với Kotlin/Arrow                             | DONE   | 
| `getOrHandle`        | `getOrElse`                       | Semantics đúng với `getOrElse((L) -> R)` của Arrow   |
| `getOrElse(() => R)` | `getOrDefault` hoặc `orElseGet`   | Tách rõ khỏi `getOrElse((L)->R)` để tránh nhập nhằng | DONE   |
| `exists`             | `isRightAnd` hoặc `isRightWhere`  | Gần nghĩa `isRight(predicate)`                       | DONE   |
| *(chưa có)*          | `isLeftAnd` hoặc `isLeftWhere`    | Bổ sung cặp đối xứng với `isRightAnd`                |        |
| `handleError`        | `recover`                         | Gần Arrow hơn                                        |        |
| `handleErrorWith`    | `recoverWith` *(hoặc giữ nguyên)* | Nếu muốn naming family đồng nhất với `recover`       |        |
| `catchError`         | `catch`                           | Tên ngắn, khớp Arrow                                 |        |
| `catchFutureError`   | `catchFuture`                     | Đồng bộ tên với `catch`                              |        |
| `catchStreamError`   | `catchStream`                     | Đồng bộ tên với `catch`                              |        |

Gợi ý rollout an toàn (vì package public):

1. Thêm tên mới dưới dạng alias.
2. `@Deprecated` tên cũ (message chỉ rõ tên thay thế).
3. Đợi 1-2 minor releases rồi mới remove ở major release.