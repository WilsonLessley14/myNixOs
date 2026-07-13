# agent-harness

A NixOS/nix-darwin module that turns a host into an AI coding agent workstation. It installs the agent tooling, runs a local LLM inference server, and wires the two together so agents can run against a local model without touching an external API.

## Purpose

The module serves two goals:

1. **Agent tooling** — installs `pi` (a terminal coding agent) and `claude-code` from the `llm-agents.nix` flake input.
2. **Local inference** — runs `llama-server` (from `llama-cpp`) as a service, exposing an OpenAI-compatible HTTP API on `localhost:8080`. The `pi` agent is pre-configured to use this endpoint via `~/.pi/agent/models.json`.

Quality is prioritised over raw speed. GPU layers are fully offloaded (`--gpu-layers 99`) to take advantage of unified memory on Apple Silicon and any CUDA/ROCm device on NixOS — this is pure upside with no quality tradeoff since the memory is physically the same.

## Model choice

The module is designed for large, high-quality models in the 27B–32B parameter range. Recommended: **Gemma 4 31B Instruct** at **Q8_0** quantisation.

- Q8_0 is perceptually lossless relative to BF16
- The 31B MoE architecture is sparse, so active parameter count during inference is much lower than the total — it fits comfortably in 64GB unified memory with headroom for a large KV cache
- BF16 (~62GB weights) was ruled out because it leaves almost no room for KV cache at extended context lengths

Good source: `https://huggingface.co/unsloth/gemma-4-31B-it-GGUF`

## Platform differences

| Feature | NixOS | macOS (nix-darwin) |
|---|---|---|
| Inference service | `systemd` via `services.llama-cpp` | `launchd` user agent (`local.llama-server`) |
| pi config | `/etc/pi-agent/models.json` (declarative) | `~/.pi/agent/models.json` (symlink via `llamactl setup-harness`) |
| Log access | `journalctl` | `/tmp/llama-server.{log,err}` |

The server does **not** start automatically on either platform. Use `llamactl start` when you need it.

## Configuration

```nix
agentHarness = {
  # Absolute path where the GGUF will be stored. No ~ expansion.
  modelPath = "/Users/yourname/Library/Application Support/llama-cpp/model.gguf";

  # URL to fetch the model from. Used only by `llamactl download`.
  modelUrl = "https://huggingface.co/unsloth/gemma-4-31B-it-GGUF/resolve/main/gemma-4-31B-it-Q8_0.gguf";
};
```

Both options are nullable. If `modelPath` is null, the inference service is not configured. If `modelUrl` is null, `llamactl download` will error.

## First-time setup

```bash
# 1. Download the model (prompts for confirmation before fetching ~33GB)
llamactl download

# 2. Wire pi to the local server (macOS only — NixOS handles this declaratively)
llamactl setup-harness

# 3. Start the server
llamactl start

# 4. Confirm it's up and the model loaded
llamactl ping

# 5. Launch pi and select the local model with /model -> llama-cpp -> local
pi
```

## llamactl reference

| Command | Description |
|---|---|
| `status` | Show service status (systemctl/launchctl) |
| `start` | Start the inference server |
| `stop` | Stop the inference server |
| `restart` | Restart the inference server |
| `logs` | Tail stdout logs |
| `errors` | Tail stderr / error logs |
| `ping` | Hit `/v1/models` and confirm the server is reachable and the model loaded |
| `setup-harness` | Symlink the pi `models.json` config into `~/.pi/agent/` *(macOS only)* |
| `download` | Download the GGUF from `modelUrl` to `modelPath` with a confirmation prompt |
