import AVFoundation

/// Syntetiserede lydeffekter til spilhændelser
class SoundManager {
    static let shared = SoundManager()

    var isEnabled: Bool = true

    // MARK: - Audio engine

    private let audioEngine = AVAudioEngine()
    private var engineNode: AVAudioSourceNode!
    private var effectNode: AVAudioSourceNode!
    private let sampleRate: Float = 44100

    // MARK: - Engine sound state

    private var enginePitch: Float = 0        // 0.0 = idle, 1.0 = max
    private var engineRunning: Bool = false
    private var engineAmplitude: Float = 0     // smooth ramp
    private var enginePhase: Float = 0

    // MARK: - Effect state

    private var activeEffect: SoundEffect?
    private var effectTime: Float = 0

    // MARK: - Init

    private init() {
        let format = AVAudioFormat(standardFormatWithSampleRate: Double(sampleRate), channels: 1)!

        engineNode = AVAudioSourceNode(format: format) { [weak self] _, _, frameCount, bufferList -> OSStatus in
            guard let self = self else { return noErr }
            let ablPointer = UnsafeMutableAudioBufferListPointer(bufferList)
            let buf = ablPointer[0]
            let frames = Int(frameCount)
            guard let data = buf.mData?.assumingMemoryBound(to: Float.self) else { return noErr }

            let running = self.engineRunning && self.isEnabled
            let targetAmp: Float = running ? (0.15 + self.enginePitch * 0.15) : 0
            let freq: Float = 80 + self.enginePitch * 320

            for i in 0..<frames {
                // Smooth amplitude ramp (undgå klik)
                self.engineAmplitude += (targetAmp - self.engineAmplitude) * 0.002

                // Sawtooth wave
                let saw = 2.0 * self.enginePhase - 1.0

                // Tremolo
                let tremolo: Float = 1.0 - 0.15 * sin(self.enginePhase * 15.0 * 2.0 * .pi / freq)

                data[i] = saw * self.engineAmplitude * tremolo

                self.enginePhase += freq / self.sampleRate
                if self.enginePhase >= 1.0 { self.enginePhase -= 1.0 }
            }
            return noErr
        }

        effectNode = AVAudioSourceNode(format: format) { [weak self] _, _, frameCount, bufferList -> OSStatus in
            guard let self = self else { return noErr }
            let ablPointer = UnsafeMutableAudioBufferListPointer(bufferList)
            let buf = ablPointer[0]
            let frames = Int(frameCount)
            guard let data = buf.mData?.assumingMemoryBound(to: Float.self) else { return noErr }

            for i in 0..<frames {
                if let effect = self.activeEffect, self.isEnabled {
                    data[i] = effect.sample(at: self.effectTime, sampleRate: self.sampleRate)
                    self.effectTime += 1.0 / self.sampleRate
                    if self.effectTime >= effect.duration {
                        self.activeEffect = nil
                    }
                } else {
                    data[i] = 0
                }
            }
            return noErr
        }

        audioEngine.attach(engineNode)
        audioEngine.attach(effectNode)
        audioEngine.connect(engineNode, to: audioEngine.mainMixerNode, format: format)
        audioEngine.connect(effectNode, to: audioEngine.mainMixerNode, format: format)

        engineNode.volume = 0.25
        effectNode.volume = 0.4

        try? AVAudioSession.sharedInstance().setCategory(.ambient, options: .mixWithOthers)
        try? AVAudioSession.sharedInstance().setActive(true)
        try? audioEngine.start()
    }

    // MARK: - Engine sound

    func startEngine() {
        engineRunning = true
        if !audioEngine.isRunning {
            try? audioEngine.start()
        }
    }

    func stopEngine() {
        engineRunning = false
        enginePitch = 0
    }

    func updateEngineSpeed(_ normalizedSpeed: Float) {
        enginePitch = max(0, min(1, normalizedSpeed))
    }

    // MARK: - One-shot effekter

    func countdownTick() {
        playEffect(.countdownBeep)
    }

    func go() {
        playEffect(.goSignal)
    }

    func flyOff() {
        playEffect(.flyOff)
    }

    func lapComplete() {
        playEffect(.lapComplete)
    }

    func raceFinished(won: Bool) {
        playEffect(won ? .raceWon : .raceLost)
    }

    private func playEffect(_ effect: SoundEffect) {
        guard isEnabled else { return }
        effectTime = 0
        activeEffect = effect
    }
}

