"""Synthesises the promo video's background track (original, royalty-free).

100 BPM, C-G-Am-F pop progression: soft pad, plucked arpeggio, bass, light
drums and a noise riser before the phone enters. Pure Python, no numpy.
"""
import math
import random
import struct
import wave

RATE = 44100
BPM = 100
BEAT = 60 / BPM
BAR = BEAT * 4

# (root-position-ish voicings, bass root) per bar, MIDI numbers.
CHORDS = [((60, 64, 67), 48), ((59, 62, 67), 43), ((60, 64, 69), 45), ((60, 65, 69), 41)]


def hz(m):
    return 440.0 * 2 ** ((m - 69) / 12)


def make(seconds, path, full_from=2, outro_bars=2, riser_at=None):
    n = int(seconds * RATE)
    bars = math.ceil(seconds / BAR)
    pad = [0.0] * n
    pluck = [0.0] * n
    bass = [0.0] * n
    drums = [0.0] * n
    rnd = random.Random(7)

    def add(buf, start, samples):
        i0 = int(start * RATE)
        for j, v in enumerate(samples):
            k = i0 + j
            if k >= n:
                break
            buf[k] += v

    for b in range(bars):
        t0 = b * BAR
        chord, root = CHORDS[b % 4]
        full = full_from <= b < bars - outro_bars

        # Pad: detuned sines with slow attack/release across the bar.
        length = int(BAR * RATE)
        for m in chord:
            f1, f2 = hz(m), hz(m) * 1.004
            samples = []
            for j in range(length):
                tt = j / RATE
                env = min(1, tt / 0.5) * min(1, (BAR - tt) / 0.6)
                samples.append(0.055 * env * (math.sin(2 * math.pi * f1 * tt) + math.sin(2 * math.pi * f2 * tt)))
            add(pad, t0, samples)

        # Pluck arpeggio in eighths, an octave up.
        pattern = [0, 1, 2, 1, 0, 2, 1, 2]
        for e, idx in enumerate(pattern):
            f = hz(chord[idx] + 12)
            dur = 0.55
            samples = []
            for j in range(int(dur * RATE)):
                tt = j / RATE
                env = math.exp(-tt * 7.5) * min(1, tt / 0.004)
                samples.append(0.16 * env * (math.sin(2 * math.pi * f * tt) + 0.35 * math.sin(4 * math.pi * f * tt)))
            add(pluck, t0 + e * BEAT / 2, samples)

        # Bass on beats 1 and 3 once the beat is in.
        if b >= full_from:
            for beat in (0, 2):
                f = hz(root)
                samples = []
                for j in range(int(0.9 * RATE)):
                    tt = j / RATE
                    env = math.exp(-tt * 3.2) * min(1, tt / 0.01)
                    samples.append(0.30 * env * math.sin(2 * math.pi * f * tt))
                add(bass, t0 + beat * BEAT, samples)

        if full:
            for beat in range(4):
                # Kick: falling sine.
                samples, ph = [], 0.0
                for j in range(int(0.28 * RATE)):
                    tt = j / RATE
                    f = 50 + 90 * math.exp(-tt * 28)
                    ph += 2 * math.pi * f / RATE
                    samples.append(0.55 * math.exp(-tt * 13) * math.sin(ph))
                add(drums, t0 + beat * BEAT, samples)
                # Hat on the off-beat.
                samples, prev = [], 0.0
                for j in range(int(0.05 * RATE)):
                    x = rnd.uniform(-1, 1)
                    samples.append(0.06 * math.exp(-j / RATE * 90) * (x - prev))
                    prev = x
                add(drums, t0 + beat * BEAT + BEAT / 2, samples)
                # Clap on 2 and 4.
                if beat in (1, 3):
                    samples = [0.13 * math.exp(-j / RATE * 30) * rnd.uniform(-1, 1)
                               for j in range(int(0.12 * RATE))]
                    add(drums, t0 + beat * BEAT, samples)

    # Riser into the first full section.
    if riser_at is not None:
        dur = 1.6
        samples, prev = [], 0.0
        for j in range(int(dur * RATE)):
            p = j / (dur * RATE)
            x = rnd.uniform(-1, 1)
            prev = prev + (0.05 + 0.6 * p) * (x - prev)
            samples.append(0.16 * p * p * prev)
        add(drums, riser_at - dur, samples)

    # Feedback delay on the pluck for space.
    d = int(BEAT * 0.75 * RATE)
    for i in range(d, n):
        pluck[i] += 0.32 * pluck[i - d]

    out = []
    fade = int(2.0 * RATE)
    for i in range(n):
        v = pad[i] + pluck[i] + bass[i] + drums[i]
        if i < int(0.3 * RATE):
            v *= i / (0.3 * RATE)
        if i > n - fade:
            v *= (n - i) / fade
        out.append(math.tanh(v * 1.1) * 0.85)

    with wave.open(path, "wb") as w:
        w.setnchannels(2)
        w.setsampwidth(2)
        w.setframerate(RATE)
        frames = bytearray()
        for v in out:
            s = int(max(-1, min(1, v)) * 32000)
            frames += struct.pack("<hh", s, s)
        w.writeframes(bytes(frames))


if __name__ == "__main__":
    import sys
    make(float(sys.argv[1]), sys.argv[2], riser_at=4.8)
