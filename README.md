# voice_typing
Continuous, hands-free speech recognition everywhere on Linux desktop with Whisper AI

voice_typing waits until you start speaking. After two seconds of silence, it starts whisper AI in the background and types text into the current window. The results is continuous speech recognition when you need it, where you need it. Just leave it running minimized in a terminal or `screen` session.

# Requirements
    # whisper AI https://github.com/openai/whisper
    # sox
    # lame
    # xdotool
    # screen (optional)

## Setup

```
# assumes you have Whisper AI installed
dnf -y install sox lame xdotool
git clone https://github.com/themanyone/voice_typing.git
cd voice_typing
./voice_typing
```
