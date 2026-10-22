import Foundation

/// 加减分项和商品可用的预设图标（SF Symbol 名）。
/// 只放确实存在的符号，避免出现空白方块。
/// 种子数据用到的图标必须在这里面，否则编辑时图标一个都不高亮。
enum IconPreset {
    static let all: [String] = [
        // 日常习惯
        "checkmark", "exclamationmark", "sparkles", "star", "heart", "face.smiling",
        "hand.thumbsup", "hand.raised", "rosette",
        // 学习
        "book", "books.vertical", "pencil", "paintbrush", "paintpalette", "ruler",
        "graduationcap", "tray",
        // 生活
        "house", "washer", "shower", "fork.knife", "cup.and.saucer", "carrot", "leaf",
        "bed.double", "tv", "bubble.left",
        // 运动
        "figure.run", "bicycle", "basketball", "soccerball", "figure.pool.swim",
        "dumbbell", "figure.walk",
        // 音乐才艺
        "music.note", "pianokeys", "guitars", "theatermasks", "camera", "gamecontroller",
        // 时间
        "clock", "alarm", "timer", "moon", "sun.max", "calendar",
        // 零食玩具
        "puzzlepiece", "cone", "film", "tree", "seal", "birthday.cake",
        // 其它
        "pawprint", "trash", "cart", "gift", "shippingbox", "paperplane", "lightbulb"
    ]
}
