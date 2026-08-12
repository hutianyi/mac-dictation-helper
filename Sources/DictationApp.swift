import SwiftUI
import AVFoundation
import AppKit

@MainActor
final class DictationSession: ObservableObject {
    enum Phase {
        case setup
        case dictating
        case finished
    }

    @Published private(set) var phase: Phase = .setup
    @Published private(set) var words: [String] = []
    @Published private(set) var currentIndex = 0
    @Published private(set) var secondsRemaining = DictationCountdown.totalSeconds

    private let synthesizer = AVSpeechSynthesizer()
    private var speechRate: Float = 0.42
    private var countdown: DictationCountdown?
    private var countdownTask: Task<Void, Never>?
    private var countdownGeneration = 0

    var totalCount: Int { words.count }
    var progress: Double {
        guard !words.isEmpty else { return 0 }
        return Double(currentIndex + 1) / Double(words.count)
    }

    func start(words newWords: [String], shuffled: Bool, rate: Double) {
        guard !newWords.isEmpty else { return }
        words = shuffled ? newWords.shuffled() : newWords
        currentIndex = 0
        speechRate = Float(rate)
        phase = .dictating
        beginCurrentWord()
    }

    func speakCurrent() {
        guard phase == .dictating, words.indices.contains(currentIndex) else { return }
        let word = words[currentIndex]
        speak(DictationCore.repeatedSpeechText(for: word), language: DictationCore.language(for: word))
    }

    func next() {
        guard phase == .dictating else { return }
        if currentIndex + 1 < words.count {
            currentIndex += 1
            beginCurrentWord()
        } else {
            finish()
        }
    }

    func restart(rate: Double) {
        guard !words.isEmpty else { return }
        currentIndex = 0
        speechRate = Float(rate)
        phase = .dictating
        beginCurrentWord()
    }

    func returnToSetup() {
        cancelCountdown()
        synthesizer.stopSpeaking(at: .immediate)
        phase = .setup
    }

    private func beginCurrentWord() {
        startCountdown()
        speakCurrent()
    }

    private func startCountdown() {
        cancelCountdown(resetDisplay: false)
        countdown = DictationCountdown()
        secondsRemaining = DictationCountdown.totalSeconds
        let generation = countdownGeneration

        countdownTask = Task { [weak self] in
            while !Task.isCancelled {
                do {
                    try await Task.sleep(for: .milliseconds(100))
                } catch {
                    return
                }

                guard let self,
                      self.phase == .dictating,
                      self.countdownGeneration == generation,
                      var countdown = self.countdown else {
                    return
                }

                let update = countdown.update()
                self.countdown = countdown
                self.secondsRemaining = update.secondsRemaining

                if update.shouldRepeatAndWarn {
                    self.speakHalfwayReminder()
                }

                if update.shouldAdvance {
                    self.next()
                    return
                }
            }
        }
    }

    private func cancelCountdown(resetDisplay: Bool = true) {
        countdownTask?.cancel()
        countdownTask = nil
        countdown = nil
        countdownGeneration += 1
        if resetDisplay {
            secondsRemaining = DictationCountdown.totalSeconds
        }
    }

    private func speakHalfwayReminder() {
        guard phase == .dictating, words.indices.contains(currentIndex) else { return }
        let word = words[currentIndex]
        speakSequence([
            (
                DictationCore.repeatedSpeechText(for: word),
                DictationCore.language(for: word)
            ),
            ("还有十五秒，将自动进入下一个词语", "zh-CN")
        ])
    }

    private func finish() {
        cancelCountdown()
        phase = .finished
        speak("默写结束", language: "zh-CN")
    }

    private func speak(_ text: String, language: String) {
        speakSequence([(text, language)])
    }

    private func speakSequence(_ items: [(text: String, language: String)]) {
        synthesizer.stopSpeaking(at: .immediate)
        for (index, item) in items.enumerated() {
            let utterance = AVSpeechUtterance(string: item.text)
            utterance.voice = PreferredVoices.voice(for: item.language)
            utterance.rate = speechRate
            utterance.pitchMultiplier = 1.0
            utterance.preUtteranceDelay = index == 0 ? 0.18 : 0.25
            utterance.postUtteranceDelay = 0.08
            synthesizer.speak(utterance)
        }
    }
}

struct ContentView: View {
    @StateObject private var session = DictationSession()
    @AppStorage("dictation.input") private var inputText = "苹果\n认真\n美丽\numbrella\nwonderful"
    @AppStorage("dictation.shuffle") private var shuffleWords = false
    @AppStorage("dictation.rate") private var speechRate = 0.42

