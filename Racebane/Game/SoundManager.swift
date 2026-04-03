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

    // MARK: - Music state

    private var musicNode: AVAudioSourceNode!
    private var musicPlaying: Bool = false
    private var musicAmplitude: Float = 0
    private var musicTime: Float = 0

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

        musicNode = AVAudioSourceNode(format: format) { [weak self] _, _, frameCount, bufferList -> OSStatus in
            guard let self = self else { return noErr }
            let ablPointer = UnsafeMutableAudioBufferListPointer(bufferList)
            let buf = ablPointer[0]
            let frames = Int(frameCount)
            guard let data = buf.mData?.assumingMemoryBound(to: Float.self) else { return noErr }

            let playing = self.musicPlaying && self.isEnabled
            let targetAmp: Float = playing ? 0.18 : 0

            for i in 0..<frames {
                self.musicAmplitude += (targetAmp - self.musicAmplitude) * 0.0005

                data[i] = MenuMusic.sample(at: self.musicTime, sampleRate: self.sampleRate) * self.musicAmplitude
                self.musicTime += 1.0 / self.sampleRate

                // Loop melodien
                if self.musicTime >= MenuMusic.totalDuration {
                    self.musicTime = 0
                }
            }
            return noErr
        }

        audioEngine.attach(engineNode)
        audioEngine.attach(effectNode)
        audioEngine.attach(musicNode)
        audioEngine.connect(engineNode, to: audioEngine.mainMixerNode, format: format)
        audioEngine.connect(effectNode, to: audioEngine.mainMixerNode, format: format)
        audioEngine.connect(musicNode, to: audioEngine.mainMixerNode, format: format)

        engineNode.volume = 0.25
        effectNode.volume = 0.4
        musicNode.volume = 0.5

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

    // MARK: - Menu musik

    func startMusic() {
        musicPlaying = true
        if !audioEngine.isRunning {
            try? audioEngine.start()
        }
    }

    func stopMusic() {
        musicPlaying = false
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

// MARK: - Menu Music Synthesis

/// Glad, loopende menu-melodi syntetiseret med sinus-bølger
enum MenuMusic {
    // Noder: (frekvens i Hz, startbeat, varighed i beats)
    // Melodi i C-dur, 140 BPM, 8 takter
    private static let bpm: Float = 140
    private static let beatDuration: Float = 60.0 / bpm

    // Melodi-stemme (glad racing-tune)
    private static let melody: [(freq: Float, beat: Float, dur: Float)] = [
        // Takt 1-2: Åbning
        (523, 0, 0.5),  (659, 0.5, 0.5),  (784, 1, 0.5),  (1047, 1.5, 1),
        (880, 2.5, 0.5), (784, 3, 0.5),    (659, 3.5, 0.5),
        // Takt 3-4
        (698, 4, 0.75),  (659, 4.75, 0.25), (587, 5, 0.5),  (523, 5.5, 0.5),
        (587, 6, 0.5),   (659, 6.5, 0.5),   (698, 7, 1),
        // Takt 5-6: Gentagelse med variation
        (523, 8, 0.5),  (659, 8.5, 0.5),  (784, 9, 0.5),  (1047, 9.5, 0.5),
        (1175, 10, 0.5), (1047, 10.5, 0.5), (880, 11, 1),
        // Takt 7-8: Afslutning der looper
        (784, 12, 0.5), (880, 12.5, 0.5), (784, 13, 0.5), (659, 13.5, 0.5),
        (587, 14, 0.5), (523, 14.5, 0.5), (494, 15, 0.75), (523, 15.75, 0.25),
    ]

    // Bas-stemme (simpel grund-tone)
    private static let bass: [(freq: Float, beat: Float, dur: Float)] = [
        (131, 0, 2), (131, 2, 2),       // C
        (147, 4, 2), (131, 6, 2),       // D, C
        (131, 8, 2), (165, 10, 2),      // C, E
        (147, 12, 2), (131, 14, 2),     // D, C
    ]

    static let totalDuration: Float = 16 * beatDuration

    static func sample(at time: Float, sampleRate: Float) -> Float {
        var output: Float = 0

        // Melodi: blød sinus med overtone
        for note in melody {
            let noteStart = note.beat * beatDuration
            let noteDur = note.dur * beatDuration
            let noteEnd = noteStart + noteDur

            if time >= noteStart && time < noteEnd {
                let t = time - noteStart
                // Attack-decay envelope
                let attack: Float = min(t / 0.02, 1.0)
                let release: Float = t > (noteDur - 0.03) ? max(0, (noteEnd - time) / 0.03) : 1.0
                let env = attack * release

                // Sinus + svag overtone for fylde
                let fundamental = sin(t * note.freq * 2 * .pi)
                let overtone = sin(t * note.freq * 2 * 2 * .pi) * 0.2
                output += (fundamental + overtone) * env * 0.35
            }
        }

        // Bas: blød sinus
        for note in bass {
            let noteStart = note.beat * beatDuration
            let noteDur = note.dur * beatDuration
            let noteEnd = noteStart + noteDur

            if time >= noteStart && time < noteEnd {
                let t = time - noteStart
                let attack: Float = min(t / 0.03, 1.0)
                let release: Float = t > (noteDur - 0.05) ? max(0, (noteEnd - time) / 0.05) : 1.0
                output += sin(t * note.freq * 2 * .pi) * attack * release * 0.25
            }
        }

        // Simpel percussion: kick på hver beat
        let beatPos = time.truncatingRemainder(dividingBy: beatDuration)
        if beatPos < 0.04 {
            let kickEnv = exp(-beatPos * 80)
            output += sin(beatPos * 120 * 2 * .pi) * kickEnv * 0.2
        }

        return output
    }
}

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
