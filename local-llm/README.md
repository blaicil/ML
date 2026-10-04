# Local LLM: Ollama + Gemma in Docker

Runs [Ollama](https://ollama.com) in a container and serves Google's
[Gemma 3](https://ollama.com/library/gemma3) model on `http://localhost:11434`.
The model is pulled automatically on first start and kept in a Docker volume,
so later starts are instant and work offline.

## Requirements

- Docker Desktop (Windows/macOS) or Docker Engine + Compose v2 (Linux)
- About 5 GB free disk and 8 GB RAM for the default `gemma3:4b`
- Optional: an NVIDIA GPU (see below)

## Run it

```sh
cd local-llm
cp .env.example .env        # optional: pick another model or port
docker compose up -d        # starts Ollama, then pulls the model
docker compose logs -f model-pull   # watch the download; it exits when done
```

With an NVIDIA GPU (Linux with the NVIDIA Container Toolkit, or Windows Docker
Desktop on WSL2):

```sh
docker compose -f compose.yaml -f compose.gpu.yaml up -d
```

On macOS, Docker containers cannot use the Apple GPU, so this runs on CPU. For
GPU speed on a Mac, install the native Ollama app instead.

## Test it

```sh
./test.sh
```

Or by hand:

```sh
# Server is up
curl http://localhost:11434/api/version

# Models installed
curl http://localhost:11434/api/tags

# One-shot generation
curl http://localhost:11434/api/generate -d '{
  "model": "gemma3:4b",
  "prompt": "Why is the sky blue? One sentence.",
  "stream": false
}'

# Chat
curl http://localhost:11434/api/chat -d '{
  "model": "gemma3:4b",
  "messages": [{"role": "user", "content": "Hello!"}],
  "stream": false
}'

# Interactive chat in the terminal
docker exec -it ollama ollama run gemma3:4b
```

On Windows PowerShell, use `curl.exe` and escape the JSON quotes, or run
`Invoke-RestMethod -Method Post -Uri http://localhost:11434/api/generate -Body '{"model":"gemma3:4b","prompt":"Hi","stream":false}'`.

Ollama also exposes an OpenAI-compatible API at
`http://localhost:11434/v1`, so agent frameworks that speak the OpenAI API can
point at it with any API key value.

## Choosing a Gemma size

Set `OLLAMA_MODEL` in `.env`, then `docker compose up -d model-pull`.

| Tag          | Download | Good for                                |
|--------------|----------|-----------------------------------------|
| `gemma3:1b`  | ~0.8 GB  | Low-RAM machines, fastest               |
| `gemma3:4b`  | ~3.3 GB  | Default; CPU with 8 GB+ RAM             |
| `gemma3:12b` | ~8 GB    | 16 GB+ RAM, or a GPU with 12 GB+ VRAM   |
| `gemma3:27b` | ~17 GB   | GPU with 24 GB+ VRAM                    |

`gemma3:4b` and larger also accept images. Any other tag from the Ollama
library works the same way.

## Everyday commands

```sh
docker compose ps                     # status
docker compose stop                   # stop (keeps models)
docker compose up -d                  # start again
docker exec -it ollama ollama list    # models on disk
docker exec -it ollama ollama rm gemma3:1b
docker compose down -v                # remove everything, including models
```

## Notes

- The API is bound to `127.0.0.1` only. Set `OLLAMA_BIND=0.0.0.0` in `.env` to
  reach it from other machines on your network; Ollama has no authentication,
  so only do this on a trusted network.
- `OLLAMA_IMAGE_TAG` pins the Ollama release if `latest` ever breaks something.
