import Foundation

/// 加减分项和商品可用的预设图标（SF Symbol 名）。
/// 只放确实存在的符号，避免出现空白方块。
enum IconPreset {
    static let all: [String] = [
        // 日常习惯
        "checkmark", "sparkles", "star", "heart", "face.smiling", "hand.thumbsup", "rosette",
        // 学习
        "book", "books.vertical", "pencil", "paintbrush", "paintpalette", "ruler", "graduationcap",
        // 生活
        "house", "washer", "shower", "fork.knife", "cup.and.saucer", "carrot", "leaf", "bed.double",
        // 运动
        "figure.run", "bicycle", "basketball", "soccerball", "figure.pool.swim", "dumbbell", "figure.walk",
        // 音乐才艺
        "music.note", "pianokeys", "guitars", "theatermasks", "camera", "gamecontroller",
        // 时间
        "clock", "alarm", "timer", "moon", "sun.max", "calendar",
        // 其它
        "pawprint", "trash", "cart", "gift", "shippingbox", "paperplane", "lightbulb"
    ]
}
