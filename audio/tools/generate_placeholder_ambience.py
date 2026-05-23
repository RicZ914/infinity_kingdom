from __future__ import annotations

import argparse
import math
import random
import wave
from pathlib import Path

SAMPLE_RATE = 48_000
MAX_AMPLITUDE = 32_767

TRACK_SPECS = {
    "ambience_town_title_loop": 26.0,
    "ambience_town_battle_loop": 24.0,
    "ambience_town_boss_loop": 22.0,
}


def note_frequency(midi_note: int) -> float:
    return 440.0 * pow(2.0, (midi_note - 69) / 12.0)


def clamp(value: float, minimum: float = -1.0, maximum: float = 1.0) -> float:
    return max(minimum, min(maximum, value))


def stable_seed(name: str) -> int:
    return sum((index + 1) * ord(char) for index, char in enumerate(name))


def oscillator(kind: str, phase: float) -> float:
    if kind == "sine":
        return math.sin(phase)
    if kind == "triangle":
        return 2.0 * abs(2.0 * ((phase / math.tau) % 1.0) - 1.0) - 1.0
    return math.sin(phase)


class AmbienceBuilder:
    def __init__(self, duration: float, seed: int) -> None:
        self.duration = duration
        self.length = max(1, int(duration * SAMPLE_RATE))
        self.samples = [0.0] * self.length
        self.random = random.Random(seed)

    def add_tone(
        self,
        start: float,
        duration: float,
        freq_start: float,
        freq_end: float | None = None,
        amp: float = 0.08,
        wave_type: str = "sine",
        attack: float = 0.3,
        release: float = 0.8,
        vibrato_hz: float = 0.0,
        vibrato_depth: float = 0.0,
    ) -> None:
        start_index = max(0, int(start * SAMPLE_RATE))
        end_index = min(self.length, start_index + max(1, int(duration * SAMPLE_RATE)))
        if end_index <= start_index:
            return
        if freq_end is None:
            freq_end = freq_start
        clip_duration = max(duration, 1.0 / SAMPLE_RATE)
        attack_ratio = min(0.95, max(0.0001, attack / clip_duration))
        release_ratio = min(0.95, max(0.0001, release / clip_duration))
        clip_length = max(1, end_index - start_index)
        phase = 0.0
        for clip_index, sample_index in enumerate(range(start_index, end_index)):
            progress = clip_index / max(1, clip_length - 1)
            freq = freq_start + (freq_end - freq_start) * progress
            if vibrato_hz > 0.0 and vibrato_depth > 0.0:
                freq *= 1.0 + math.sin(math.tau * vibrato_hz * clip_index / SAMPLE_RATE) * vibrato_depth
            phase += math.tau * freq / SAMPLE_RATE
            envelope = 1.0
            if progress < attack_ratio:
                envelope *= progress / attack_ratio
            if progress > 1.0 - release_ratio:
                envelope *= max(0.0, (1.0 - progress) / release_ratio)
            envelope *= 0.82 + 0.18 * math.sin(progress * math.tau * 0.5)
            self.samples[sample_index] += oscillator(wave_type, phase) * amp * envelope

    def add_noise(
        self,
        start: float,
        duration: float,
        amp: float,
        color: str,
        attack: float = 0.02,
        release: float = 0.12,
    ) -> None:
        start_index = max(0, int(start * SAMPLE_RATE))
        end_index = min(self.length, start_index + max(1, int(duration * SAMPLE_RATE)))
        if end_index <= start_index:
            return
        clip_duration = max(duration, 1.0 / SAMPLE_RATE)
        attack_ratio = min(0.95, max(0.0001, attack / clip_duration))
        release_ratio = min(0.95, max(0.0001, release / clip_duration))
        clip_length = max(1, end_index - start_index)
        low = 0.0
        mid = 0.0
        high = 0.0
        last_white = 0.0
        for clip_index, sample_index in enumerate(range(start_index, end_index)):
            progress = clip_index / max(1, clip_length - 1)
            white = self.random.uniform(-1.0, 1.0)
            if color == "wind":
                low = low * 0.995 + white * 0.005
                mid = mid * 0.94 + white * 0.06
                value = low * 1.35 + (mid - low) * 0.45
            elif color == "gust":
                low = low * 0.985 + white * 0.015
                mid = mid * 0.86 + white * 0.14
                value = low * 0.85 + (mid - low) * 1.2
            elif color == "rumble":
                low = low * 0.985 + white * 0.015
                value = low
            elif color == "crackle":
                spike = white if self.random.random() > 0.985 else 0.0
                value = (white - last_white * 0.78) * 0.45 + spike * 0.9
            elif color == "metal":
                mid = mid * 0.7 + white * 0.3
                value = (white - mid) * 1.4
            elif color == "cloth":
                low = low * 0.988 + white * 0.012
                mid = mid * 0.9 + white * 0.1
                value = (mid - low) * 0.75
            elif color == "steps":
                low = low * 0.96 + white * 0.04
                value = low * 0.85 + (white - last_white * 0.82) * 0.18
            elif color == "chain":
                mid = mid * 0.58 + white * 0.42
                high = high * 0.22 + white * 0.78
                value = (high - mid) * 1.55
            else:
                value = white
            last_white = white
            envelope = 1.0
            if progress < attack_ratio:
                envelope *= progress / attack_ratio
            if progress > 1.0 - release_ratio:
                envelope *= max(0.0, (1.0 - progress) / release_ratio)
            self.samples[sample_index] += value * amp * envelope

    def add_loop_fade(self, seconds: float = 0.02) -> None:
        fade_samples = min(int(seconds * SAMPLE_RATE), self.length // 8)
        for index in range(fade_samples):
            weight = index / max(1, fade_samples - 1)
            self.samples[index] *= weight
            self.samples[self.length - 1 - index] *= weight

    def finalize(self) -> bytes:
        self.add_loop_fade()
        peak = max(max(abs(sample) for sample in self.samples), 0.001)
        scale = 0.78 / peak
        frames = bytearray()
        for sample in self.samples:
            shaped = math.tanh(sample * scale)
            frames.extend(int(clamp(shaped) * MAX_AMPLITUDE).to_bytes(2, byteorder="little", signed=True))
        return bytes(frames)


def add_fire_cluster(builder: AmbienceBuilder, start: float, count: int, spacing: float, amp: float) -> None:
    for index in range(count):
        event_start = start + index * spacing
        builder.add_noise(event_start, 0.55, amp=amp, color="crackle", attack=0.02, release=0.18)


def add_banner_motion(builder: AmbienceBuilder, start: float, length: float, amp: float) -> None:
    builder.add_noise(start, length, amp=amp, color="cloth", attack=0.06, release=0.18)
    builder.add_tone(
        start,
        length,
        note_frequency(62),
        note_frequency(58),
        amp=amp * 0.18,
        wave_type="triangle",
        attack=0.08,
        release=0.24,
        vibrato_hz=0.18,
        vibrato_depth=0.02,
    )


def add_step_group(builder: AmbienceBuilder, start: float, count: int, spacing: float, amp: float) -> None:
    for index in range(count):
        event_start = start + index * spacing
        builder.add_noise(event_start, 0.1, amp=amp, color="steps", attack=0.005, release=0.04)
        builder.add_noise(event_start + 0.015, 0.08, amp=amp * 0.42, color="metal", attack=0.004, release=0.04)


def add_chain_event(builder: AmbienceBuilder, start: float, amp: float) -> None:
    builder.add_noise(start, 0.28, amp=amp, color="chain", attack=0.01, release=0.1)
    builder.add_tone(
        start,
        0.44,
        note_frequency(57),
        note_frequency(50),
        amp=amp * 0.22,
        wave_type="triangle",
        attack=0.01,
        release=0.16,
    )


def add_pressure_swell(builder: AmbienceBuilder, start: float, duration: float, amp: float) -> None:
    builder.add_noise(start, duration, amp=amp * 0.85, color="gust", attack=0.16, release=0.28)
    builder.add_tone(
        start + 0.08,
        duration,
        note_frequency(45),
        note_frequency(57),
        amp=amp * 0.26,
        wave_type="sine",
        attack=0.14,
        release=0.34,
        vibrato_hz=0.22,
        vibrato_depth=0.02,
    )


def render_title(builder: AmbienceBuilder) -> None:
    builder.add_noise(0.0, builder.duration, amp=0.046, color="wind", attack=0.55, release=0.55)
    builder.add_noise(0.0, builder.duration, amp=0.014, color="rumble", attack=0.65, release=0.65)
    builder.add_tone(0.0, builder.duration, note_frequency(38), note_frequency(36), amp=0.03, wave_type="sine", vibrato_hz=0.07, vibrato_depth=0.018)
    builder.add_tone(2.6, 10.4, note_frequency(50), note_frequency(48), amp=0.013, wave_type="triangle", vibrato_hz=0.11, vibrato_depth=0.012)
    for start in (1.8, 6.9, 12.8, 18.4, 22.4):
        add_fire_cluster(builder, start, count=2, spacing=0.18, amp=0.016)
    for start in (4.8, 11.1, 16.7, 20.8):
        add_banner_motion(builder, start, 1.35, amp=0.014)
    for start in (8.6, 19.3):
        builder.add_noise(start, 1.3, amp=0.02, color="gust", attack=0.12, release=0.28)
    for start in (5.4, 14.8, 23.0):
        builder.add_noise(start, 0.42, amp=0.01, color="metal", attack=0.03, release=0.14)
        builder.add_tone(start + 0.02, 0.35, note_frequency(74), note_frequency(70), amp=0.008, wave_type="triangle", attack=0.01, release=0.15)


def render_battle(builder: AmbienceBuilder) -> None:
    builder.add_noise(0.0, builder.duration, amp=0.056, color="wind", attack=0.4, release=0.4)
    builder.add_noise(0.0, builder.duration, amp=0.023, color="rumble", attack=0.45, release=0.45)
    builder.add_tone(0.0, builder.duration, note_frequency(38), note_frequency(34), amp=0.038, wave_type="sine", vibrato_hz=0.09, vibrato_depth=0.022)
    builder.add_tone(1.2, 11.4, note_frequency(45), note_frequency(42), amp=0.014, wave_type="triangle", vibrato_hz=0.13, vibrato_depth=0.016)
    for start in (0.6, 4.0, 7.2, 10.4, 13.8, 17.0, 20.2):
        add_step_group(builder, start, count=3, spacing=0.22, amp=0.022)
    for start in (2.8, 8.1, 14.3, 19.1):
        builder.add_noise(start, 0.44, amp=0.018, color="gust", attack=0.04, release=0.16)
    for start in (3.6, 9.2, 15.1, 21.0):
        builder.add_noise(start, 0.7, amp=0.018, color="crackle", attack=0.02, release=0.24)
    for start in (5.4, 11.8, 18.5):
        builder.add_noise(start, 0.25, amp=0.014, color="metal", attack=0.01, release=0.08)
        builder.add_tone(start, 0.4, note_frequency(57), note_frequency(52), amp=0.01, wave_type="triangle", attack=0.02, release=0.18)
    add_pressure_swell(builder, 16.1, 1.5, amp=0.016)


def render_boss(builder: AmbienceBuilder) -> None:
    builder.add_noise(0.0, builder.duration, amp=0.042, color="wind", attack=0.32, release=0.32)
    builder.add_noise(0.0, builder.duration, amp=0.042, color="rumble", attack=0.3, release=0.3)
    builder.add_tone(0.0, builder.duration, note_frequency(33), note_frequency(31), amp=0.055, wave_type="sine", vibrato_hz=0.05, vibrato_depth=0.018)
    builder.add_tone(0.5, builder.duration - 1.0, note_frequency(45), note_frequency(40), amp=0.016, wave_type="triangle", vibrato_hz=0.09, vibrato_depth=0.013)
    for start in (1.4, 6.2, 10.4, 15.6, 19.1):
        add_chain_event(builder, start, amp=0.02)
    for start in (3.2, 8.9, 13.9, 18.2):
        add_pressure_swell(builder, start, 1.4, amp=0.022)
    for start in (4.7, 12.0, 17.4):
        builder.add_noise(start, 0.9, amp=0.02, color="gust", attack=0.08, release=0.26)
    for start in (5.5, 14.6):
        builder.add_tone(start, 1.8, note_frequency(57), note_frequency(64), amp=0.012, wave_type="sine", attack=0.08, release=0.5, vibrato_hz=0.2, vibrato_depth=0.02)
    for start in (7.8, 16.4):
        builder.add_noise(start, 0.72, amp=0.016, color="metal", attack=0.02, release=0.2)


def build_track(track_id: str) -> AmbienceBuilder:
    builder = AmbienceBuilder(TRACK_SPECS[track_id], stable_seed(track_id))
    if track_id == "ambience_town_title_loop":
        render_title(builder)
    elif track_id == "ambience_town_battle_loop":
        render_battle(builder)
    elif track_id == "ambience_town_boss_loop":
        render_boss(builder)
    else:
        raise ValueError(f"Unknown ambience track: {track_id}")
    return builder


def render_track(track_id: str, output_dir: Path, force: bool) -> bool:
    output_path = output_dir / f"{track_id}.wav"
    if output_path.exists() and not force:
        return False
    builder = build_track(track_id)
    output_dir.mkdir(parents=True, exist_ok=True)
    with wave.open(str(output_path), "wb") as wav_file:
        wav_file.setnchannels(1)
        wav_file.setsampwidth(2)
        wav_file.setframerate(SAMPLE_RATE)
        wav_file.writeframes(builder.finalize())
    return True


def clean_unused(output_dir: Path) -> int:
    removed = 0
    valid_names = {f"{track_id}.wav" for track_id in TRACK_SPECS.keys()}
    for file_path in output_dir.glob("ambience_*.wav"):
        if file_path.name in valid_names:
            continue
        file_path.unlink()
        removed += 1
    return removed


def main() -> int:
    parser = argparse.ArgumentParser(description="Generate prototype ambience layers for Infinity Kingdom.")
    parser.add_argument("--force", action="store_true", help="Overwrite existing wav files.")
    parser.add_argument("--clean", action="store_true", help="Remove stale ambience wav files.")
    args = parser.parse_args()

    root_dir = Path(__file__).resolve().parents[2]
    output_dir = root_dir / "audio" / "generated"
    output_dir.mkdir(parents=True, exist_ok=True)

    written = 0
    for track_id in TRACK_SPECS.keys():
        if render_track(track_id, output_dir, args.force):
            written += 1

    removed = clean_unused(output_dir) if args.clean else 0
    print(f"Generated {written} placeholder ambience files in {output_dir}")
    if removed > 0:
        print(f"Removed {removed} stale ambience files")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