// MARK: - Sound Effect Synthesis

enum SoundEffect {
    case countdownBeep
    case goSignal
    case flyOff
    case lapComplete
    case raceWon
    case raceLost

    var duration: Float {
        switch self {
        case .countdownBeep: return 0.15
        case .goSignal: return 0.4
        case .flyOff: return 1.0
        case .lapComplete: return 0.25
        case .raceWon: return 0.6
        case .raceLost: return 0.5
        }
    }

    func sample(at time: Float, sampleRate: Float) -> Float {
        switch self {
        case .countdownBeep:
            // 880 Hz sinus med fade-out
            let envelope = time < 0.12 ? 1.0 : max(0, 1.0 - (time - 0.12) / 0.03)
            return sin(time * 880 * 2 * .pi) * 0.5 * envelope

        case .goSignal:
            // C-dur akkord: C5 + E5 + G5
            let envelope = time < 0.3 ? 1.0 : max(0, 1.0 - (time - 0.3) / 0.1)
            let c = sin(time * 523 * 2 * .pi)
            let e = sin(time * 659 * 2 * .pi)
            let g = sin(time * 784 * 2 * .pi)
            return (c + e + g) / 3.0 * 0.5 * envelope

        case .flyOff:
            // Eksplosion! Tre faser: kort screech → BOOM → rumble
            if time < 0.08 {
                // Kort dæk-screech
                let freq = 3000 - (time / 0.08) * 2000
                let phase = time * freq * 2 * .pi
                return (sin(phase) > 0 ? 0.4 : -0.4)
            } else if time < 0.35 {
                // BOOM — lavfrekvent explosion med noise
                let boomTime = time - 0.08
                let boom = sin(boomTime * 60 * 2 * .pi) * 0.7 * exp(-boomTime * 4)
                let noise = Float.random(in: -1...1) * 0.6 * exp(-boomTime * 5)
                let crackle = sin(boomTime * 200 * 2 * .pi) * 0.3 * exp(-boomTime * 8)
                return boom + noise + crackle
            } else {
                // Rumble — lavfrekvent efterdønning med knitrende debris
                let rumbleTime = time - 0.35
                let rumble = sin(rumbleTime * 40 * 2 * .pi) * 0.3 * exp(-rumbleTime * 3)
                let debris = Float.random(in: -1...1) * 0.2 * exp(-rumbleTime * 4)
                return (rumble + debris) * max(0, 1.0 - rumbleTime / 0.65)
            }

        case .lapComplete:
            // To-tone ascending ding
            if time < 0.1 {
                let envelope = time < 0.07 ? 1.0 : max(0, 1.0 - (time - 0.07) / 0.03)
                return sin(time * 880 * 2 * .pi) * 0.5 * envelope
            } else {
                let t2 = time - 0.1
                let envelope = t2 < 0.1 ? 1.0 : max(0, 1.0 - (t2 - 0.1) / 0.05)
                return sin(t2 * 1175 * 2 * .pi) * 0.5 * envelope
            }

        case .raceWon:
            // Ascending arpeggio: C5, E5, G5, C6
            let notes: [(freq: Float, start: Float)] = [
                (523, 0.0), (659, 0.15), (784, 0.3), (1047, 0.45)
            ]
            for (i, note) in notes.enumerated() {
                let noteEnd = (i < notes.count - 1) ? notes[i + 1].start : duration
                if time >= note.start && time < noteEnd {
                    let t = time - note.start
                    let noteDur = noteEnd - note.start
                    let envelope = t < (noteDur - 0.03) ? 1.0 : max(0, 1.0 - (t - (noteDur - 0.03)) / 0.03)
                    return sin(t * note.freq * 2 * .pi) * 0.5 * envelope
                }
            }
            return 0

        case .raceLost:
            // Faldende to-toner: G4 → C4
            if time < 0.2 {
                let envelope = time < 0.15 ? 1.0 : max(0, 1.0 - (time - 0.15) / 0.05)
                return sin(time * 392 * 2 * .pi) * 0.4 * envelope
            } else {
                let t2 = time - 0.2
                let envelope = t2 < 0.2 ? 1.0 : max(0, 1.0 - (t2 - 0.2) / 0.1)
                return sin(t2 * 262 * 2 * .pi) * 0.4 * envelope
            }
        }
    }
}
