# Voice Typing with Openai-Whisper

State-of-the-art, private, offline voice typing/real-time voice translation in Linux tty (or WFL sesson on Windows.) with a tiny bash script. No subscription necessary.

**No grapical OS required.** Yet the voice keyboard *does* work with GUI X, wayland, whatever. Speak text everywhere, like a boss.

- Privacy-focused. Uses [Whisper AI](https://github.com/openai/whisper) or [Whisper.cpp](https://github.com/ggerganov/whisper.cpp) for offline speech recognition.
- Organic software (free, off-grid, open-source, unrestrictive licenses).
- Promotes peace through expediting communications and understanding.
- Hands-free utilizing `sox` for rudimentary sound-level detection.
- Voice keyboard leverages `ydotool` to type text into any active window.
- Low memory requirements. Resources may be freed between each spoken interaction.

We invite you to examine `voice_typing` and `voice_client` scripts and see how easy they are to customize for any occasion. They are around 50-75 lines is all. Do not run untrusted code.

## Whisper flow

There is a popular app with a name similar to Whisper flow. It applies edits using an LLM. So instead of typing out what you say, verbatim, it types more or less what you intended to say. We have included a program, called `llama_edit` to mimic that functionality. It is disabled by default. So if you don't need it, skip this section.

This alpha version of `llama_edit` should work okay with some small, fast models. It is currently set up to use [prism-ml/Bonsai-1.7B](https://huggingface.co/prism-ml/Bonsai-1.7B-gguf) locally, with [llama.cpp](https://github.com/ggml-org/llama.cpp) so try those out first.

Edit `llama_edit` with the server location and preferred language model. Test it like this:

```shell
./llama_edit Please, uh, tell Joe, I mean Josh to bring back the cones from the job site.
Please tell Josh to bring back the cones from the job site.
```

Once you are satisfied that it works, install `llama_edit` somewhere in your path.

`cp llama_edit ~/.local/bin`

Then, in whatever client you choose, comment out the existing call to `ydotool`. And uncomment the line to filter the result text thru `llama_edit`, like this.

```shell
# ydotool type "$extracted_text"
ydotool type $(llama_edit "$extracted_text")
```

## Choosing a Client

**Windowws 11.** Unlike Windows® 11's voice keyboard (voice typing), which sends voice data to Microsoft™ for processing, this project keeps it all under your roof. Let's make that __very clear!__. This is a completely-independent project. If you still want to use Windows's voice keyboard, press Windows-H to set that up, and be off on your Windows journey. We will see you next time!

[voice_typing](voice_typing) loads Whisper for each spoken paragraph, which causes a noticeable wait before text appears. It is intended for occasional use. And it is the most economical on resources.

[voice_client_local](voice_client_local) connects to a [Whisper.cpp](https://github.com/ggerganov/whisper.cpp) server that runs, in the background, on the same machine. The server is configured to start and stop with the app. These client/server setups reduce delays but use a little more resources.

[voice_client](voice_client) is intended to connect to a sever that runs continuously somewhere else on the network. It lacks extra code to start and stop the server.

[whisper_dictation](https://github.com/themanyone/whisper_dictation.git) is a separate, AI assistant project with a conversational chatbot, AI image generation, and voice-controlled program launchers leveraging the full power of Python.

**End feature creep.** This project is just a starting point, and will remain so. [There is no end to what you might do from here](https://github.com/ReimuNotMoe/ydotool).

## Requirements
- [Whisper AI](https://github.com/openai/whisper) or [Whisper.cpp](https://github.com/ggerganov/whisper.cpp) decodes speech
- [ffmpeg](https://ffmpeg.org/) used by whisper/whisper.cpp
- [sox](https://sox.sourceforge.net/) for recording audio
- [lame](https://lame.sourceforge.io/) used by sox to write mp3 files
- [ydotool](https://github.com/ReimuNotMoe/ydotool) virtual keyboard
- [jq](https://jqlang.org/) for decoding JSON
- [curl](https://curl.se/) for client requests

## Install Dependencies

**Whisper** You will need [Whisper AI](https://github.com/openai/whisper) or [Whisper.cpp](https://github.com/ggerganov/whisper.cpp) and dependencies installed and working. Most of the dependencies are available through the official software update app for each platform.

**Ydotool.** There is a tutorial for [building and installing ydotool](https://gabrielstaples.com/ydotool-tutorial). What follows is a brief summary for some systems that already have packages for it.

Fedora/Centos:
```
dnf -y install sox curl lame ydotool jq
sudo cp /usr/lib/systemd/system/ydotool.service /etc/systemd/system/
sudo chmod +x /etc/systemd/system/ydotool.service
sudo systemctl daemon-reload
sudo systemctl enable ydotool
sudo systemctl start ydotool
sudo chmod +s $(which ydotool)
```

The `ydotool` package has instructions in `/usr/share/doc/ydotool/README.md` where they say the man page may not be up to date. 

Debian-based systems:
```
sudo apt install sox curl lame ydotool openai-whisper libsox-fmt-mp3 jq
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

Install voice_typing, make sure `ydotool` works, and it's good to go.

```shell
git clone https://github.com/themanyone/voice_typing.git
sudo systemctl enable ydotool.service
sudo systemctl start ydotool.service
ydotool type hello! # test
cd voice_typing
./voice_typing
```

Speak and text appears. No other interaction is required.

## Launch client in tray

If there is a server available, edit `voice_client` to change the server location from `localhost` to wherever it resides on the network.

Launch a voice client in text terminal. Or if there is a window manager available, install `Guake` to launch in tray with a hotkey: `guake -e voice_client_local`

## Server setup

The `whisper-cpp` executable is available in the repos. But power users may prefer to compile [Whisper.cpp](https://github.com/ggerganov/whisper.cpp) with GPU optimizations for best results. We compiled using `cmake -B build -DGGML_CUDA=1 -DWHISPER_SDL2=ON -DWHISPER_FFMPEG=yes` for about 4x speedup. If it complains about unsupported compiler, the best option is to search for rpms for a CUDA-compatible version of `gcc`, such as `g++-14`.

To minimize resources, launch `server` with `ggml-tiny.en.bin`. It uses just over 111 MiB VRAM on our budget laptop. (48MiB with `ggml-tiny.en-q4_0.bin` quantized to 4Bits, which is also usable with no graphics card).

```shell
./whisper-server -l en -m models/ggml-tiny.en.bin --port 7777 --convert
```

This works, for testing. But for even better results, try [install some Voice Activity Detection](https://github.com/ggml-org/whisper.cpp?tab=readme-ov-file#voice-activity-detection-vad) (VAD) and start `whisper-server` that way, e.g.

```shell
whisper-server -l en -vm models/ggml-silero-v6.2.0.bin --vad -m models/ggml-base.en-q5_1.bin --convert --port 7777
```

## Industrial client/server on same machine

For the professional at home, at work, and on the go, we have `voice_client_local` pre-configured for noisy environments, with a couple added lines to start and stop the server with the app:

```shell
systemctl --user start whisper.service

cleanup () {
    systemctl --user stop whisper.service
```

To avoid using `sudo`, configure whisper server to run as a user service:

```shell
cat <<EOF>$HOME/.config/systemd/user/whisper.service
Description=Run Whisper server
Documentation=https://github.com/openai/whisper

[Service]
ExecStart=$HOME/.local/bin/whisper-server \
-m $HOME/Downloads/src/whisper.cpp/models/ggml-medium-q5_0.bin \
-sns --convert --port 7777

[Install]
WantedBy=default.target
EOF
```

This will create `$HOME/.config/systemd/user/whisper.service` which should be edited for the preferred port, model, vad, etc. We're still using port 7777 to avoid conflicts.

Next, run `systemctl --user daemon-reload` to make the service available.

Install `Guake` and launch `guake - e voice_client_local` with a hotkey, such as Alt-Ctrl-V.

## Other terminals

Instead of launching in the tray with `Guake`, the script may be launched with `xterm` e.g. `xterm -e voice_client_local` or any other terminal. It does not actually need a desktop to run. But if it does run on the desktop, we can use `ydotool` to press Alt-Tab. That should return control to whatever desktop app was running before it was launched. Add a line like this.

```shell
sleep 0.25 && ydotool key 56:0 42:0 56:1 15:1 56:0 15:0
```

## Notes

- Adjust mic volume for best results. If recording never stops, mic volume is up too high. If you can't adjust volume for some reason, edit `voice_typing` or `voice_client`. And change silence-detection threshold from 4% and 2% to something higher, like 6% and 5%: `rec -c 1 -r 22050 -t mp3 "$tmp" silence 1 0.2 6% 1 1.0 5%`
- Optionally create a Keybinding for mic mute/unmute. If there is continuous noise in the background, it can go into a recording loop and never get around to typing text. If your system has pulseaudio, this might work for you: `pactl set-source-mute $(pactl get-default-source) toggle`

- First run of `voice_typing` might be slow as it needs to download the model (better yet, use whisper or whisper.cpp from cli first to download a model.

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

## Similar Projects

- [Whisper Typer Tool](https://github.com/dynamiccreator/whisper-typer-tool)
- [Whisper Dictation](https://github.com/themanyone/whisper_dictation.git)
- [BabelFish Universal Translator](https://github.com/themanyone/BabelFish)

### Thanks for trying out Voice Typing!

- GitHub https://github.com/themanyone
- YouTube https://www.youtube.com/themanyone
- Mastodon https://mastodon.social/@themanyone
- Linkedin https://www.linkedin.com/in/henry-kroll-iii-93860426/
- Buy me a coffee https://buymeacoffee.com/isreality
- [TheNerdShow.com](http://thenerdshow.com/)

Copyright (C) 2026 Henry Kroll III, www.thenerdshow.com.
See [LICENSE](LICENSE) for details.
