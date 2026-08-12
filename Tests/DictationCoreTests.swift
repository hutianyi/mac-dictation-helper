import Foundation

@main
struct DictationCoreTests {
    static func main() {
        assert(
            DictationCore.parseWords(from: "苹果\n认真，umbrella; very good\t美丽") ==
            ["苹果", "认真", "umbrella", "very", "good", "美丽"]
        )
        assert(DictationCore.parseWords(from: "  苹果  \n\n 英语 ") == ["苹果", "英语"])

        let suppliedSample = """
        生物\t从事\t成就\t学期\t考试\t再三\t同意\t
        难得\t值班\t努力\t留学\t国家\t落后\t地位\t
        环节\t难度\t刻苦\t兴奋\t
        手术台\t阵地\t战斗  打响 消灭 伤员\t陆续\t
        血丝\t匆匆\t医生\t转告 赶忙 迅速 争分夺秒\t
        连续
        怒目圆睁 眨眼 眼眶\t目瞪口呆\t
        耳闻目睹
        """
        assert(DictationCore.parseWords(from: suppliedSample).count == 38)
        assert(DictationCore.parseWords(from: suppliedSample).contains("争分夺秒"))
        assert(DictationCore.language(for: "苹果") == "zh-CN")
        assert(DictationCore.language(for: "wonderful") == "en-US")
        assert(DictationCore.language(for: "第 1 课") == "zh-CN")
        assert(DictationCore.repeatedSpeechText(for: "连续") == "连续，连续")
        assert(DictationCore.repeatedSpeechText(for: "wonderful") == "wonderful. wonderful")

        let startedAt = Date(timeIntervalSince1970: 1_000)
        var countdown = DictationCountdown(startedAt: startedAt)
        assert(
            countdown.update(at: startedAt) == .init(
                secondsRemaining: 30,
                shouldRepeatAndWarn: false,
                shouldAdvance: false
            )
        )
        assert(
            countdown.update(at: startedAt.addingTimeInterval(14.2)) == .init(
                secondsRemaining: 16,
                shouldRepeatAndWarn: false,
                shouldAdvance: false
            )
        )
        assert(
            countdown.update(at: startedAt.addingTimeInterval(15)) == .init(
                secondsRemaining: 15,
                shouldRepeatAndWarn: true,
                shouldAdvance: false
            )
        )
        assert(
            countdown.update(at: startedAt.addingTimeInterval(20)) == .init(
                secondsRemaining: 10,
                shouldRepeatAndWarn: false,
                shouldAdvance: false
            )
        )
        assert(
            countdown.update(at: startedAt.addingTimeInterval(30)) == .init(
                secondsRemaining: 0,
                shouldRepeatAndWarn: false,
                shouldAdvance: true
            )
        )
        print("DictationCore tests passed")
    }
}
