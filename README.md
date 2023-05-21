# voice_typing

State-of-the-art voice typing to the Linux desktop (or WFL sesson on Windows.) with a simple bash script.

- Privacy-focused. Uses [Whisper AI](https://github.com/openai/whisper) for offline speech recognition,
- Hands-free using `sox` for rudimentary voice activity detection (VAD).
- Leverages `xdotool` to type text into the current window.
- Low memory requirements. Resources are freed-up between each spoken interaction.

## Disadvantages

Whisper has to load up each time speech is detected, which means a noticeable wait before text appears. 

For faster, continuous dictation, try my [whisper_dictation](https://github.com/themanyone/whisper_dictation.git) project, which uses whisper-jax and threads to dramatically speed up dictation, while also enabling other features, such as AI Chat and enhanced voice controls. The disadvantage of that approach is it hogs GPU resources until you completely close the app. And there are gigabytes of dependencies to install.

These experimental scripts bring AI to average users with entry-level video cards.

## Requirements
- whisper AI https://github.com/openai/whisper
- ffmpeg
- sox
- lame
- xdotool
- screen (optional)

## Setup

We assume you have [Whisper AI](https://github.com/openai/whisper) installed and working.

```
dnf -y install sox lame xdotool
git clone https://github.com/themanyone/voice_typing.git
cd voice_typing
./voice_typing
```

Adjust mic volume for best result.

Report issues in the [GitHub issue tracker](https://github.com/themanyone/voice_typing/issues). Or fork the project and submit a pull request.

Thanks for trying voice_typing!

Browse Themanyone
- GitHub https://github.com/themanyone
- YouTube https://www.youtube.com/themanyone
- Mastodon https://mastodon.social/@themanyone
- Linkedin https://www.linkedin.com/in/henry-kroll-iii-93860426/
- [TheNerdShow.com](http://thenerdshow.com/)
