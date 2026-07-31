//  WatermarkBridge.h
//  6.6 Image Provenance (iOS) — C interface cho Swift gọi vào watermark DCT.
//
//  Crypto (SHA-256, AES-256-GCM) làm ở Swift/CryptoKit (ProvenanceCrypto.swift).
//  File này CHỈ lo miền DCT: đọc hệ số, chọn carrier, nhúng/trích LSB, đóng khung wire + CRC.
//  Byte-compatible với Android watermark_jni.cpp (cùng carrier/wire/CRC/DC).
//
//  Quy ước trả về: 0 = thành công; khi thành công *out là buffer malloc (Swift phải free()),
//  *outLen là độ dài. Thất bại: trả != 0, *out = NULL.

#ifndef WATERMARK_BRIDGE_H
#define WATERMARK_BRIDGE_H

#include <stdint.h>
#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

// Serialize hệ số DC luma (component 0): mỗi DC là int16 big-endian, thứ tự block raster.
// Swift tính SHA-256(dc_bytes) = imageHash. (Không nhúng DC nên imageHash ổn định.)
int wm_dc_bytes(const uint8_t *jpeg, size_t jpegLen,
                uint8_t **out, size_t *outLen);

// Nhúng body (= nonce|ciphertext|tag, do Swift mã hoá) vào ảnh -> JPEG mới đã watermark.
// Native tự đóng khung wire = MAGIC|bodyLen|body|crc32 rồi nhúng LSB vào carrier AC.
int wm_embed_body(const uint8_t *jpeg, size_t jpegLen,
                  const uint8_t *body, size_t bodyLen,
                  uint8_t **out, size_t *outLen);

// Trích body (đã verify MAGIC + CRC) -> Swift AES-GCM decrypt. Dùng để self-test trên máy.
int wm_extract_body(const uint8_t *jpeg, size_t jpegLen,
                    uint8_t **out, size_t *outLen);

#ifdef __cplusplus
}
#endif

#endif /* WATERMARK_BRIDGE_H */
