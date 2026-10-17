import SwiftUI

extension Color {
    enum kami {
        static let bg           = Color(hex: 0xF5F4ED)
        static let surface      = Color(hex: 0xFAF9F5)
        static let surfaceWarm  = Color(hex: 0xE8E6DC)
        static let fg           = Color(hex: 0x141413)
        static let fg2          = Color(hex: 0x3D3D3A)
        static let muted        = Color(hex: 0x504E49)
        static let meta         = Color(hex: 0x6B6A64)
        static let border       = Color(hex: 0xE8E6DC)
        static let borderSoft   = Color(hex: 0xE5E3D8)
        static let accent       = Color(hex: 0x1B365D)
        static let accentOn     = Color(hex: 0xFAF9F5)
        static let accentLight  = Color(hex: 0x2D5A8A)
        static let accentActive = Color(hex: 0x142A48)
        static let success      = Color(hex: 0x4A6B3A)
        static let warn         = Color(hex: 0x8A6B1F)
        static let danger       = Color(hex: 0x8A3A30)

        static let tagBgFaint   = Color(hex: 0xEEF2F7)
        static let tagBgSoft    = Color(hex: 0xE4ECF5)
        static let tagBgBase    = Color(hex: 0xD6E1EE)
        static let tagBgStrong  = Color(hex: 0xD0DCE9)
    }

    init(hex: UInt32, opacity: Double = 1) {
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >>  8) & 0xFF) / 255
        let b = Double( hex        & 0xFF) / 255
        self.init(.sRGB, red: r, green: g, blue: b, opacity: opacity)
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

