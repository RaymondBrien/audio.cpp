set shell := ["bash", "-eu", "-o", "pipefail", "-c"]

audiocpp_cli := "./build/bin/audiocpp_cli"
model_file := "./build/bin/models/PocketTTS-GGUF/english/pocket-tts-english-q8_0.gguf"
backend := "metal"

# Generate a WAV file from text using PocketTTS-GGUF.
tts text="this is a test" output="wavs/test.wav":
    mkdir -p "$(dirname "{{output}}")"
    "{{audiocpp_cli}}" \
        --task tts \
        --family pocket_tts \
        --model "{{model_file}}" \
        --backend "{{backend}}" \
        --voice-id alba \
        --text "{{text}}" \
        --out "{{output}}"
    afplay {{output}}
