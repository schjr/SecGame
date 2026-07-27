"""Generate the original UI sound effects used by Security Desktop Academy."""

from __future__ import annotations

import math
import random
import wave
from pathlib import Path


SAMPLE_RATE = 44_100
OUTPUT_DIR = Path(__file__).resolve().parents[1] / "assets" / "audio"


def envelope(time: float, duration: float, attack: float, release: float) -> float:
    attack_gain = min(1.0, time / max(attack, 1e-6))
    release_gain = min(1.0, (duration - time) / max(release, 1e-6))
    return max(0.0, min(attack_gain, release_gain))


def write_wav(name: str, samples: list[float]) -> None:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    peak = max(max(abs(sample) for sample in samples), 1e-6)
    gain = min(0.92 / peak, 1.0)
    pcm = bytearray()
    for sample in samples:
        value = int(max(-1.0, min(1.0, sample * gain)) * 32_767)
        pcm.extend(value.to_bytes(2, byteorder="little", signed=True))
    with wave.open(str(OUTPUT_DIR / name), "wb") as output:
        output.setnchannels(1)
        output.setsampwidth(2)
        output.setframerate(SAMPLE_RATE)
        output.writeframes(pcm)


def mouse_click() -> list[float]:
    rng = random.Random(4102)
    duration = 0.095
    samples: list[float] = []
    previous_noise = 0.0
    for index in range(int(SAMPLE_RATE * duration)):
        time = index / SAMPLE_RATE
        noise = rng.uniform(-1.0, 1.0)
        high_noise = noise - previous_noise * 0.78
        previous_noise = noise
        press = math.exp(-time * 105.0) * (
            0.55 * math.sin(2 * math.pi * 1_850 * time) + 0.32 * high_noise
        )
        release_time = max(0.0, time - 0.041)
        release = 0.0
        if time >= 0.041:
            release = math.exp(-release_time * 145.0) * (
                0.32 * math.sin(2 * math.pi * 2_350 * release_time)
                + 0.18 * high_noise
            )
        samples.append((press + release) * 0.72)
    return samples


def paper_rustle() -> list[float]:
    rng = random.Random(7261)
    duration = 0.82
    samples: list[float] = []
    smooth_noise = 0.0
    previous_smooth = 0.0
    for index in range(int(SAMPLE_RATE * duration)):
        time = index / SAMPLE_RATE
        raw = rng.uniform(-1.0, 1.0)
        smooth_noise = smooth_noise * 0.72 + raw * 0.28
        textured = smooth_noise - previous_smooth * 0.62
        previous_smooth = smooth_noise
        flutter = (
            0.32
            + 0.20 * math.sin(2 * math.pi * 7.3 * time)
            + 0.13 * math.sin(2 * math.pi * 13.7 * time + 0.8)
        )
        movement = envelope(time, duration, 0.035, 0.18)
        fold = math.exp(-((time - 0.18) / 0.045) ** 2)
        fold += 0.8 * math.exp(-((time - 0.48) / 0.065) ** 2)
        low_thump = fold * math.sin(2 * math.pi * 115 * time) * 0.12
        samples.append(textured * flutter * movement + low_thump)
    return samples


def harmonic_tone(
    time: float, start: float, duration: float, frequency: float, volume: float
) -> float:
    local_time = time - start
    if local_time < 0.0 or local_time >= duration:
        return 0.0
    gain = envelope(local_time, duration, 0.008, duration * 0.72)
    fundamental = math.sin(2 * math.pi * frequency * local_time)
    overtone = 0.28 * math.sin(2 * math.pi * frequency * 2.01 * local_time)
    shimmer = 0.10 * math.sin(2 * math.pi * frequency * 3.99 * local_time)
    return (fundamental + overtone + shimmer) * gain * volume


def error_alert() -> list[float]:
    duration = 0.58
    samples: list[float] = []
    for index in range(int(SAMPLE_RATE * duration)):
        time = index / SAMPLE_RATE
        first = harmonic_tone(time, 0.0, 0.24, 622.25, 0.42)
        tension = harmonic_tone(time, 0.0, 0.24, 466.16, 0.22)
        second = harmonic_tone(time, 0.255, 0.30, 392.0, 0.46)
        samples.append(first + tension + second)
    return samples


