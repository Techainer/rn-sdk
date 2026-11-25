#ifndef SecurityGuardBridge_h
#define SecurityGuardBridge_h

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/// Trả về 1 nếu tiến trình đang bị debugger attach
/// (sysctl CTL_KERN/KERN_PROC → cờ P_TRACED), ngược lại trả 0.
int sg_is_debugged(void);

/// ptrace(PT_DENY_ATTACH, 0, 0, 0) — chặn debugger attach vào tiến trình.
/// Chỉ gọi MỘT lần lúc khởi động app ở bản Release (đây là bước hardening,
/// không phải bước "detect").
void sg_deny_debugger(void);

/// Đọc cờ trạng thái code-signing qua csops(getpid(), CS_OPS_STATUS, ...).
/// Ghi giá trị cờ vào *out_status. Trả về 0 nếu thành công, khác 0 nếu lỗi.
int sg_csops_status(uint32_t *out_status);

#ifdef __cplusplus
}
#endif

#endif /* SecurityGuardBridge_h */
