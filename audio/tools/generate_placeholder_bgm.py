from __future__ import annotations

import argparse
import math
import random
import wave
from pathlib import Path

SAMPLE_RATE = 48_000
MAX_AMPLITUDE = 32_767
BEATS_PER_BAR = 4

TRACK_IDS = [
    "music_title_loop",
    "music_town_battle_loop",
    "music_town_boss_loop",
    "music_victory_stinger",
    "music_defeat_stinger",
]

TITLE_BPM = 92.0
BATTLE_BPM = 124.0
BOSS_BPM = 132.0
VICTORY_BPM = 112.0
DEFEAT_BPM = 104.0

TITLE_BARS = 12
BATTLE_BARS = 12
BOSS_BARS = 12
VICTORY_BARS = 2
DEFEAT_BARS = 2

TOWN_THEME_A = [62, 65, 67, 69, 67, 65, 64, 62]
TOWN_THEME_B = [57, 60, 62, 64, 62, 60, 59, 57]
TOWN_THEME_BOSS = [69, 67, 65, 64, 62, 64, 65, 57]

TITLE_PROGRESSION = [
    [50, 53, 57],
    [46, 50, 53],
    [43, 46, 50],
    [45, 49, 52],
]

BATTLE_PROGRESSION = [
    [50, 53, 57],
    [43, 46, 50],
    [46, 50, 53],
    [45, 49, 52],
]

BOSS_PROGRESSION = [
    [50, 53, 57],
    [48, 52, 55],
    [46, 50, 53],
    [45, 49, 52],
]

TRACK_SPECS = {
    "music_title_loop": {
        "duration": TITLE_BARS * BEATS_PER_BAR * 60.0 / TITLE_BPM,
        "loop": True,
    },
    "music_town_battle_loop": {
        "duration": BATTLE_BARS * BEATS_PER_BAR * 60.0 / BATTLE_BPM,
        "loop": True,
    },
    "music_town_boss_loop": {
        "duration": BOSS_BARS * BEATS_PER_BAR * 60.0 / BOSS_BPM,
        "loop": True,
    },
    "music_victory_stinger": {
        "duration": VICTORY_BARS * BEATS_PER_BAR * 60.0 / VICTORY_BPM,
        "loop": False,
    },
    "music_defeat_stinger": {
        "duration": DEFEAT_BARS * BEATS_PER_BAR * 60.0 / DEFEAT_BPM,
        "loop": False,
    },
}


def note_frequency(midi_note: int) -> float:
    return 440.0 * pow(2.0, (midi_note - 69) / 12.0)


def clamp(value: float, minimum: float = -1.0, maximum: float = 1.0) -> float:
    return max(minimum, min(maximum, value))


def lerp(start: float, end: float, weight: float) -> float:
    return start + (end - start) * weight


def stable_seed(name: str) -> int:
    return sum((index + 1) * ord(char) for index, char in enumerate(name))


def oscillator(kind: str, phase: float) -> float:
    if kind == "sine":
        return math.sin(phase)
    if kind == "triangle":
        return 2.0 * abs(2.0 * ((phase / math.tau) % 1.0) - 1.0) - 1.0
    if kind == "saw":
        return 2.0 * ((phase / math.tau) % 1.0) - 1.0
    if kind == "square":
        return 1.0 if math.sin(phase) >= 0.0 else -1.0
    return math.sin(phase)


