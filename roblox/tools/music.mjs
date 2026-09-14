import { mkdirSync, writeFileSync } from "node:fs";

const rate = 22050;
const tracks = [
  { name: "Explore", bpm: 92, notes: [60, 64, 67, 69, 67, 64, 62, 59], bass: [36, 41, 43, 36], bright: 0.35 },
  { name: "Combat", bpm: 126, notes: [60, 63, 67, 70, 67, 63, 65, 62], bass: [36, 39, 41, 43], bright: 0.65 },
  { name: "Danger", bpm: 146, notes: [60, 61, 67, 66, 63, 61, 58, 59], bass: [36, 37, 34, 35], bright: 0.85 },
];
mkdirSync("assets", { recursive: true });
for (const track of tracks) {
  const beat = 60 / track.bpm;
  const samples = new Float64Array(Math.round(rate * beat * 32));
  function tone(start, duration, midi, volume, percussion = false) {
    const frequency = 440 * 2 ** ((midi - 69) / 12);
    const length = Math.round(duration * rate);
    for (let i = 0; i < length; i++) {
      const t = i / rate;
      const phase = Math.PI * 2 * frequency * t;
      const decay = Math.exp(-t / (percussion ? 0.07 : 0.24));
      const envelope = Math.min(1, t / 0.009) * decay * Math.min(1, (duration - t) / 0.03);
      const sound = Math.sin(phase) + track.bright * Math.sin(phase * 2.002) / 3 + Math.sin(phase * 3) / 8;
      const index = Math.round(start * rate) + i;
      if (index < samples.length) samples[index] += sound * envelope * volume;
    }
  }
  for (let step = 0; step < 64; step++) {
    const at = step * beat / 2;
    const midi = track.notes[step % track.notes.length] + (step % 16 >= 8 ? 12 : 0);
    tone(at, beat * 0.8, midi, 0.22);
    if (step % 2 === 0) tone(at, beat * 0.7, track.bass[Math.floor(step / 16)], 0.2);
    if (step % 4 === 2) tone(at, 0.16, 42, 0.13, true);
    if (track.name !== "Explore" || step % 4 === 0) tone(at, 0.08, 91, 0.04, true);
  }
  const output = Buffer.alloc(44 + samples.length * 2);
  output.write("RIFF"); output.writeUInt32LE(output.length - 8, 4);
  output.write("WAVEfmt ", 8); output.writeUInt32LE(16, 16);
  output.writeUInt16LE(1, 20); output.writeUInt16LE(1, 22);
  output.writeUInt32LE(rate, 24); output.writeUInt32LE(rate * 2, 28);
  output.writeUInt16LE(2, 32); output.writeUInt16LE(16, 34);
  output.write("data", 36); output.writeUInt32LE(samples.length * 2, 40);
  for (let i = 0; i < samples.length; i++) {
    const endFade = Math.min(1, (samples.length - i) / (rate * 0.04));
    output.writeInt16LE(Math.round(Math.tanh(samples[i]) * 28000 * endFade), 44 + i * 2);
  }
  writeFileSync(`assets/${track.name}.wav`, output);
  console.log(`${track.name}: ${(samples.length / rate).toFixed(1)} seconds, original synthesized score`);
}
