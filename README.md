# Voice Typing with Openai-Whisper

State-of-the-art, offline voice typing in Linux tty (or WFL sesson on Windows.) with a tiny bash script.

**No grapical OS required.** Yet it *does* work with GUI X, wayland, whatever. Speak text everywhere, like a boss.

- Privacy-focused. Uses [Whisper AI](https://github.com/openai/whisper) or [Whisper.cpp](https://github.com/ggerganov/whisper.cpp) for offline speech recognition,
- Hands-free using `sox` for rudimentary voice activity detection (VAD).
- Leverages `ydotool` to type text into any active window (but does not require a graphical OS).
- Low memory requirements. Resources may be freed between each spoken interaction.

## Caveats

When `voice_typing` detects speech, it trims unwanted background noise, and then loads Whisper, which causes a noticeable wait before text appears. It is good for occasional use. And it is the most economical on resources.

For heavier usage, instead of loading and unloading Whisper multiple times, we have added `voice_client`. It connects to your [Whisper.cpp](https://github.com/ggerganov/whisper.cpp) server. The server may run continuously on the same machine, or a dedicated GPU server somewhere across the network. Try it. Users might discover significant speedup. :)

For even-faster, continuous, networked dictation with more features, try the [whisper_dictation](https://github.com/themanyone/whisper_dictation.git) AI assistant project. Features include a conversational chatbot, AI image generation, and voice-controlled program launchers leveraging the full power of Python.

**End feature creep.** This project is just a starting point, and will remain so. [There is no end to what you might do from here](https://github.com/ReimuNotMoe/ydotool). If you have time, take [record.py](https://github.com/themanyone/whisper_dictation/blob/main/record.py) from [whisper_dictation](https://github.com/themanyone/whisper_dictation.git). Just (click to download the file) and adapt this script to use that instead of `sox`. It runs a delay loop "time machine" that rewinds to catch the beginning of speech. So you don't have to clear your throat or say, "hey Linus" before talking. Gstreamer-1.0 is required to run it though. And some people prefer minimal [emebeded systems on a chip](https://www.reddit.com/r/embedded/comments/16xakmp/how_to_design_a_simple_pcb_running_linux/).

## Requirements
- [Whisper AI](https://github.com/openai/whisper) or [Whisper.cpp](https://github.com/ggerganov/whisper.cpp)
- [ffmpeg](https://ffmpeg.org/)
- [sox](https://sox.sourceforge.net/)
- [lame](https://lame.sourceforge.io/)
- <del>[xdotool](https://github.com/jordansissel/xdotool)</del>
  - [ydotool](https://github.com/ReimuNotMoe/ydotool)
- [tmux](https://github.com/tmux/tmux/wiki) or [screen](https://linuxize.com/post/how-to-use-linux-screen/) (optional)
- [curl](https://curl.se/) (for clients)

## Install Dependencies

This assumes [Whisper AI](https://github.com/openai/whisper) or [Whisper.cpp](https://github.com/ggerganov/whisper.cpp) and dependencies are installed and working. Most are available through the official software update app for each platform. Please examine `voice_typing` and `voice_client` scripts and see how easy they are to customize for any occasion. They are around 50 lines is all. Do not run untrusted code.

Fedora/Centos:
```
dnf -y install sox curl lame ydotool
sudo cp /usr/lib/systemd/system/ydotool.service /etc/systemd/system/
sudo chmod +x /etc/systemd/system/ydotool.service
sudo systemctl daemon-reload
sudo systemctl enable ydotool
sudo systemctl start ydotool
sudo chmod +s $(which ydotool)
```

You might need Rpmfusion-freeworld installed to get versions of `lame` and `sox` that write mp3 files. `sudo dnf install \ https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm`

The `ydotool` package has instructions in `/usr/share/doc/ydotool/README.md` where they say the man page may not be up to date.

Debian-based systems:
```
sudo apt install sox curl lame ydotool openai-whisper libsox-fmt-mp3 scdoc
```

If ydotool is not available, or you need a later version, snwfdhmp commented:

```
git clone https://github.com/ReimuNotMoe/ydotool
cd ydotool
mkdir build
cd build
cmake -DSYSTEMD_SYSTEM_SERVICE=ON -DSYSTEMD_USER_SERVICE=OFF ..
make -j `nproc`
sudo ln -s $(pwd)/ydotool /usr/local/bin/ydotool
sudo ln -s $(pwd)/ydotoold /usr/local/bin/ydotoold
sudo cp ./ydotoold.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable ydotoold.service # later changed to ydotool.service
sudo systemctl start ydotoold.service
```
For quick troubleshooting
```
sudo systemctl status ydotoold  # Should show "Active: active (running)"
journalctl -u ydotoold -b | tail -n 20
```

## Setup

Edit `.bashrc` and add the line, `export YDOTOOL_SOCKET=/tmp/.ydotool_socket`

```
git clone https://github.com/themanyone/voice_typing.git
sudo systemctl enable ydotool.service
sudo systemctl start ydotool.service
ydotool type hello!
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

- Adjust mic volume for best results. If recording never stops, mic volume is up too high. If you can't adjust volume for some reason, edit `voice_typing` or `voice_client`. And change silence-detection threshold from 4% and 2% to something higher.
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
