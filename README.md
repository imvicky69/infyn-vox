# infyn Vox

Professional 48kHz Multilingual Speech Synthesis & Desktop Audio Workstation.

Built with Flutter Desktop (Windows) and high-performance neural TTS backend engines.

---

## Key Highlights

- **48kHz Pristine Speech Synthesis**: Ultra-clear, natural acoustic delivery across 30+ global languages with true-to-life prosody and nuance.
- **Voice Vault & Persona Design**: Curated presets and custom voice design workflows with instant zero-shot timbres.
- **Smart Long-Form Segmenter**: Breaks down large scripts and articles into semantic segments with automated pause insertion, chunk stitching, and aligned SRT subtitle exports.
- **Saved Audio Library**: Persistent recording library with search, inline playback synced with the studio dock, individual format exports, and one-click **Export All** with structured JSON manifests.
- **Modern Monochrome Interface**: Swiss-inspired minimal monochrome design with `#3B82F6` Electric Blue accents, dynamic Light/Dark theme switching, and official Geist typography.

---

## Quick Start

### 1. Start the Backend Server

```bash
cd backend
pip install -r requirements.txt
python server.py --host 127.0.0.1 --port 8808
```

### 2. Launch the Desktop App

```bash
flutter pub get
flutter run -d windows
```

---

## Architecture

- **Frontend**: Flutter Desktop Windows, Geist typography, custom title bar, scrubbable waveform visualizer, and non-destructive tab state preservation.
- **Backend**: Python 3.12 FastAPI server, async neural Edge-TTS provider with custom prosody modulation and acoustic timbre styling.
