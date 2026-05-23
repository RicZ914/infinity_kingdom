from __future__ import annotations

import argparse
import math
import random
import wave
from pathlib import Path

SAMPLE_RATE = 48_000
MAX_AMPLITUDE = 32_767

EVENTS = {
	"ui_confirm": {"preset": "ui_confirm", "duration": 0.22, "pitch": 1.0, "intensity": 1.0},
	"knight_attack": {"preset": "melee_heavy", "duration": 0.34, "pitch": 0.95, "intensity": 1.0},
	"knight_skill1_charge": {"preset": "charge_heavy", "duration": 0.7, "pitch": 0.82, "intensity": 1.15},
	"knight_skill2_shockwave": {"preset": "slam", "duration": 0.52, "pitch": 0.78, "intensity": 1.2},
	"knight_skill3_sanctuary": {"preset": "sanctuary", "duration": 0.92, "pitch": 0.92, "intensity": 1.0},
	"knight_hit": {"preset": "hurt_heavy", "duration": 0.22, "pitch": 0.86, "intensity": 0.95},
	"knight_dead": {"preset": "death_heavy", "duration": 1.12, "pitch": 0.76, "intensity": 1.05},
	"ranger_attack": {"preset": "melee_light", "duration": 0.18, "pitch": 1.25, "intensity": 0.92},
	"ranger_skill1_arrow": {"preset": "bow_shot", "duration": 0.28, "pitch": 1.08, "intensity": 0.98},
	"ranger_skill2_roll": {"preset": "dash_light", "duration": 0.24, "pitch": 1.15, "intensity": 0.88},
	"ranger_skill3_assassinate": {"preset": "assassinate", "duration": 0.4, "pitch": 1.1, "intensity": 1.0},
	"ranger_hit": {"preset": "hurt_light", "duration": 0.18, "pitch": 1.18, "intensity": 0.9},
	"ranger_dead": {"preset": "death_light", "duration": 0.62, "pitch": 1.04, "intensity": 0.92},
	"mage_attack": {"preset": "mage_cast", "duration": 0.26, "pitch": 1.12, "intensity": 0.95},
	"mage_skill1_blades": {"preset": "arcane_orbit", "duration": 0.65, "pitch": 1.0, "intensity": 1.0},
	"mage_skill2_burst": {"preset": "arcane_burst", "duration": 0.46, "pitch": 1.04, "intensity": 1.05},
	"mage_skill3_enchant": {"preset": "enchant", "duration": 0.34, "pitch": 1.08, "intensity": 0.92},
	"mage_hit": {"preset": "mage_hurt", "duration": 0.22, "pitch": 1.12, "intensity": 0.88},
	"mage_dead": {"preset": "mage_death", "duration": 0.92, "pitch": 0.96, "intensity": 0.95},
	"enemy_swordsman_attack": {"preset": "melee_light", "duration": 0.24, "pitch": 0.98, "intensity": 0.92},
	"enemy_shield_bash": {"preset": "shield_bash", "duration": 0.32, "pitch": 0.82, "intensity": 1.0},
	"enemy_archer_shot": {"preset": "bow_shot", "duration": 0.26, "pitch": 0.96, "intensity": 0.9},
	"enemy_hunter_dash": {"preset": "dash_light", "duration": 0.25, "pitch": 0.92, "intensity": 0.95},
	"enemy_apprentice_cast": {"preset": "apprentice_cast", "duration": 0.34, "pitch": 0.95, "intensity": 0.92},
	"enemy_arcanist_cast": {"preset": "arcanist_cast", "duration": 0.56, "pitch": 0.9, "intensity": 1.05},
	"enemy_generic_hit": {"preset": "hurt_light", "duration": 0.14, "pitch": 0.88, "intensity": 0.84},
	"enemy_generic_dead": {"preset": "death_light", "duration": 0.5, "pitch": 0.86, "intensity": 0.95},
	"boss_judicator_attack": {"preset": "melee_heavy", "duration": 0.42, "pitch": 0.78, "intensity": 1.15},
	"boss_judicator_skill1": {"preset": "slam", "duration": 0.78, "pitch": 0.7, "intensity": 1.3},
	"boss_judicator_skill2": {"preset": "line_smash", "duration": 0.72, "pitch": 0.74, "intensity": 1.22},
	"boss_guard_immune_break": {"preset": "barrier_break", "duration": 0.62, "pitch": 0.98, "intensity": 1.12},
	"boss_twin_teleport": {"preset": "teleport_slash", "duration": 0.4, "pitch": 1.04, "intensity": 1.0},
	"boss_twin_charge": {"preset": "royal_charge", "duration": 0.62, "pitch": 0.84, "intensity": 1.12},
	"boss_twin_barrage": {"preset": "projectile_barrage", "duration": 0.7, "pitch": 1.02, "intensity": 1.06},
	"boss_generic_dead": {"preset": "boss_death", "duration": 1.32, "pitch": 0.72, "intensity": 1.2},
}


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


