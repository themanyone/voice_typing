# Voice Typing with Openai-Whisper

State-of-the-art voice typing to the Linux desktop (or WFL sesson on Windows.) with a simple bash script.

- Privacy-focused. Uses [Whisper AI](https://github.com/openai/whisper) for offline speech recognition,
- Hands-free using `sox` for rudimentary voice activity detection (VAD).
- Leverages `ydotool` to type text at the command line. (Changed to `ydotool` to remove X dependency)
- Low memory requirements. Resources are freed-up between each spoken interaction.

## Caveats

To keep system resource usage to a bare minimum, `voice_typing` loads whisper only when speech is detected. And audio is processed to trim unwanted background noise, which means a noticeable wait before text appears. 

To work around this, we have added `voice_client`, which connects to any [Whisper.cpp](https://github.com/ggerganov/whisper.cpp) server running on the same machine, or across the network. Since clients don't need to have whisper running, users might discover that it is significantly faster. :). Edit `voice_client` with the server's location (localhost).

For even faster, continuous dictation across the network, with more features, try the [whisper_dictation](https://github.com/themanyone/whisper_dictation.git) AI assistant project. Features include AI Chat, AI image generation, and voice-controlled program launchers using the power of Python.

## Requirements
- [Whisper AI](https://github.com/openai/whisper)
- [ffmpeg](https://ffmpeg.org/)
- [sox](https://sox.sourceforge.net/)
- [lame](https://lame.sourceforge.io/)
- <del>[xdotool](https://github.com/jordansissel/xdotool)</del>
  - [ydotool](https://github.com/ReimuNotMoe/ydotool)
- [screen](https://linuxize.com/post/how-to-use-linux-screen/) (optional)

## Install Dependencies

This assumes [Whisper AI](https://github.com/openai/whisper) or [Whisper.cpp](https://github.com/ggerganov/whisper.cpp) and dependencies are installed and working. Most are available through the official software update app for each platform. Please examine `voice_typing` and `voice_client` scripts and see how easy they are to customize for any occasion. They are around 50 lines is all. Do not run untrusted code.

Fedora/Centos:
```
dnf -y install sox lame ydotool
```
You might need Rpmfusion-freeworld installed to get versions of `lame` and `sox` that write mp3 files. `sudo dnf install \ https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm`

Debian-based systems:
```
sudo apt install sox lame ydotool openai-whisper libsox-fmt-mp3
```

## Setup

```
git clone https://github.com/themanyone/voice_typing.git
sudo systemctl enable ydotool.service
sudo systemctl start ydotool.service
cd voice_typing
./voice_typing
```

Edit `.bashrc` and add the line, `export YDOTOOL_SOCKET=/tmp/.ydotool_socket`

## Notes

- Adjust mic volume for best result. If recording never stops, edit `voice_typing` and change silence / pause threshold from 4% and 2% to something higher.
```rec -c 1 -r 22050 -t mp3 "$tmp" silence 1 0.2 6% 1 1.0 5%```

- Add a Keybinding for mic mute/unmute. If there is continuous noise in the background, it goes into a recording loop and never gets around to typing text.

- First run of `voice_typing` might be slow as it needs to download the model (better yet, use whisper or whisper.cpp from cli first to download the model (tiny))

## Troubleshooting
"failed to connect socket `/tmp/.ydotool_socket': Permission denied" Error

When encountering the error "failed to connect socket `/tmp/.ydotool_socket': Permission denied," it's essential to ensure that the current user has sufficient permissions to access the socket file. Here are some steps to troubleshoot this issue:

Check User Permissions and Service Status.
    Ensure that the user has been added to the "input" group and has the necessary permissions to access the socket file.
    Verify the status of the ydotool service to ensure it is running as expected.

Setuid Bit on the Executable.
    Consider setting the setuid bit on the ydotool executable using the command:

    sudo chmod +s $(which ydotool)

This step can help address permission issues when running ydotool as a user.

Address Already in Use.
    If encountering the error "failed to bind socket: Address already in use," it may be necessary to delete the socket file from /tmp to resolve the issue.

Linking to the Expected Socket.
    If ydotool started as a user looks for the socket "/run/user/1000/.ydotool_socket" but the daemon as a systemwide service listens to /tmp/.ydotool_socket, consider creating a link to the expected socket to ensure proper functionality.

Report others issues in the [GitHub issue tracker](https://github.com/themanyone/voice_typing).

Thanks for trying voice_typing!

## Similar Projects

- [Whisper Typer Tool](https://github.com/dynamiccreator/whisper-typer-tool)
- [Whisper Dictation](https://github.com/themanyone/whisper_dictation.git)
