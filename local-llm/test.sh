#!/usr/bin/env sh
# Smoke test: checks the server is up, the model is present, and it answers.
set -eu
HOST="${OLLAMA_URL:-http://localhost:${OLLAMA_PORT:-11434}}"
MODEL="${OLLAMA_MODEL:-gemma3:4b}"

echo "Server version:"
curl -fsS "$HOST/api/version"; echo

echo "Installed models:"
TAGS=$(curl -fsS "$HOST/api/tags")
echo "$TAGS" | grep -o '"name":"[^"]*"' || echo "(none yet)"
if ! echo "$TAGS" | grep -q "\"name\":\"$MODEL\""; then
  echo "Model $MODEL is not installed yet. Check: docker compose logs -f model-pull" >&2
  exit 1
fi

echo "Asking $MODEL a question (first call loads the model, can take a while on CPU)..."
curl -fsS "$HOST/api/generate" \
  -d "{\"model\":\"$MODEL\",\"prompt\":\"Reply with one short sentence: what is Ollama?\",\"stream\":false}" \
  | grep -o '"response":"[^"]*"'
