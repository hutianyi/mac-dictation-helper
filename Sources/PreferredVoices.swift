import AVFoundation

enum PreferredVoices {
    static let chineseIdentifier = "com.apple.voice.premium.zh-CN.Lili"
    static let englishIdentifier = "com.apple.voice.premium.en-US.Ava"

    static func voice(for language: String) -> AVSpeechSynthesisVoice? {
        let preferredIdentifier = language == "zh-CN"
            ? chineseIdentifier
            : englishIdentifier
        return AVSpeechSynthesisVoice(identifier: preferredIdentifier)
            ?? AVSpeechSynthesisVoice(language: language)
    }
}
