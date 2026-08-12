import Foundation

enum DictationCore {
    private static let separators = CharacterSet.whitespacesAndNewlines
        .union(CharacterSet(charactersIn: ",，;；"))

    static func parseWords(from text: String) -> [String] {
        text.components(separatedBy: separators)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    static func language(for text: String) -> String {
        let containsChinese = text.unicodeScalars.contains { scalar in
            (0x3400...0x4DBF).contains(scalar.value) ||
            (0x4E00...0x9FFF).contains(scalar.value) ||
            (0xF900...0xFAFF).contains(scalar.value)
        }
        return containsChinese ? "zh-CN" : "en-US"
    }

    static func repeatedSpeechText(for text: String) -> String {
        language(for: text) == "zh-CN"
            ? "\(text)，\(text)"
            : "\(text). \(text)"
    }
}

struct DictationCountdown {
    struct Update: Equatable {
        let secondsRemaining: Int
        let shouldRepeatAndWarn: Bool
        let shouldAdvance: Bool
    }

    static let totalSeconds = 30
    static let halfwaySeconds = 15

    let deadline: Date
    private(set) var didRepeatAndWarn = false

    init(startedAt: Date = Date()) {
        deadline = startedAt.addingTimeInterval(TimeInterval(Self.totalSeconds))
    }

    mutating func update(at now: Date = Date()) -> Update {
        let interval = max(0, deadline.timeIntervalSince(now))
        let secondsRemaining = Int(ceil(interval))

        if secondsRemaining == 0 {
            return Update(
                secondsRemaining: 0,
                shouldRepeatAndWarn: false,
                shouldAdvance: true
            )
        }

        let shouldRepeatAndWarn = !didRepeatAndWarn
            && secondsRemaining <= Self.halfwaySeconds
        if shouldRepeatAndWarn {
            didRepeatAndWarn = true
        }

        return Update(
            secondsRemaining: secondsRemaining,
            shouldRepeatAndWarn: shouldRepeatAndWarn,
            shouldAdvance: false
        )
    }
}
