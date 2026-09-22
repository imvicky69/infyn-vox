# infyn Vox v1.0.0 — Release Notes

> **The Professional 48kHz Multilingual Desktop Speech Synthesis & Audio Workstation**

Welcome to the initial official release of **infyn Vox (v1.0.0)**! 

infyn Vox is a desktop audio workstation engineered for high-fidelity speech synthesis, voice persona design, and long-form narrative production with 48kHz studio audio output.

---

## 🌟 What's New in v1.0.0

### 🎙️ 1. Studio Speech Synthesis (48kHz Neural Fidelity)
- **30+ Supported Languages**: Multilingual generation across English, Hindi, Mandarin Chinese, Japanese, Korean, French, German, Spanish, Arabic, and more with auto-script detection.
- **Acoustic Timbre & Persona Differentiation**:
  - **Swara & Elena**: Soft, warm female storytelling voices.
  - **Aria & Xiao Ya**: Modern, crisp assistants with delicate melodic cadence.
  - **David & Kabir**: Authoritative, deep documentary baritones.
  - **Leo & Kenji**: High-energy tech podcasts and expressive character acting.
- **Full Hyperparameter Control**: Adjust CFG Guidance Scale, DiT Flow Steps, Random Seed, WeText Normalization, and ZipEnhancer noise removal.

### 📜 2. Smart Long-Form Audio Segmenter
- Break down articles, books, podcast scripts, and video narration into semantic sentences without prosodic degradation.
- Batch synthesizes all segments and seamlessly stitches them into a master audio track with natural breathing intervals.
- Generates synchronized **SRT subtitle files** automatically for video creators.
- Voice template selection directly inside the segmenter.

### 🗄️ 3. Saved Audio Library & Batch "Export All"
- Persistent recording library that stores all synthesized speech clips and stitched masters.
- Search clips by title, persona, or date.
- Real-time dock synchronization with scrubber waveform playback.
- **Export All**: One-click batch exporter that exports all audio files to your chosen folder and generates a structured `manifest.json`.

### 🎨 4. Swiss Monochrome Interface & Theme Switching
- Minimalist Zinc 950 (`#09090B`) / Slate White (`#F8FAFC`) aesthetic with `#3B82F6` Electric Blue accents.
- Dynamic **Light / Dark theme toggle** in the custom Windows Title Bar.
- Official bundled **Geist** typography for ultra-clean readability.
- Non-destructive navigation: scripts, sliders, and audio state are preserved when switching tabs.

### 🔄 5. Integrated GitHub Auto-Updater
- Automatically checks `imvicky69/infyn-vox` for new releases on launch.
- Non-intrusive notification when a new version is available with changelog preview and direct download link.
- Supports forced updates for breaking model upgrades.

---

## 🚀 Installation & Running

### Option A: Direct Installer Executable (Recommended)
1. Download **`infyn-vox-v1.0.0-setup.exe`** from the Assets below.
2. Double click the installer executable and follow the quick setup wizard.
3. Automatically creates **Desktop** and **Start Menu** shortcuts.
4. Launch **infyn Vox** directly from your Desktop or Start Menu!

### Option B: Portable Archive (No Installation Required)
1. Download **`infyn-vox-v1.0.0-windows-x64.zip`** from the Assets below.
2. Extract the archive to any folder on your computer.
3. Double click **`infyn_vox.exe`** to launch the workstation immediately!

### Backend Synthesis Engine Setup
Ensure the local Python speech synthesis backend is running:
```bash
cd backend
pip install -r requirements.txt
python server.py --host 127.0.0.1 --port 8808
```

---

## 📦 Release Assets

| Asset Name | Type | Size | Description |
| :--- | :--- | :--- | :--- |
| **`infyn-vox-v1.0.0-setup.exe`** | Direct Installer | ~12.7 MB | Standalone Windows installer wizard with Desktop/Start Menu shortcuts |
| **`infyn-vox-v1.0.0-windows-x64.zip`** | Portable Archive | ~14.2 MB | Portable pre-packaged zip archive (extract and run) |

