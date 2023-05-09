# voice_typing

Continuous, offline, hands-free speech recognition everywhere in Linux terminals and desktop with [Whisper AI](https://github.com/openai/whisper) and `xdotool`.

`voice_typing` waits until you start speaking and records audio in the background. After two seconds of silence--it keeps listening, waiting for you to speak again. Whisper AI runs in the foreground, using `xdotool` to type out the resulting text into whatever window is open at the time. The results is continuous speech recognition when you need it, where you need it. Just leave it running in a terminal or `screen` session.

## Advantages and Disadvantages

One advantage of this script is that resources are freed-up between each spoken interaction. You can play videos and do other things between talking. A disadvantage is whisper has to load up each time, which means a noticeable wait before text appears. 

For faster continuous dictation, try my [whisper_dictation](https://github.com/themanyone/whisper_dictation.git) project, which uses whisper-jax and threads to keep a compiled function loaded in memory. The disadvantage of that approach is it hogs GPU resources until you completely close the app. And there are gigabytes of dependencies to install.

These experimental scripts are intended for working offline, on systems that have a powerful video card. For smaller, connected devices, you might want to look at whisper cloud solutions.

## Requirements
    # whisper AI https://github.com/openai/whisper
    # ffmpeg
    # sox
    # lame
    # xdotool
    # screen (optional)

## Setup

We assume you have [Whisper AI](https://github.com/openai/whisper) installed and working.

```
dnf -y install sox lame xdotool
git clone https://github.com/themanyone/voice_typing.git
cd voice_typing
./voice_typing
```

Browse Themanyone
- GitHub https://github.com/themanyone
- YouTube https://www.youtube.com/themanyone
- Mastodon https://mastodon.social/@themanyone
- Linkedin https://www.linkedin.com/in/henry-kroll-iii-93860426/
- [TheNerdShow.com](http://thenerdshow.com/)