class TrackBuilder:
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
        amp: float = 0.18,
        wave_type: str = "sine",
        attack: float = 0.01,
        release: float = 0.1,
        decay: float = 0.7,
        tremolo_hz: float = 0.0,
        tremolo_depth: float = 0.0,
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
            freq = lerp(freq_start, freq_end, progress)
            if vibrato_hz > 0.0 and vibrato_depth > 0.0:
                freq *= 1.0 + math.sin(math.tau * vibrato_hz * clip_index / SAMPLE_RATE) * vibrato_depth
            phase += math.tau * freq / SAMPLE_RATE
            envelope = 1.0
            if progress < attack_ratio:
                envelope *= progress / attack_ratio
            if progress > 1.0 - release_ratio:
                envelope *= max(0.0, (1.0 - progress) / release_ratio)
            envelope *= pow(max(0.0, 1.0 - progress), decay * 0.35)
            if tremolo_hz > 0.0 and tremolo_depth > 0.0:
                envelope *= 1.0 - tremolo_depth + tremolo_depth * (
                    0.5 + 0.5 * math.sin(math.tau * tremolo_hz * clip_index / SAMPLE_RATE)
                )
            self.samples[sample_index] += oscillator(wave_type, phase) * amp * envelope

    def add_noise(
        self,
        start: float,
        duration: float,
        amp: float = 0.1,
        color: str = "white",
        attack: float = 0.001,
        release: float = 0.05,
        decay: float = 1.0,
    ) -> None:
        start_index = max(0, int(start * SAMPLE_RATE))
        end_index = min(self.length, start_index + max(1, int(duration * SAMPLE_RATE)))
        if end_index <= start_index:
            return
        clip_duration = max(duration, 1.0 / SAMPLE_RATE)
        attack_ratio = min(0.95, max(0.0001, attack / clip_duration))
        release_ratio = min(0.95, max(0.0001, release / clip_duration))
        clip_length = max(1, end_index - start_index)
        filtered = 0.0
        last_white = 0.0
        for clip_index, sample_index in enumerate(range(start_index, end_index)):
            progress = clip_index / max(1, clip_length - 1)
            raw = self.random.uniform(-1.0, 1.0)
            if color == "thump":
                filtered = filtered * 0.94 + raw * 0.06
                value = filtered
            elif color == "hiss":
                value = raw - last_white * 0.76
            else:
                value = raw
            last_white = raw
            envelope = 1.0
            if progress < attack_ratio:
                envelope *= progress / attack_ratio
            if progress > 1.0 - release_ratio:
                envelope *= max(0.0, (1.0 - progress) / release_ratio)
            envelope *= pow(max(0.0, 1.0 - progress), decay * 0.5)
            self.samples[sample_index] += value * amp * envelope

    def add_chord(
        self,
        start: float,
        duration: float,
        notes: list[int],
        amp: float,
        wave_type: str = "sine",
        attack: float = 0.03,
        release: float = 0.18,
        decay: float = 0.55,
        tremolo_hz: float = 0.0,
        tremolo_depth: float = 0.0,
    ) -> None:
        for note in notes:
            self.add_tone(
                start,
                duration,
                note_frequency(note),
                amp=amp / max(1, len(notes)),
                wave_type=wave_type,
                attack=attack,
                release=release,
                decay=decay,
                tremolo_hz=tremolo_hz,
                tremolo_depth=tremolo_depth,
            )

    def add_sub_hit(self, start: float, note: int, duration: float, amp: float) -> None:
        self.add_tone(
            start,
            duration,
            note_frequency(note),
            note_frequency(note - 12),
            amp=amp,
            wave_type="sine",
            attack=0.003,
            release=min(duration * 0.65, 0.2),
            decay=1.0,
        )
        self.add_noise(start, min(duration * 0.22, 0.09), amp=amp * 0.18, color="thump", release=0.05, decay=1.1)

    def finalize(self, loop: bool) -> bytes:
        if loop:
            self._apply_boundary_fade(0.01)
        else:
            self._apply_head_tail_fade(0.03, 0.22)
        peak = max(max(abs(sample) for sample in self.samples), 0.001)
        scale = 0.92 / peak
        frames = bytearray()
        for sample in self.samples:
            shaped = math.tanh(sample * scale * 1.18)
            frames.extend(int(clamp(shaped) * MAX_AMPLITUDE).to_bytes(2, byteorder="little", signed=True))
        return bytes(frames)

    def _apply_boundary_fade(self, seconds: float) -> None:
        fade_samples = min(int(seconds * SAMPLE_RATE), self.length // 6)
        for index in range(fade_samples):
            weight = index / max(1, fade_samples - 1)
            self.samples[index] *= weight
            self.samples[self.length - 1 - index] *= weight

    def _apply_head_tail_fade(self, head_seconds: float, tail_seconds: float) -> None:
        head_samples = min(int(head_seconds * SAMPLE_RATE), self.length // 5)
        tail_samples = min(int(tail_seconds * SAMPLE_RATE), self.length // 4)
        for index in range(head_samples):
            self.samples[index] *= index / max(1, head_samples - 1)
        for index in range(tail_samples):
            weight = index / max(1, tail_samples - 1)
            self.samples[self.length - tail_samples + index] *= max(0.0, 1.0 - weight)


def note_time(bar: int, beat: float, bpm: float) -> float:
    return (bar * BEATS_PER_BAR + beat) * 60.0 / bpm


def add_theme_phrase(
    builder: TrackBuilder,
    notes: list[int],
    bar: int,
    beat: float,
    bpm: float,
    step_beats: float,
    amp: float,
    wave_type: str,
    gate: float = 0.82,
    transpose: int = 0,
    accent_pattern: tuple[int, ...] = (),
    release: float = 0.08,
) -> None:
    beat_seconds = 60.0 / bpm
    for index, note in enumerate(notes):
        start_time = note_time(bar, beat + index * step_beats, bpm)
        duration = beat_seconds * step_beats * gate
        accent = 1.18 if index in accent_pattern else 1.0
        builder.add_tone(
            start_time,
            duration,
            note_frequency(note + transpose),
            amp=amp * accent,
            wave_type=wave_type,
            attack=0.004,
            release=release,
            decay=0.82,
            vibrato_hz=5.2,
            vibrato_depth=0.008,
        )


def add_pad_progression(
    builder: TrackBuilder,
    progression: list[list[int]],
    bpm: float,
    amp: float,
    wave_type: str,
    upper_amp: float = 0.0,
) -> None:
    bar_duration = 60.0 / bpm * BEATS_PER_BAR
    for bar in range(len(progression)):
        start = bar * bar_duration
        chord = progression[bar]
        builder.add_chord(
            start,
            bar_duration,
            chord,
            amp,
            wave_type=wave_type,
            attack=0.05,
            release=0.26,
            decay=0.42,
            tremolo_hz=3.2,
            tremolo_depth=0.1,
        )
        if upper_amp > 0.0:
            builder.add_chord(
                start + bar_duration * 0.48,
                bar_duration * 0.7,
                [note + 12 for note in chord],
                upper_amp,
                wave_type="triangle",
                attack=0.04,
                release=0.2,
                decay=0.48,
                tremolo_hz=4.0,
                tremolo_depth=0.06,
            )


def add_drone(builder: TrackBuilder, roots: list[int], bpm: float, amp: float) -> None:
    bar_duration = 60.0 / bpm * BEATS_PER_BAR
    for bar, root in enumerate(roots):
        start = bar * bar_duration
        builder.add_tone(
            start,
            bar_duration,
            note_frequency(root - 12),
            amp=amp,
            wave_type="sine",
            attack=0.02,
            release=0.3,
            decay=0.5,
        )
        builder.add_tone(
            start,
            bar_duration * 0.82,
            note_frequency(root - 5),
            amp=amp * 0.45,
            wave_type="triangle",
            attack=0.03,
            release=0.2,
            decay=0.6,
        )


def add_soft_pulse_bar(builder: TrackBuilder, bar: int, root: int, bpm: float, amp: float) -> None:
    beat_seconds = 60.0 / bpm
    for beat in (0.0, 2.0):
        builder.add_sub_hit(note_time(bar, beat, bpm), root - 24, beat_seconds * 0.88, amp)
    builder.add_noise(note_time(bar, 1.5, bpm), beat_seconds * 0.08, amp=amp * 0.18, color="hiss", release=0.04, decay=0.8)


def add_march_bar(builder: TrackBuilder, bar: int, root: int, bpm: float, intensity: float, boss: bool = False) -> None:
    beat_seconds = 60.0 / bpm
    kick_pattern = (0.0, 1.5, 2.0, 3.0) if boss else (0.0, 2.0, 3.0)
    for beat in kick_pattern:
        builder.add_sub_hit(note_time(bar, beat, bpm), root - 24, beat_seconds * 0.58, 0.11 * intensity)
    for beat in (1.0, 3.0):
        start = note_time(bar, beat, bpm)
        builder.add_noise(start, beat_seconds * 0.14, amp=0.08 * intensity, color="hiss", release=0.06, decay=0.82)
        builder.add_tone(start, beat_seconds * 0.12, note_frequency(root + 12), note_frequency(root + 7), amp=0.03 * intensity, wave_type="triangle", release=0.05, decay=0.9)
    hat_steps = 8 if boss else 6
    for step in range(hat_steps):
        hat_start = note_time(bar, step * 0.5, bpm)
        builder.add_noise(hat_start, beat_seconds * 0.05, amp=0.026 * intensity, color="hiss", release=0.02, decay=0.82)


def add_ostinato_bar(
    builder: TrackBuilder,
    chord: list[int],
    bar: int,
    bpm: float,
    amp: float,
    wave_type: str,
    pattern: tuple[int, ...],
    note_length_beats: float = 0.42,
) -> None:
    beat_seconds = 60.0 / bpm
    notes = chord + [chord[-1] + 12]
    for step, note_index in enumerate(pattern):
        start = note_time(bar, step * 0.5, bpm)
        builder.add_tone(
            start,
            beat_seconds * note_length_beats,
            note_frequency(notes[note_index]),
            amp=amp,
            wave_type=wave_type,
            attack=0.003,
            release=0.07,
            decay=0.9,
            vibrato_hz=4.8,
            vibrato_depth=0.006,
        )


def add_bell_glint(builder: TrackBuilder, bar: int, beat: float, note: int, bpm: float, amp: float) -> None:
    start = note_time(bar, beat, bpm)
    builder.add_tone(
        start,
        60.0 / bpm * 1.1,
        note_frequency(note),
        amp=amp,
        wave_type="sine",
        attack=0.003,
        release=0.3,
        decay=0.5,
        vibrato_hz=6.5,
        vibrato_depth=0.01,
    )
    builder.add_tone(
        start + 0.015,
        60.0 / bpm * 0.9,
        note_frequency(note + 12),
        amp=amp * 0.55,
        wave_type="triangle",
        attack=0.003,
        release=0.26,
        decay=0.55,
    )


def render_title_loop(builder: TrackBuilder) -> None:
    progression = TITLE_PROGRESSION * 3
    roots = [chord[0] for chord in progression]
    add_pad_progression(builder, progression, TITLE_BPM, amp=0.22, wave_type="sine", upper_amp=0.09)
    add_drone(builder, roots, TITLE_BPM, amp=0.08)
    for bar, root in enumerate(roots):
        add_soft_pulse_bar(builder, bar, root, TITLE_BPM, amp=0.085)
    for bar in (0, 4, 8):
        add_theme_phrase(
            builder,
            TOWN_THEME_A,
            bar,
            0.5,
            TITLE_BPM,
            0.5,
            amp=0.072,
            wave_type="triangle",
            accent_pattern=(0, 3, 7),
            release=0.12,
        )
        add_theme_phrase(
            builder,
            TOWN_THEME_B,
            bar + 1,
            0.5,
            TITLE_BPM,
            0.5,
            amp=0.05,
            wave_type="sine",
            transpose=12,
            accent_pattern=(0, 4),
            release=0.14,
        )
    for bar in (1, 5, 9, 11):
        add_bell_glint(builder, bar, 3.0, progression[bar][1] + 12, TITLE_BPM, amp=0.038)
    add_theme_phrase(builder, [69, 67, 65, 64], 10, 2.0, TITLE_BPM, 0.5, amp=0.055, wave_type="sine", transpose=12, accent_pattern=(0,))


def render_town_battle_loop(builder: TrackBuilder) -> None:
    progression = BATTLE_PROGRESSION * 3
    roots = [chord[0] for chord in progression]
    add_pad_progression(builder, progression, BATTLE_BPM, amp=0.16, wave_type="triangle", upper_amp=0.05)
    add_drone(builder, roots, BATTLE_BPM, amp=0.045)
    ostinato_pattern = (0, 1, 2, 1, 2, 3, 2, 1)
    for bar, chord in enumerate(progression):
        intensity = 1.0 if bar < 8 else 1.12
        add_march_bar(builder, bar, chord[0], BATTLE_BPM, intensity)
        add_ostinato_bar(builder, [note + 12 for note in chord], bar, BATTLE_BPM, amp=0.05 * intensity, wave_type="saw", pattern=ostinato_pattern)
        if bar % 2 == 0:
            add_theme_phrase(
                builder,
                TOWN_THEME_A[:4],
                bar,
                0.0,
                BATTLE_BPM,
                0.5,
                amp=0.07 * intensity,
                wave_type="triangle",
                transpose=0,
                accent_pattern=(0, 3),
                release=0.09,
            )
        else:
            add_theme_phrase(
                builder,
                TOWN_THEME_B[:4],
                bar,
                1.0,
                BATTLE_BPM,
                0.5,
                amp=0.058 * intensity,
                wave_type="sine",
                transpose=12,
                accent_pattern=(0,),
                release=0.08,
            )
    add_theme_phrase(builder, [62, 64, 65, 67, 69, 67, 65, 64], 8, 0.5, BATTLE_BPM, 0.5, amp=0.06, wave_type="sine", transpose=12, accent_pattern=(0, 4), release=0.1)
    add_theme_phrase(builder, [69, 67, 65, 64], 11, 1.5, BATTLE_BPM, 0.5, amp=0.08, wave_type="triangle", accent_pattern=(0, 3), release=0.1)


def render_town_boss_loop(builder: TrackBuilder) -> None:
    progression = BOSS_PROGRESSION * 3
    roots = [chord[0] for chord in progression]
    add_pad_progression(builder, progression, BOSS_BPM, amp=0.18, wave_type="saw", upper_amp=0.06)
    add_drone(builder, roots, BOSS_BPM, amp=0.055)
    ostinato_pattern = (0, 2, 1, 2, 0, 2, 3, 2)
    for bar, chord in enumerate(progression):
        intensity = 1.08 if bar < 8 else 1.2
        add_march_bar(builder, bar, chord[0], BOSS_BPM, intensity, boss=True)
        add_ostinato_bar(builder, [note - 12 for note in chord], bar, BOSS_BPM, amp=0.058 * intensity, wave_type="square", pattern=ostinato_pattern, note_length_beats=0.36)
        if bar % 2 == 0:
            add_theme_phrase(
                builder,
                TOWN_THEME_BOSS[:4],
                bar,
                0.5,
                BOSS_BPM,
                0.5,
                amp=0.08 * intensity,
                wave_type="triangle",
                transpose=-12,
                accent_pattern=(0, 2),
                release=0.08,
            )
        else:
            add_theme_phrase(
                builder,
                TOWN_THEME_BOSS[4:],
                bar,
                1.0,
                BOSS_BPM,
                0.5,
                amp=0.068 * intensity,
                wave_type="saw",
                transpose=0,
                accent_pattern=(0, 3),
                release=0.07,
            )
        if bar in (6, 10):
            add_bell_glint(builder, bar, 3.0, chord[1] + 12, BOSS_BPM, amp=0.03)
    builder.add_tone(note_time(10, 2.0, BOSS_BPM), 60.0 / BOSS_BPM * 2.8, note_frequency(74), note_frequency(86), amp=0.06, wave_type="sine", attack=0.01, release=0.16, decay=0.72)
    add_theme_phrase(builder, [69, 67, 65, 64, 62, 64, 65, 69], 11, 0.0, BOSS_BPM, 0.5, amp=0.085, wave_type="triangle", transpose=0, accent_pattern=(0, 4, 7), release=0.08)


def render_victory_stinger(builder: TrackBuilder) -> None:
    beat_seconds = 60.0 / VICTORY_BPM
    intro_chords = [
        [50, 53, 57],
        [55, 59, 62],
    ]
    for bar, chord in enumerate(intro_chords):
        builder.add_chord(note_time(bar, 0.0, VICTORY_BPM), beat_seconds * BEATS_PER_BAR, chord, amp=0.24, wave_type="triangle", attack=0.02, release=0.28, decay=0.52)
        builder.add_chord(note_time(bar, 0.0, VICTORY_BPM), beat_seconds * BEATS_PER_BAR, [note + 12 for note in chord], amp=0.1, wave_type="sine", attack=0.01, release=0.26, decay=0.5)
        builder.add_sub_hit(note_time(bar, 0.0, VICTORY_BPM), chord[0] - 12, beat_seconds * 0.9, 0.11)
    add_theme_phrase(builder, [62, 65, 67, 69], 0, 0.5, VICTORY_BPM, 0.5, amp=0.085, wave_type="triangle", accent_pattern=(0, 3), release=0.1)
    add_theme_phrase(builder, [69, 71, 74, 76], 1, 0.0, VICTORY_BPM, 0.5, amp=0.09, wave_type="sine", accent_pattern=(0, 3), release=0.14)
    builder.add_chord(note_time(1, 2.0, VICTORY_BPM), beat_seconds * 1.8, [50, 54, 57, 62], amp=0.28, wave_type="triangle", attack=0.01, release=0.34, decay=0.45)
    add_bell_glint(builder, 1, 2.0, 74, VICTORY_BPM, amp=0.055)


def render_defeat_stinger(builder: TrackBuilder) -> None:
    beat_seconds = 60.0 / DEFEAT_BPM
    falling_notes = [69, 67, 65, 62, 60, 57]
    add_theme_phrase(builder, falling_notes, 0, 0.0, DEFEAT_BPM, 0.5, amp=0.075, wave_type="square", transpose=-12, accent_pattern=(0, 3), release=0.12)
    for beat, root in zip((0.0, 1.5, 2.5, 3.5), (50, 48, 46, 45)):
        start = note_time(0, beat, DEFEAT_BPM)
        builder.add_tone(start, beat_seconds * 1.1, note_frequency(root), note_frequency(root - 7), amp=0.14, wave_type="square", attack=0.004, release=0.22, decay=1.0)
        builder.add_tone(start, beat_seconds * 1.25, note_frequency(root - 12), amp=0.1, wave_type="sine", attack=0.003, release=0.28, decay=1.15)
        builder.add_noise(start, beat_seconds * 0.16, amp=0.05, color="thump", release=0.06, decay=1.15)
    builder.add_chord(note_time(1, 1.5, DEFEAT_BPM), beat_seconds * 2.0, [45, 48, 52], amp=0.13, wave_type="triangle", attack=0.02, release=0.34, decay=0.7)
    builder.add_noise(note_time(1, 0.0, DEFEAT_BPM), beat_seconds * 0.75, amp=0.035, color="hiss", release=0.2, decay=0.95)


def build_track(track_id: str) -> tuple[TrackBuilder, bool]:
    spec = TRACK_SPECS[track_id]
    builder = TrackBuilder(float(spec["duration"]), stable_seed(track_id))
    if track_id == "music_title_loop":
        render_title_loop(builder)
    elif track_id == "music_town_battle_loop":
        render_town_battle_loop(builder)
    elif track_id == "music_town_boss_loop":
        render_town_boss_loop(builder)
    elif track_id == "music_victory_stinger":
        render_victory_stinger(builder)
    elif track_id == "music_defeat_stinger":
        render_defeat_stinger(builder)
    else:
        raise ValueError(f"Unknown track id: {track_id}")
    return builder, bool(spec["loop"])


def render_track(track_id: str, output_dir: Path, force: bool) -> bool:
    output_path = output_dir / f"{track_id}.wav"
    if output_path.exists() and not force:
        return False
    builder, loop = build_track(track_id)
    output_dir.mkdir(parents=True, exist_ok=True)
    with wave.open(str(output_path), "wb") as wav_file:
        wav_file.setnchannels(1)
        wav_file.setsampwidth(2)
        wav_file.setframerate(SAMPLE_RATE)
        wav_file.writeframes(builder.finalize(loop))
    return True


def clean_unused(output_dir: Path) -> int:
    removed = 0
    valid_names = {f"{track_id}.wav" for track_id in TRACK_IDS}
    for file_path in output_dir.glob("music_*.wav"):
        if file_path.name in valid_names:
            continue
        file_path.unlink()
        removed += 1
    return removed


def main() -> int:
    parser = argparse.ArgumentParser(description="Generate town-chapter prototype BGM placeholders for Infinity Kingdom.")
    parser.add_argument("--force", action="store_true", help="Overwrite existing wav files.")
    parser.add_argument("--clean", action="store_true", help="Remove stale generated music wav files.")
    args = parser.parse_args()

    root_dir = Path(__file__).resolve().parents[2]
    output_dir = root_dir / "audio" / "generated"
    output_dir.mkdir(parents=True, exist_ok=True)

    written = 0
    for track_id in TRACK_IDS:
        if render_track(track_id, output_dir, args.force):
            written += 1

    removed = clean_unused(output_dir) if args.clean else 0
    print(f"Generated {written} placeholder BGM files in {output_dir}")
    if removed > 0:
        print(f"Removed {removed} stale music files")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
