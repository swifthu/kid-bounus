import SwiftUI
import UIKit

extension Color {
    enum kami {
        // 纸感主题：浅色是米白纸面，深色是暖调夜里的灰
        static let bg           = Color(light: 0xF5F4ED, dark: 0x1A1A19)
        static let surface      = Color(light: 0xFAF9F5, dark: 0x232322)
        static let surfaceWarm  = Color(light: 0xE8E6DC, dark: 0x2E2E2B)
        static let fg           = Color(light: 0x141413, dark: 0xF0EEE7)
        static let fg2          = Color(light: 0x3D3D3A, dark: 0xD5D2C9)
        static let muted        = Color(light: 0x504E49, dark: 0xB2AEA4)
        static let meta         = Color(light: 0x6B6A64, dark: 0x8C8880)
        static let border       = Color(light: 0xE8E6DC, dark: 0x383733)
        static let borderSoft   = Color(light: 0xE5E3D8, dark: 0x2F2E2B)
        static let accent       = Color(light: 0x1B365D, dark: 0x7FA8DC)
        static let accentOn     = Color(light: 0xFAF9F5, dark: 0x10151E)
        static let accentLight  = Color(light: 0x2D5A8A, dark: 0xA9C8EC)
        static let accentActive = Color(light: 0x142A48, dark: 0xC5D9F0)
        static let success      = Color(light: 0x4A6B3A, dark: 0x9BC47E)
        static let warn         = Color(light: 0x8A6B1F, dark: 0xE2BE66)
        static let danger       = Color(light: 0x8A3A30, dark: 0xE59084)

        static let tagBgFaint   = Color(light: 0xEEF2F7, dark: 0x2E3138)
        static let tagBgSoft    = Color(light: 0xE4ECF5, dark: 0x28313E)
        static let tagBgBase    = Color(light: 0xD6E1EE, dark: 0x334257)
        static let tagBgStrong  = Color(light: 0xD0DCE9, dark: 0x3A4C66)

        // 状态色的浅底
        static let successBg    = Color(light: 0xE6EDE0, dark: 0x26301F)
        static let warnBg       = Color(light: 0xEFE7D3, dark: 0x332C1B)
        static let dangerBg     = Color(light: 0xEFE2DF, dark: 0x33221F)
    }

    /// 跟随浅色 / 深色外观。
    init(light: UInt32, dark: UInt32) {
        self.init(uiColor: UIColor { trait in
            UIColor(rgb: trait.userInterfaceStyle == .dark ? dark : light)
        })
    }

    init(hex: UInt32, opacity: Double = 1) {
        self.init(.sRGB, red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: opacity)
    }
}

extension UIColor {
    convenience init(rgb: UInt32) {
        self.init(red: CGFloat((rgb >> 16) & 0xFF) / 255,
                  green: CGFloat((rgb >> 8) & 0xFF) / 255,
                  blue: CGFloat(rgb & 0xFF) / 255,
                  alpha: 1)
    }
}

enum Spacing {
    static let s1:  CGFloat = 4
    static let s2:  CGFloat = 8
    static let s3:  CGFloat = 12
    static let s4:  CGFloat = 16
    static let s5:  CGFloat = 20
    static let s6:  CGFloat = 24
    static let s7:  CGFloat = 28
    static let s8:  CGFloat = 32
    static let s12: CGFloat = 48
}

enum Radius {
    static let xs:   CGFloat = 2
    static let sm:   CGFloat = 4
    static let md:   CGFloat = 8
    static let lg:   CGFloat = 12
    static let xl:   CGFloat = 16
    static let pill: CGFloat = 9999
}

enum KamiFontStyle { case display, body, mono }