class SoundBuilder:
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
		amp: float = 0.25,
		wave_type: str = "sine",
		attack: float = 0.005,
		release: float = 0.05,
		decay: float = 1.0,
		vibrato_hz: float = 0.0,
		vibrato_amount: float = 0.0,
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
		phase = 0.0
		clip_length = max(1, end_index - start_index)
		for clip_index, sample_index in enumerate(range(start_index, end_index)):
			progress = clip_index / max(1, clip_length - 1)
			freq = lerp(freq_start, freq_end, progress)
			if vibrato_hz > 0.0 and vibrato_amount > 0.0:
				freq *= 1.0 + math.sin(math.tau * vibrato_hz * clip_index / SAMPLE_RATE) * vibrato_amount
			phase += math.tau * freq / SAMPLE_RATE
			envelope = 1.0
			if progress < attack_ratio:
				envelope *= progress / attack_ratio
			if progress > 1.0 - release_ratio:
				envelope *= max(0.0, (1.0 - progress) / release_ratio)
			envelope *= pow(max(0.0, 1.0 - progress), decay * 0.5)
			self.samples[sample_index] += oscillator(wave_type, phase) * amp * envelope

	def add_noise(
		self,
		start: float,
		duration: float,
		amp: float = 0.2,
		color: str = "white",
		attack: float = 0.001,
		release: float = 0.04,
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
		last_white = 0.0
		filtered = 0.0
		for clip_index, sample_index in enumerate(range(start_index, end_index)):
			progress = clip_index / max(1, clip_length - 1)
			raw = self.random.uniform(-1.0, 1.0)
			if color == "thump":
				filtered = filtered * 0.92 + raw * 0.08
				value = filtered
			elif color == "hiss":
				value = raw - last_white * 0.78
			elif color == "shatter":
				filtered = filtered * 0.7 + raw * 0.3
				value = (raw - filtered) * 1.6
			else:
				value = raw
			last_white = raw
			envelope = 1.0
			if progress < attack_ratio:
				envelope *= progress / attack_ratio
			if progress > 1.0 - release_ratio:
				envelope *= max(0.0, (1.0 - progress) / release_ratio)
			envelope *= pow(max(0.0, 1.0 - progress), decay * 0.65)
			self.samples[sample_index] += value * amp * envelope

	def add_echo(self, delay: float, gain: float, repeats: int = 1) -> None:
		delay_samples = int(delay * SAMPLE_RATE)
		if delay_samples <= 0 or repeats <= 0:
			return
		source = self.samples[:]
		for repeat in range(1, repeats + 1):
			offset = delay_samples * repeat
			scale = gain ** repeat
			for index in range(self.length - offset):
				self.samples[index + offset] += source[index] * scale

	def finalize(self) -> bytes:
		peak = max(max(abs(sample) for sample in self.samples), 0.001)
		scale = 0.88 / peak
		frames = bytearray()
		for sample in self.samples:
			shaped = math.tanh(sample * scale * 1.35)
			frames.extend(int(clamp(shaped) * MAX_AMPLITUDE).to_bytes(2, byteorder="little", signed=True))
		return bytes(frames)


def preset_ui_confirm(builder: SoundBuilder, pitch: float, intensity: float) -> None:
	builder.add_tone(0.0, 0.18, 1320.0 * pitch, 1980.0 * pitch, amp=0.28 * intensity, wave_type="sine", release=0.08, decay=0.45)
	builder.add_tone(0.03, 0.12, 1980.0 * pitch, 2420.0 * pitch, amp=0.16 * intensity, wave_type="triangle", release=0.05, decay=0.35)
	builder.add_noise(0.0, 0.02, amp=0.025 * intensity, color="hiss", release=0.02)


def preset_melee_light(builder: SoundBuilder, pitch: float, intensity: float) -> None:
	builder.add_noise(0.0, builder.duration * 0.55, amp=0.1 * intensity, color="hiss", release=0.05, decay=0.7)
	builder.add_tone(0.02, builder.duration * 0.72, 720.0 * pitch, 180.0 * pitch, amp=0.16 * intensity, wave_type="saw", release=0.08, decay=0.95)
	builder.add_tone(0.04, builder.duration * 0.25, 220.0 * pitch, 120.0 * pitch, amp=0.07 * intensity, wave_type="triangle", release=0.05)


def preset_melee_heavy(builder: SoundBuilder, pitch: float, intensity: float) -> None:
	builder.add_noise(0.0, builder.duration * 0.62, amp=0.14 * intensity, color="hiss", release=0.08, decay=0.8)
	builder.add_tone(0.03, builder.duration * 0.72, 560.0 * pitch, 120.0 * pitch, amp=0.22 * intensity, wave_type="saw", release=0.14, decay=1.05)
	builder.add_noise(0.08, builder.duration * 0.22, amp=0.09 * intensity, color="thump", release=0.12, decay=1.2)
	builder.add_tone(0.08, builder.duration * 0.28, 96.0 * pitch, 54.0 * pitch, amp=0.14 * intensity, wave_type="sine", release=0.12, decay=1.4)


def preset_charge_heavy(builder: SoundBuilder, pitch: float, intensity: float) -> None:
	builder.add_tone(0.0, builder.duration * 0.42, 150.0 * pitch, 240.0 * pitch, amp=0.12 * intensity, wave_type="triangle", attack=0.02, release=0.08, decay=0.6)
	builder.add_noise(builder.duration * 0.22, builder.duration * 0.28, amp=0.08 * intensity, color="hiss", release=0.08, decay=0.8)
	builder.add_tone(builder.duration * 0.28, builder.duration * 0.48, 460.0 * pitch, 90.0 * pitch, amp=0.22 * intensity, wave_type="saw", release=0.16, decay=1.1)
	builder.add_tone(builder.duration * 0.32, builder.duration * 0.22, 110.0 * pitch, 58.0 * pitch, amp=0.18 * intensity, wave_type="sine", release=0.14, decay=1.3)
	builder.add_noise(builder.duration * 0.36, builder.duration * 0.18, amp=0.07 * intensity, color="thump", release=0.12, decay=1.2)


def preset_slam(builder: SoundBuilder, pitch: float, intensity: float) -> None:
	builder.add_tone(0.0, builder.duration * 0.34, 170.0 * pitch, 95.0 * pitch, amp=0.16 * intensity, wave_type="triangle", attack=0.01, release=0.09, decay=0.6)
	builder.add_noise(builder.duration * 0.18, builder.duration * 0.34, amp=0.17 * intensity, color="shatter", release=0.14, decay=1.1)
	builder.add_noise(builder.duration * 0.2, builder.duration * 0.24, amp=0.12 * intensity, color="thump", release=0.18, decay=1.4)
	builder.add_tone(builder.duration * 0.2, builder.duration * 0.4, 120.0 * pitch, 42.0 * pitch, amp=0.22 * intensity, wave_type="sine", release=0.2, decay=1.6)


def preset_sanctuary(builder: SoundBuilder, pitch: float, intensity: float) -> None:
	builder.add_tone(0.0, builder.duration * 0.82, 520.0 * pitch, 760.0 * pitch, amp=0.14 * intensity, wave_type="sine", attack=0.03, release=0.24, decay=0.5, vibrato_hz=4.0, vibrato_amount=0.01)
	builder.add_tone(0.08, builder.duration * 0.68, 910.0 * pitch, 1140.0 * pitch, amp=0.12 * intensity, wave_type="triangle", attack=0.02, release=0.22, decay=0.55)
	builder.add_tone(0.12, builder.duration * 0.55, 1260.0 * pitch, 1520.0 * pitch, amp=0.08 * intensity, wave_type="sine", attack=0.02, release=0.2, decay=0.6)
	builder.add_echo(0.09, 0.35, repeats=2)


def preset_hurt_heavy(builder: SoundBuilder, pitch: float, intensity: float) -> None:
	builder.add_noise(0.0, builder.duration * 0.5, amp=0.14 * intensity, color="thump", release=0.05, decay=1.2)
	builder.add_tone(0.0, builder.duration * 0.45, 160.0 * pitch, 72.0 * pitch, amp=0.12 * intensity, wave_type="square", release=0.06, decay=1.1)


def preset_hurt_light(builder: SoundBuilder, pitch: float, intensity: float) -> None:
	builder.add_noise(0.0, builder.duration * 0.42, amp=0.1 * intensity, color="white", release=0.04, decay=1.0)
	builder.add_tone(0.0, builder.duration * 0.36, 320.0 * pitch, 150.0 * pitch, amp=0.07 * intensity, wave_type="triangle", release=0.05, decay=0.9)


def preset_death_heavy(builder: SoundBuilder, pitch: float, intensity: float) -> None:
	builder.add_noise(0.02, builder.duration * 0.48, amp=0.12 * intensity, color="thump", release=0.26, decay=1.3)
	builder.add_noise(0.12, builder.duration * 0.38, amp=0.09 * intensity, color="shatter", release=0.3, decay=1.2)
	builder.add_tone(0.0, builder.duration * 0.82, 150.0 * pitch, 38.0 * pitch, amp=0.14 * intensity, wave_type="square", attack=0.01, release=0.32, decay=1.8)
	builder.add_tone(0.08, builder.duration * 0.62, 70.0 * pitch, 28.0 * pitch, amp=0.12 * intensity, wave_type="sine", release=0.36, decay=2.0)


def preset_death_light(builder: SoundBuilder, pitch: float, intensity: float) -> None:
	builder.add_noise(0.0, builder.duration * 0.4, amp=0.09 * intensity, color="white", release=0.12, decay=1.0)
	builder.add_tone(0.0, builder.duration * 0.72, 280.0 * pitch, 72.0 * pitch, amp=0.1 * intensity, wave_type="triangle", release=0.2, decay=1.5)


def preset_bow_shot(builder: SoundBuilder, pitch: float, intensity: float) -> None:
	builder.add_tone(0.0, builder.duration * 0.25, 640.0 * pitch, 260.0 * pitch, amp=0.15 * intensity, wave_type="triangle", release=0.04, decay=0.8)
	builder.add_tone(0.02, builder.duration * 0.18, 1240.0 * pitch, 840.0 * pitch, amp=0.06 * intensity, wave_type="sine", release=0.04, decay=0.6)
	builder.add_noise(0.02, builder.duration * 0.44, amp=0.06 * intensity, color="hiss", release=0.06, decay=0.85)


def preset_dash_light(builder: SoundBuilder, pitch: float, intensity: float) -> None:
	builder.add_noise(0.0, builder.duration * 0.72, amp=0.1 * intensity, color="hiss", release=0.08, decay=0.75)
	builder.add_tone(0.02, builder.duration * 0.36, 240.0 * pitch, 420.0 * pitch, amp=0.06 * intensity, wave_type="triangle", release=0.06, decay=0.8)


def preset_assassinate(builder: SoundBuilder, pitch: float, intensity: float) -> None:
	builder.add_noise(0.0, builder.duration * 0.26, amp=0.08 * intensity, color="hiss", release=0.05, decay=0.7)
	builder.add_tone(0.08, builder.duration * 0.62, 880.0 * pitch, 180.0 * pitch, amp=0.18 * intensity, wave_type="saw", release=0.09, decay=1.0)
	builder.add_tone(0.1, builder.duration * 0.22, 180.0 * pitch, 90.0 * pitch, amp=0.1 * intensity, wave_type="square", release=0.06, decay=1.0)


def preset_mage_cast(builder: SoundBuilder, pitch: float, intensity: float) -> None:
	builder.add_tone(0.0, builder.duration * 0.74, 520.0 * pitch, 1220.0 * pitch, amp=0.14 * intensity, wave_type="sine", release=0.08, decay=0.55, vibrato_hz=7.0, vibrato_amount=0.012)
	builder.add_tone(0.04, builder.duration * 0.44, 760.0 * pitch, 1480.0 * pitch, amp=0.08 * intensity, wave_type="triangle", release=0.06, decay=0.45)
	builder.add_noise(0.0, builder.duration * 0.24, amp=0.03 * intensity, color="hiss", release=0.04)


def preset_arcane_orbit(builder: SoundBuilder, pitch: float, intensity: float) -> None:
	builder.add_tone(0.0, builder.duration * 0.84, 360.0 * pitch, 760.0 * pitch, amp=0.12 * intensity, wave_type="triangle", attack=0.02, release=0.18, decay=0.6)
	builder.add_tone(0.06, builder.duration * 0.72, 1040.0 * pitch, 820.0 * pitch, amp=0.1 * intensity, wave_type="sine", attack=0.02, release=0.18, decay=0.55, vibrato_hz=6.5, vibrato_amount=0.018)
	builder.add_tone(0.1, builder.duration * 0.42, 1480.0 * pitch, 1740.0 * pitch, amp=0.05 * intensity, wave_type="sine", release=0.12, decay=0.4)
	builder.add_echo(0.07, 0.28, repeats=2)


def preset_arcane_burst(builder: SoundBuilder, pitch: float, intensity: float) -> None:
	builder.add_tone(0.0, builder.duration * 0.28, 420.0 * pitch, 640.0 * pitch, amp=0.1 * intensity, wave_type="triangle", release=0.05, decay=0.6)
	builder.add_noise(builder.duration * 0.18, builder.duration * 0.22, amp=0.12 * intensity, color="white", release=0.08, decay=0.8)
	builder.add_tone(builder.duration * 0.18, builder.duration * 0.46, 1640.0 * pitch, 340.0 * pitch, amp=0.18 * intensity, wave_type="saw", release=0.12, decay=0.95)
	builder.add_tone(builder.duration * 0.2, builder.duration * 0.32, 220.0 * pitch, 70.0 * pitch, amp=0.09 * intensity, wave_type="sine", release=0.1, decay=1.1)
	builder.add_echo(0.05, 0.22, repeats=2)


def preset_enchant(builder: SoundBuilder, pitch: float, intensity: float) -> None:
	builder.add_tone(0.0, builder.duration * 0.7, 720.0 * pitch, 980.0 * pitch, amp=0.1 * intensity, wave_type="triangle", attack=0.01, release=0.1, decay=0.5)
	builder.add_tone(0.08, builder.duration * 0.36, 1400.0 * pitch, 1180.0 * pitch, amp=0.06 * intensity, wave_type="sine", release=0.08, decay=0.5)
	builder.add_echo(0.05, 0.2, repeats=1)


def preset_mage_hurt(builder: SoundBuilder, pitch: float, intensity: float) -> None:
	builder.add_noise(0.0, builder.duration * 0.4, amp=0.06 * intensity, color="shatter", release=0.05, decay=0.9)
	builder.add_tone(0.0, builder.duration * 0.45, 420.0 * pitch, 160.0 * pitch, amp=0.08 * intensity, wave_type="triangle", release=0.06, decay=0.9)


def preset_mage_death(builder: SoundBuilder, pitch: float, intensity: float) -> None:
	builder.add_tone(0.0, builder.duration * 0.82, 420.0 * pitch, 80.0 * pitch, amp=0.12 * intensity, wave_type="triangle", attack=0.01, release=0.22, decay=1.4)
	builder.add_tone(0.06, builder.duration * 0.54, 1180.0 * pitch, 260.0 * pitch, amp=0.08 * intensity, wave_type="sine", release=0.18, decay=1.0)
	builder.add_noise(0.04, builder.duration * 0.32, amp=0.05 * intensity, color="shatter", release=0.14, decay=0.95)
	builder.add_echo(0.08, 0.18, repeats=2)


def preset_shield_bash(builder: SoundBuilder, pitch: float, intensity: float) -> None:
	builder.add_noise(0.0, builder.duration * 0.42, amp=0.14 * intensity, color="thump", release=0.07, decay=1.1)
	builder.add_noise(0.02, builder.duration * 0.28, amp=0.07 * intensity, color="shatter", release=0.08, decay=0.9)
	builder.add_tone(0.0, builder.duration * 0.36, 180.0 * pitch, 82.0 * pitch, amp=0.12 * intensity, wave_type="square", release=0.08, decay=1.2)


def preset_apprentice_cast(builder: SoundBuilder, pitch: float, intensity: float) -> None:
	builder.add_tone(0.0, builder.duration * 0.72, 420.0 * pitch, 920.0 * pitch, amp=0.11 * intensity, wave_type="triangle", release=0.08, decay=0.6, vibrato_hz=5.0, vibrato_amount=0.03)
	builder.add_noise(0.08, builder.duration * 0.22, amp=0.04 * intensity, color="white", release=0.05, decay=0.8)


def preset_arcanist_cast(builder: SoundBuilder, pitch: float, intensity: float) -> None:
	builder.add_tone(0.0, builder.duration * 0.8, 220.0 * pitch, 620.0 * pitch, amp=0.13 * intensity, wave_type="sine", attack=0.03, release=0.16, decay=0.55, vibrato_hz=3.5, vibrato_amount=0.01)
	builder.add_tone(0.1, builder.duration * 0.58, 860.0 * pitch, 1240.0 * pitch, amp=0.09 * intensity, wave_type="triangle", attack=0.02, release=0.14, decay=0.6)
	builder.add_noise(0.12, builder.duration * 0.24, amp=0.03 * intensity, color="hiss", release=0.06, decay=0.8)
	builder.add_echo(0.08, 0.22, repeats=2)


def preset_line_smash(builder: SoundBuilder, pitch: float, intensity: float) -> None:
	builder.add_tone(0.0, builder.duration * 0.24, 180.0 * pitch, 260.0 * pitch, amp=0.1 * intensity, wave_type="triangle", attack=0.01, release=0.06, decay=0.6)
	builder.add_noise(builder.duration * 0.16, builder.duration * 0.4, amp=0.14 * intensity, color="shatter", release=0.12, decay=1.0)
	builder.add_tone(builder.duration * 0.18, builder.duration * 0.56, 520.0 * pitch, 70.0 * pitch, amp=0.22 * intensity, wave_type="saw", release=0.18, decay=1.15)
	builder.add_tone(builder.duration * 0.18, builder.duration * 0.34, 100.0 * pitch, 34.0 * pitch, amp=0.16 * intensity, wave_type="sine", release=0.18, decay=1.4)


def preset_barrier_break(builder: SoundBuilder, pitch: float, intensity: float) -> None:
	builder.add_tone(0.0, builder.duration * 0.3, 980.0 * pitch, 1420.0 * pitch, amp=0.07 * intensity, wave_type="sine", attack=0.01, release=0.06, decay=0.55)
	builder.add_noise(builder.duration * 0.12, builder.duration * 0.44, amp=0.16 * intensity, color="shatter", release=0.12, decay=1.05)
	builder.add_tone(builder.duration * 0.14, builder.duration * 0.46, 1460.0 * pitch, 260.0 * pitch, amp=0.15 * intensity, wave_type="triangle", release=0.12, decay=0.95)
	builder.add_echo(0.06, 0.2, repeats=2)


def preset_teleport_slash(builder: SoundBuilder, pitch: float, intensity: float) -> None:
	builder.add_noise(0.0, builder.duration * 0.24, amp=0.06 * intensity, color="hiss", release=0.04, decay=0.75)
	builder.add_tone(0.0, builder.duration * 0.22, 360.0 * pitch, 980.0 * pitch, amp=0.08 * intensity, wave_type="sine", release=0.04, decay=0.55)
	builder.add_tone(builder.duration * 0.18, builder.duration * 0.52, 1040.0 * pitch, 180.0 * pitch, amp=0.18 * intensity, wave_type="saw", release=0.08, decay=0.95)
	builder.add_echo(0.04, 0.15, repeats=1)


def preset_royal_charge(builder: SoundBuilder, pitch: float, intensity: float) -> None:
	builder.add_tone(0.0, builder.duration * 0.34, 160.0 * pitch, 280.0 * pitch, amp=0.11 * intensity, wave_type="triangle", attack=0.02, release=0.08, decay=0.55)
	builder.add_noise(builder.duration * 0.16, builder.duration * 0.34, amp=0.09 * intensity, color="hiss", release=0.08, decay=0.8)
	builder.add_tone(builder.duration * 0.24, builder.duration * 0.54, 420.0 * pitch, 92.0 * pitch, amp=0.2 * intensity, wave_type="saw", release=0.14, decay=1.1)
	builder.add_tone(builder.duration * 0.28, builder.duration * 0.24, 130.0 * pitch, 48.0 * pitch, amp=0.14 * intensity, wave_type="sine", release=0.14, decay=1.25)


def preset_projectile_barrage(builder: SoundBuilder, pitch: float, intensity: float) -> None:
	for index in range(4):
		start = index * builder.duration * 0.17
		builder.add_tone(start, builder.duration * 0.22, (880.0 + 120.0 * index) * pitch, (1320.0 + 90.0 * index) * pitch, amp=0.1 * intensity, wave_type="sine", release=0.05, decay=0.5)
		builder.add_noise(start + 0.015, builder.duration * 0.12, amp=0.04 * intensity, color="hiss", release=0.03, decay=0.7)
	builder.add_echo(0.05, 0.15, repeats=2)


def preset_boss_death(builder: SoundBuilder, pitch: float, intensity: float) -> None:
	builder.add_tone(0.0, builder.duration * 0.9, 180.0 * pitch, 26.0 * pitch, amp=0.18 * intensity, wave_type="square", attack=0.02, release=0.34, decay=1.7)
	builder.add_tone(0.08, builder.duration * 0.74, 96.0 * pitch, 20.0 * pitch, amp=0.16 * intensity, wave_type="sine", release=0.38, decay=2.0)
	builder.add_noise(0.12, builder.duration * 0.42, amp=0.12 * intensity, color="shatter", release=0.24, decay=1.1)
	builder.add_noise(0.24, builder.duration * 0.3, amp=0.09 * intensity, color="thump", release=0.26, decay=1.4)
	builder.add_echo(0.1, 0.22, repeats=2)


PRESET_BUILDERS = {
	"ui_confirm": preset_ui_confirm,
	"melee_light": preset_melee_light,
	"melee_heavy": preset_melee_heavy,
	"charge_heavy": preset_charge_heavy,
	"slam": preset_slam,
	"sanctuary": preset_sanctuary,
	"hurt_heavy": preset_hurt_heavy,
	"hurt_light": preset_hurt_light,
	"death_heavy": preset_death_heavy,
	"death_light": preset_death_light,
	"bow_shot": preset_bow_shot,
	"dash_light": preset_dash_light,
	"assassinate": preset_assassinate,
	"mage_cast": preset_mage_cast,
	"arcane_orbit": preset_arcane_orbit,
	"arcane_burst": preset_arcane_burst,
	"enchant": preset_enchant,
	"mage_hurt": preset_mage_hurt,
	"mage_death": preset_mage_death,
	"shield_bash": preset_shield_bash,
	"apprentice_cast": preset_apprentice_cast,
	"arcanist_cast": preset_arcanist_cast,
	"line_smash": preset_line_smash,
	"barrier_break": preset_barrier_break,
	"teleport_slash": preset_teleport_slash,
	"royal_charge": preset_royal_charge,
	"projectile_barrage": preset_projectile_barrage,
	"boss_death": preset_boss_death,
}


def render_event(event_id: str, config: dict[str, float | str], output_dir: Path, force: bool) -> bool:
	output_path = output_dir / f"{event_id}.wav"
	if output_path.exists() and not force:
		return False
	builder = SoundBuilder(float(config["duration"]), stable_seed(event_id))
	preset_name = str(config["preset"])
	PRESET_BUILDERS[preset_name](builder, float(config["pitch"]), float(config["intensity"]))
	output_path.parent.mkdir(parents=True, exist_ok=True)
	with wave.open(str(output_path), "wb") as wav_file:
		wav_file.setnchannels(1)
		wav_file.setsampwidth(2)
		wav_file.setframerate(SAMPLE_RATE)
		wav_file.writeframes(builder.finalize())
	return True


def clean_unused(output_dir: Path) -> int:
	removed = 0
	valid_names = {f"{event_id}.wav" for event_id in EVENTS.keys()}
	for file_path in output_dir.glob("*.wav"):
		if file_path.name in valid_names:
			continue
		file_path.unlink()
		removed += 1
	return removed


def main() -> int:
	parser = argparse.ArgumentParser(description="Generate prototype placeholder SFX for Infinity Kingdom.")
	parser.add_argument("--force", action="store_true", help="Overwrite existing wav files.")
	parser.add_argument("--clean", action="store_true", help="Remove generated wav files that are not in the current event list.")
	args = parser.parse_args()

	root_dir = Path(__file__).resolve().parents[2]
	output_dir = root_dir / "audio" / "generated"
	output_dir.mkdir(parents=True, exist_ok=True)

	written = 0
	for event_id, config in EVENTS.items():
		if render_event(event_id, config, output_dir, args.force):
			written += 1

	removed = clean_unused(output_dir) if args.clean else 0
	print(f"Generated {written} placeholder SFX files in {output_dir}")
	if removed > 0:
		print(f"Removed {removed} stale wav files")
	return 0


if __name__ == "__main__":
	raise SystemExit(main())