def stage_success() -> list[float]:
    duration = 1.18
    notes = [
        (0.00, 0.38, 523.25, 0.32),
        (0.14, 0.42, 659.25, 0.32),
        (0.28, 0.48, 783.99, 0.34),
        (0.45, 0.68, 1_046.50, 0.40),
    ]
    return [
        sum(harmonic_tone(index / SAMPLE_RATE, *note) for note in notes)
        for index in range(int(SAMPLE_RATE * duration))
    ]


def stage_failure() -> list[float]:
    duration = 1.18
    notes = [
        (0.00, 0.42, 440.00, 0.30),
        (0.20, 0.48, 369.99, 0.34),
        (0.42, 0.70, 277.18, 0.40),
    ]
    samples: list[float] = []
    for index in range(int(SAMPLE_RATE * duration)):
        time = index / SAMPLE_RATE
        tone = sum(harmonic_tone(time, *note) for note in notes)
        low = harmonic_tone(time, 0.48, 0.68, 138.59, 0.20)
        samples.append(tone + low)
    return samples


def background_music() -> list[float]:
    """A calm 32-second ambient loop with soft synth pads and light pulses."""
    duration = 32.0
    chord_length = 8.0
    crossfade = 1.6
    chords = [
        (130.81, 155.56, 196.00),  # C minor
        (103.83, 130.81, 155.56),  # A-flat major
        (155.56, 196.00, 233.08),  # E-flat major
        (116.54, 146.83, 174.61),  # B-flat minor colour
    ]
    arpeggios = [
        (261.63, 311.13, 392.00, 466.16),
        (207.65, 261.63, 311.13, 392.00),
        (311.13, 392.00, 466.16, 523.25),
        (233.08, 293.66, 349.23, 466.16),
    ]

    # Quantized frequencies finish an integer number of cycles at the loop
    # boundary, preventing a click when Godot returns to sample zero.
    def loop_frequency(frequency: float) -> float:
        return round(frequency * duration) / duration

    def pad_voice(time: float, frequency: float) -> float:
        frequency = loop_frequency(frequency)
        return (
            math.sin(2 * math.pi * frequency * time)
            + 0.18 * math.sin(2 * math.pi * frequency * 2 * time + 0.35)
            + 0.06 * math.sin(2 * math.pi * frequency * 3 * time + 1.1)
        )

    samples: list[float] = []
    for index in range(int(SAMPLE_RATE * duration)):
        time = index / SAMPLE_RATE
        chord_index = int(time / chord_length) % len(chords)
        next_index = (chord_index + 1) % len(chords)
        position = time % chord_length
        blend = max(0.0, min(1.0, (position - (chord_length - crossfade)) / crossfade))
        blend = blend * blend * (3.0 - 2.0 * blend)
        current_gain = math.cos(blend * math.pi * 0.5)
        next_gain = math.sin(blend * math.pi * 0.5)

        current_pad = sum(pad_voice(time, note) for note in chords[chord_index])
        next_pad = sum(pad_voice(time, note) for note in chords[next_index])
        pad = (current_pad * current_gain + next_pad * next_gain) * 0.075

        beat = int(time / 0.5)
        beat_time = time % 0.5
        arp_chord = int(time / chord_length) % len(arpeggios)
        arp_note = arpeggios[arp_chord][beat % 4]
        arp_frequency = loop_frequency(arp_note)
        pluck_envelope = (1.0 - math.exp(-beat_time * 65.0)) * math.exp(-beat_time * 8.5)
        pluck = (
            math.sin(2 * math.pi * arp_frequency * time)
            + 0.22 * math.sin(2 * math.pi * arp_frequency * 2 * time)
        ) * pluck_envelope * 0.105

        bar_time = time % 4.0
        bass_envelope = (1.0 - math.exp(-bar_time * 35.0)) * math.exp(-bar_time * 1.25)
        bass_frequency = loop_frequency(chords[chord_index][0] * 0.5)
        bass = math.sin(2 * math.pi * bass_frequency * time) * bass_envelope * 0.09

        slow_motion = 0.94 + 0.06 * math.sin(2 * math.pi * time / duration)
        samples.append((pad + pluck + bass) * slow_motion)
    return samples


def main() -> None:
    sounds = {
        "mouse_click.wav": mouse_click(),
        "paper_rustle.wav": paper_rustle(),
        "error_alert.wav": error_alert(),
        "stage_success.wav": stage_success(),
        "stage_failure.wav": stage_failure(),
        "background_loop.wav": background_music(),
    }
    for name, samples in sounds.items():
        write_wav(name, samples)
        print(f"generated {name}")


if __name__ == "__main__":
    main()
