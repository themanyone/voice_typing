# Voice Typing with Openai-Whisper

State-of-the-art voice typing to the Linux desktop (or WFL sesson on Windows.) with a simple bash script.

- Privacy-focused. Uses [Whisper AI](https://github.com/openai/whisper) for offline speech recognition,
- Hands-free using `sox` for rudimentary voice activity detection (VAD).
- Leverages `ydotool` to type text into the current window.
  - Changed to `ydotool` to work with Wayland and X11
- Low memory requirements. Resources are freed-up between each spoken interaction.

## Notes

Whisper has to load up each time speech is detected, which means a noticeable wait before text appears.

For faster, continuous dictation, try the [whisper_dictation](https://github.com/themanyone/whisper_dictation.git) project, which uses whisper-jax and threads to dramatically speed up dictation, while also enabling other features, such as AI Chat and enhanced voice controls. The disadvantage of that approach is it hogs GPU resources until the app closes. And there are gigabytes of dependencies to install.

## Requirements
- [Whisper AI](https://github.com/openai/whisper)
- [ffmpeg](https://ffmpeg.org/)
- [sox](https://sox.sourceforge.net/)
- [lame](https://lame.sourceforge.io/)
- <del>[xdotool](https://github.com/jordansissel/xdotool)</del>
  - [ydotool](https://github.com/ReimuNotMoe/ydotool)
- [screen](https://linuxize.com/post/how-to-use-linux-screen/) (optional)

## Setup

This assumes [Whisper AI](https://github.com/openai/whisper) and other dependencies are installed and working. Most are available through the official software update app for each platform. Please examine `voice_typing` bash script and feel free to customize it. It's only 50 lines. Do not run untrusted code.

For Debian systems:
```
apt install sox lame ydotool openai-whisper libsox-fmt-mp3
git clone git@github.com:tallmtt/voice_typing.git
sudo chmod +s $(which ydotool)
cd voice_typing
./voice_typing
```
Notes:
- Adjust mic volume for best result.
- First run might be slow as it needs to download the model (better yet, use whisper from cli first to download the model (tiny))

Recommended:
- Add a Keybinding for mic mute/unmute - Text is generated and fills in after muted (might be the needed because of my poor mic quality)

Report issues in the [GitHub issue tracker](https://github.com/tallmtt/voice_typing/issues). (This is a fork from themanyone)[https://github.com/themanyone/voice_typing]

Thanks for trying voice_typing!
- Forked from: GitHub https://github.com/themanyone
