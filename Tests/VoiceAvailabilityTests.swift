import AVFoundation

@main
struct VoiceAvailabilityTests {
    static func main() {
        guard let chinese = PreferredVoices.voice(for: "zh-CN") else {
            fatalError("No Chinese system voice is available")
        }
        guard let english = PreferredVoices.voice(for: "en-US") else {
            fatalError("No English system voice is available")
        }

        let preferredChinese = AVSpeechSynthesisVoice(identifier: PreferredVoices.chineseIdentifier)
        let preferredEnglish = AVSpeechSynthesisVoice(identifier: PreferredVoices.englishIdentifier)

        if let preferredChinese {
            assert(chinese.identifier == preferredChinese.identifier)
        }
        if let preferredEnglish {
            assert(english.identifier == preferredEnglish.identifier)
        }

        print("Voice selection tests passed: \(chinese.name), \(english.name)")
    }
}
