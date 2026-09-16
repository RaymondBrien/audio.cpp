# Video Pipeline TTS Workflow

The intended workflow is:

1. Configure the server with the path to your already-downloaded model.
2. Start `audiocpp_server`.
3. Send `POST /v1/audio/speech` requests.
4. Save each binary response as a WAV file wherever your script chooses.
5. Repeat requests sequentially as part of a larger pipeline.

## Configure a local model

For this repo, the bundled PocketTTS-GGUF model is located at `/build/bin/models/PocketTTS-GGUF`.

```json
{
  "host": "127.0.0.1",
  "port": 8080,
  "backend": "cuda",
  "lazy_load": true,
  "models": [
    {
      "id": "pockettts-gguf",
      "family": "qwen3_tts",
      "path": "/build/bin/models/PocketTTS-GGUF",
      "task": "tts",
      "mode": "offline"
    }
  ]
}
```

With `lazy_load: true`, the server starts quickly and loads the model on the first request. Subsequent requests reuse the loaded model. You can set `"lazy": false` on the model if you want it loaded during server startup instead.

## Generate one WAV file

A single request can write directly to a WAV file:

```bash
curl --fail http://127.0.0.1:8080/v1/audio/speech \
  -H 'Content-Type: application/json' \
  -o /absolute/output/clip-001.wav \
  -d '{
    "model": "pockettts-gguf",
    "input": "This is one generated audio clip.",
    "seed": 1234
  }'
```

The speech endpoint returns `audio/wav` by default. The output location is controlled by the client—in this case, `curl -o`. The server itself does not need to know where you want the output saved.

## Batch generation pipeline

A simple batch pipeline could look like:

```bash
#!/usr/bin/env bash
set -euo pipefail

server_url="http://127.0.0.1:8080"
output_dir="/absolute/output/clips"
mkdir -p "$output_dir"

texts=(
  "This is the first clip."
  "This is the second clip."
  "This is the third clip."
)

for i in "${!texts[@]}"; do
  printf -v filename "%s/clip-%04d.wav" "$output_dir" "$((i + 1))"

  jq -n \
    --arg text "${texts[$i]}" \
    '{
      model: "pockettts-gguf",
      input: $text,
      seed: 1234
    }' |
    curl --fail --silent --show-error \
      "$server_url/v1/audio/speech" \
      -H 'Content-Type: application/json' \
      --data-binary @- \
      -o "$filename"

  echo "Saved $filename"
done
```

## Start the server from the script

You can start the server from the same script and wait for readiness:

```bash
build/bin/audiocpp_server --config server.json &
server_pid=$!
trap 'kill "$server_pid"' EXIT

until curl --silent --fail http://127.0.0.1:8080/health >/dev/null; do
  sleep 0.5
done

# Run generation loop here.
```

## Voice cloning

For voice cloning, include fields such as:

```json
{
  "model": "pockettts-gguf",
  "input": "Generated using the reference voice.",
  "voice_ref": "/absolute/path/to/reference.wav",
  "reference_text": "Transcript of the reference audio."
}
```

The reference path is interpreted on the **server machine**. If the client and server are different machines, use the base64 `voice_ref` form or make the reference audio available to the server.

## Multi-stage pipelines

`POST /v1/tasks/run` can also be used for generic framework tasks and multi-stage processing, but `/v1/audio/speech` is the simplest route for TTS. For a pipeline involving several models, you can have one script call speech, transcription, enhancement, conversion, or other task endpoints and save each response to a known intermediate file. The server serializes requests for a given model, so sequential requests are the safest default for a batch pipeline.