    private var parsedWords: [String] {
        DictationCore.parseWords(from: inputText)
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.94, green: 0.97, blue: 1.0), Color(red: 0.98, green: 0.95, blue: 1.0)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Group {
                switch session.phase {
                case .setup:
                    setupView
                case .dictating:
                    dictatingView
                case .finished:
                    finishedView
                }
            }
            .padding(34)
        }
        .frame(minWidth: 680, minHeight: 540)
    }

    private var setupView: some View {
        VStack(spacing: 22) {
            VStack(spacing: 8) {
                Image(systemName: "text.book.closed.fill")
                    .font(.system(size: 42))
                    .foregroundStyle(.blue)
                Text("默写小程序")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                Text("粘贴词语，Mac 会逐个读给孩子听")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("默写内容")
                        .font(.headline)
                    Spacer()
                    Text("共 \(parsedWords.count) 个")
                        .foregroundStyle(.secondary)
                }

                TextEditor(text: $inputText)
                    .font(.system(size: 18))
                    .padding(10)
                    .scrollContentBackground(.hidden)
                    .background(Color.white.opacity(0.92))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay {
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.black.opacity(0.08), lineWidth: 1)
                    }
                    .frame(minHeight: 190)

                Text("空格、连续空格、换行、Tab、逗号和分号都可以分隔词语。")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                Text("每个词语最多30秒；15秒时会自动重读并提醒。")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 24) {
                Toggle("随机顺序", isOn: $shuffleWords)
                    .toggleStyle(.switch)

                Divider().frame(height: 24)

                HStack {
                    Image(systemName: "tortoise.fill")
                        .foregroundStyle(.secondary)
                    Slider(value: $speechRate, in: 0.32...0.55, step: 0.01)
                        .frame(width: 150)
                    Image(systemName: "hare.fill")
                        .foregroundStyle(.secondary)
                }
                .accessibilityLabel("朗读速度")
            }

            Button {
                session.start(words: parsedWords, shuffled: shuffleWords, rate: speechRate)
            } label: {
                Label("开始默写", systemImage: "play.fill")
                    .font(.title3.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(parsedWords.isEmpty)
        }
        .padding(26)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.10), radius: 24, y: 10)
    }

    private var dictatingView: some View {
        VStack(spacing: 28) {
            HStack {
                Button {
                    session.returnToSetup()
                } label: {
                    Label("返回", systemImage: "chevron.left")
                }
                .buttonStyle(.plain)

                Spacer()
                Text("第 \(session.currentIndex + 1) 个，共 \(session.totalCount) 个")
                    .font(.headline)
                    .monospacedDigit()
            }

            ProgressView(value: session.progress)
                .tint(.blue)

            Spacer()

            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.12))
                    .frame(width: 150, height: 150)
                Image(systemName: "speaker.wave.3.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.blue)
            }

            VStack(spacing: 9) {
                Text("正在默写")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                Text("答案已隐藏，请听语音")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }

            countdownView

            HStack(spacing: 16) {
                shortcutHint(key: "R", text: "重复朗读（计时继续）")
                shortcutHint(key: "空格", text: "下一个")
            }

            HStack(spacing: 14) {
                Button {
                    session.speakCurrent()
                } label: {
                    Label("重复", systemImage: "arrow.counterclockwise")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .keyboardShortcut("r", modifiers: [])

                Button {
                    session.next()
                } label: {
                    Label("下一个", systemImage: "forward.fill")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .keyboardShortcut(.space, modifiers: [])
            }

            Spacer()
        }
        .padding(30)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.10), radius: 24, y: 10)
    }

    private var countdownView: some View {
        HStack(spacing: 12) {
            Image(systemName: "timer")
                .font(.title2)
            Text("\(session.secondsRemaining) 秒")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .monospacedDigit()
            Text(session.secondsRemaining <= DictationCountdown.halfwaySeconds
                 ? "即将自动进入下一个词语"
                 : "本词剩余时间")
                .font(.callout)
        }
        .foregroundStyle(countdownColor)
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .background(countdownColor.opacity(0.10))
        .clipShape(Capsule())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("本词剩余 \(session.secondsRemaining) 秒")
    }

    private var countdownColor: Color {
        if session.secondsRemaining <= 5 {
            return .red
        }
        if session.secondsRemaining <= DictationCountdown.halfwaySeconds {
            return .orange
        }
        return .blue
    }

    private var finishedView: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.14))
                    .frame(width: 150, height: 150)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 88))
                    .foregroundStyle(.green)
            }

            Text("默写结束")
                .font(.system(size: 36, weight: .bold, design: .rounded))
            Text("今天完成了 \(session.totalCount) 个词语")
                .font(.title3)
                .foregroundStyle(.secondary)

            HStack(spacing: 14) {
                Button {
                    session.returnToSetup()
                } label: {
                    Label("修改词语", systemImage: "pencil")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)

                Button {
                    session.restart(rate: speechRate)
                } label: {
                    Label("再默写一遍", systemImage: "arrow.clockwise")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .keyboardShortcut(.return, modifiers: [])
            }

            Spacer()
        }
        .padding(30)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.10), radius: 24, y: 10)
    }

    private func shortcutHint(key: String, text: String) -> some View {
        HStack(spacing: 8) {
            Text(key)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .padding(.horizontal, 9)
                .padding(.vertical, 5)
                .background(Color.white.opacity(0.9))
                .clipShape(RoundedRectangle(cornerRadius: 7))
                .overlay {
                    RoundedRectangle(cornerRadius: 7)
                        .stroke(Color.black.opacity(0.10), lineWidth: 1)
                }
            Text(text)
                .foregroundStyle(.secondary)
        }
    }
}

@main
struct DictationApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 760, height: 650)
        .commands {
            CommandGroup(replacing: .newItem) { }
        }
    }
}
