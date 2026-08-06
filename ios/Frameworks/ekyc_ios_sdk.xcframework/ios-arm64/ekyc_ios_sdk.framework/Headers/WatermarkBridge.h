//  WatermarkBridge.h
//  Session Binding (iOS) — C interface cho Swift gọi vào lớp ký + chèn JPEG COM.
//
//  Toàn bộ crypto (SHA-256, HMAC-SHA256, base64url) VÀ việc dựng COM segment nằm
//  trong C++ (WatermarkCore.cpp) — khó dịch ngược hơn Swift. Trước đây crypto ở
//  Swift/CryptoKit (ProvenanceCrypto.swift); file đó đã bị xoá.
//
//  Byte-compatible với Android watermark_jni.cpp: cùng thứ tự signed_input, cùng
//  bảng base64url, cùng khung COM. Cả hai phải ra đúng hex của known-answer vector.
//
//  Quy ước trả về: 0 = thành công. Khi thành công *out là buffer malloc — Swift PHẢI
//  gọi ekyc_free() sau khi copy. Thất bại: trả != 0 và *out = NULL.

#ifndef EKYC_WATERMARK_BRIDGE_H
#define EKYC_WATERMARK_BRIDGE_H

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/// Mã lỗi. Chỉ 0 là thành công.
typedef enum {
    EKYC_OK              = 0,
    EKYC_ERR_NOT_JPEG    = 1,  ///< thiếu SOI 0xFFD8
    EKYC_ERR_KEY_LEN     = 2,  ///< session_key không đúng 32 raw bytes
    EKYC_ERR_SESSION_ID  = 3,  ///< session_id rỗng
    EKYC_ERR_PAYLOAD_CAP = 4,  ///< payload vượt trần 512 B của server
    EKYC_ERR_NON_ASCII   = 5,  ///< payload có byte >= 0x80
    EKYC_ERR_CRYPTO      = 6,  ///< SHA-256 / HMAC thất bại
    EKYC_ERR_ALLOC       = 7   ///< malloc thất bại
} ekyc_status_t;

/// Ký JPEG rồi chèn COM segment ngay sau SOI. KHÔNG sửa byte nào khác.
///
/// - jpeg/jpegLen: JPEG cuối cùng sẽ upload (sau resize + compress). Hash tính trên
///   CHÍNH bytes này, TRƯỚC khi chèn COM.
/// - sessionKey/keyLen: **32 raw bytes** đã base64-decode. Truyền chuỗi base64 vào
///   đây là sai và hàm trả EKYC_ERR_KEY_LEN.
/// - sessionId: chuỗi UUID NUL-terminated y như server cấp (lowercase, có gạch nối).
/// - tsMs: epoch millis; ghi vào payload dạng ASCII thập phân.
/// - out/outLen: buffer kết quả (malloc). Gọi ekyc_free() sau khi dùng.
int ekyc_sign_and_inject_com(const uint8_t* jpeg, size_t jpegLen,
                             const uint8_t* sessionKey, size_t keyLen,
                             const char* sessionId, int64_t tsMs,
                             uint8_t** out, size_t* outLen);

/// Parity self-test với known-answer vector của spec.
///
/// Ghi 64 ký tự hex + NUL vào `outHex65` (buffer phải >= 65 byte). Kết quả PHẢI là
///   3cb601af7dbc224d98b823d52ceb71c168fe036d5458cdef6d6fb4e95ead9e1b
/// Lệch một ký tự nghĩa là byte order hoặc encoding sai ⇒ MỌI frame bị server từ
/// chối. Lỗi này không biểu hiện lúc build. Chạy trong test/CI trước khi ship.
int ekyc_parity_self_test(char* outHex65);

/// Giải phóng buffer do ekyc_sign_and_inject_com cấp.
void ekyc_free(uint8_t* p);

#ifdef __cplusplus
}
#endif

#endif /* EKYC_WATERMARK_BRIDGE_H */
