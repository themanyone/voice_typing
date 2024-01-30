# Voice Typing with Openai-Whisper

State-of-the-art voice typing in Linux terminal (or WFL sesson on Windows.) with a simple bash script.
Works with all window managers. **No window manager required.**

- Privacy-focused. Uses [Whisper AI](https://github.com/openai/whisper) or [Whisper.cpp](https://github.com/ggerganov/whisper.cpp) for offline speech recognition,
- Hands-free using `sox` for rudimentary voice activity detection (VAD).
- Leverages `ydotool` to type text into any active window (but does not require a graphical OS).
- Low memory requirements. Resources may be freed between each spoken interaction.

## Caveats

When `voice_typing` detects speech, it trims unwanted background noise, and then loads Whisper, which causes a noticeable wait before text appears. It is good for occasional use. And it is the most economical on resources.

For heavier usage, instead of loading and unloading Whisper multiple times, we have added `voice_client`. It connects to a CUDA-accelerated [Whisper.cpp](https://github.com/ggerganov/whisper.cpp) server. The server runs continuously on the same machine, or somewhere across the network. Try it. Users might discover significant speedup. :)

For even-faster, continuous, networked dictation with more features, try the [whisper_dictation](https://github.com/themanyone/whisper_dictation.git) AI assistant project. Features include AI Chat, AI image generation, and voice-controlled program launchers leveraging the full power of Python.

## Requirements
- [Whisper AI](https://github.com/openai/whisper) or [Whisper.cpp](https://github.com/ggerganov/whisper.cpp)
- [ffmpeg](https://ffmpeg.org/)
- [sox](https://sox.sourceforge.net/)
- [lame](https://lame.sourceforge.io/)
- <del>[xdotool](https://github.com/jordansissel/xdotool)</del>
  - [ydotool](https://github.com/ReimuNotMoe/ydotool)
- [screen](https://linuxize.com/post/how-to-use-linux-screen/) (optional)
- [curl](https://curl.se/) (for clients)

## Install Dependencies

This assumes [Whisper AI](https://github.com/openai/whisper) or [Whisper.cpp](https://github.com/ggerganov/whisper.cpp) and dependencies are installed and working. Most are available through the official software update app for each platform. Please examine `voice_typing` and `voice_client` scripts and see how easy they are to customize for any occasion. They are around 50 lines is all. Do not run untrusted code.

Fedora/Centos:
```
dnf -y install sox curl lame ydotool
```
You might need Rpmfusion-freeworld installed to get versions of `lame` and `sox` that write mp3 files. `sudo dnf install \ https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm`

Debian-based systems:
```
sudo apt install sox curl lame ydotool openai-whisper libsox-fmt-mp3
```

## Setup

Edit `.bashrc` and add the line, `export YDOTOOL_SOCKET=/tmp/.ydotool_socket`

```
git clone https://github.com/themanyone/voice_typing.git
sudo systemctl enable ydotool.service
sudo systemctl start ydotool.service
cd voice_typing
./voice_typing
```

Speak and text appears. No other interaction is required.

## Optional Whisper.cpp client/server setup.

Compile [Whisper.cpp](https://github.com/ggerganov/whisper.cpp) with some type of acceleration for best results. We are using cuBLAS for about 4x speedup. If it complains about unsupported compiler, the best option is to use conda or docker to install an earlier version of `gcc`, currently `gcc-12`.

To minimize GPU footprint, launch `server` with `ggml-tiny.en.bin`. It uses just over 111 MiB VRAM on our budget laptop. (48MiB with `ggml-tiny.en-q4_0.bin` quantized to 4Bits.) We launch under a simlink to, `whisper_cpp_server` to make it less confusing when `server` shows up in the process list.

```shell
ln -s $(pwd)/server whisper_cpp_server
./whisper_cpp_server -l en -m models/ggml-tiny.en.bin --port 7777 --convert
```

There could be [issues](https://github.com/ggerganov/whisper.cpp/issues/1587), if compiled with `-allow-unsupported-compiler`. The `-ng` flag will make it work. Although `-ng` is not ideal, matrix multiplcations will still use cuBLAS for CPU, so about 2x speedup similar to openBLAS.

Edit `voice_client` to change the server location from localhost to wherever it resides on the network.

Run it.
```shell
./voice_client
```

## Notes

- Adjust mic volume for best result. If recording never stops, edit `voice_typing` or `voice_client`. And change silence-detection threshold from 4% and 2% to something higher.
```rec -c 1 -r 22050 -t mp3 "$tmp" silence 1 0.2 6% 1 1.0 5%```

- Optionally create a Keybinding for mic mute/unmute. If there is continuous noise in the background, it goes into a recording loop and never gets around to typing text.

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
