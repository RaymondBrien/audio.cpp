set shell := ["bash", "-eu", "-o", "pipefail", "-c"]

audiocpp_cli := "./build/bin/audiocpp_cli"
model_dir := "./build/bin/models"
model_relative := "PocketTTS-GGUF/english/pocket-tts-english-q8_0.gguf"
model_file := model_dir + "/" + model_relative
docker_image := "ghcr.io/0xshug0/audio.cpp:full-cpu"
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
        --out "{{output}}" \
        --metrics
    afplay {{output}}

# Generate a WAV file from text using PocketTTS-GGUF in Docker.
tts-docker text="this is a test" output="wavs/test.wav" rm="":
    mkdir -p "$(dirname "{{output}}")"
    docker run \
        {{rm}} \
        -v "$(pwd)/{{model_dir}}:/models:ro" \
        -v "$(pwd)/$(dirname "{{output}}"):/output" \
        "{{docker_image}}" \
        cli \
        --task tts \
        --family pocket_tts \
        --model "/models/{{model_relative}}" \
        --backend cpu \
        --voice-id alba \
        --text "{{text}}" \
        --out "/output/$(basename "{{output}}")" \
        --metrics
    afplay {{output}}


# Aditional params to play with:
# --metrics
# --request-sequence <json file>
#
# example json: see requestsequenes/example1.json
# for further options, see docs/usage.md
#
