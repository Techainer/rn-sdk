//
//  BrightnessHelper.swift
//  ekyc_ios_sdk
//
//  Created by mac on 27/3/25.
//  Phạm Thế Sơn
//


import UIKit

class BrightnessHelper {
    private var originalBrightness: CGFloat?
    private let defaultBrightness: CGFloat = 0.3

    // Đặt độ sáng màn hình
    func setBrightness(_ value: CGFloat) {
        DispatchQueue.main.async {
            UIScreen.main.brightness = value
        }
    }

    // Lấy độ sáng hiện tại, nếu chưa lưu thì dùng mặc định
    func getBrightness() {
        if originalBrightness == nil {
            originalBrightness = UIScreen.main.brightness
        }
    }

    // Khôi phục độ sáng ban đầu
    func restoreBrightness() {
        if let brightness = originalBrightness {
            setBrightness(brightness)
        }
    }
}
