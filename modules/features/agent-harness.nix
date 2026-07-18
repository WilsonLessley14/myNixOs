{ self, inputs, lib, ... }:

let
  # pi models.json for local llama-server. Single provider/port always;
  # see contextSplit below.
  mkPiModelsJson = { contextWindow }:
    let
      model = { id = "local"; } // lib.optionalAttrs (contextWindow != null) { inherit contextWindow; };
    in
    builtins.toJSON {
      providers = {
        llama-cpp = {
          baseUrl = "http://localhost:8080/v1";
          api = "openai-completions";
          apiKey = "none";
          models = [ model ];
        };
      };
    };

  nixosModule = { config, pkgs, lib, ... }: let
    cfg = config.agentHarness;
    llamaCtl = pkgs.writeShellScriptBin "llamactl" ''
      MODEL_PATH="${if cfg.modelPath != null then toString cfg.modelPath else ""}"
      MODEL_URL="${if cfg.modelUrl != null then cfg.modelUrl else ""}"

      case "$1" in
        status)  systemctl status llama-cpp ;;
        start)   systemctl start llama-cpp ;;
        stop)    systemctl stop llama-cpp ;;
        restart) systemctl restart llama-cpp ;;
        logs)    journalctl -fu llama-cpp ;;
        errors)  journalctl -fu llama-cpp -p err ;;
        ping)
          response=$(${pkgs.curl}/bin/curl -sf http://127.0.0.1:8080/v1/models 2>&1) || {
            echo "error: server not reachable at http://127.0.0.1:8080"
            exit 1
          }
          echo "$response" | ${pkgs.jq}/bin/jq -r '.data[].id' 2>/dev/null \
            && echo "ok: server is up" \
            || echo "ok: server is up (no models listed)"
          ;;
        download)
          if [ -z "$MODEL_URL" ]; then
            echo "error: no modelUrl configured in agentHarness"
            exit 1
          fi
          echo "Model URL:  $MODEL_URL"
          echo "Saved to:   $MODEL_PATH"
          printf "Download this model? [y/N] "
          read -r reply
          if [ "$reply" != "y" ] && [ "$reply" != "Y" ]; then
            echo "Aborted."
            exit 0
          fi
          mkdir -p "$(dirname "$MODEL_PATH")"
          ${pkgs.curl}/bin/curl -L --progress-bar -o "$MODEL_PATH" "$MODEL_URL"
          ;;
        *)
          echo "Usage: llamactl {status|start|stop|restart|logs|errors|ping|download}"
          exit 1
          ;;
      esac
    '';
  in {
    imports = [ inputs.pi-orchestrator.nixosModules.pi-orchestrator ];

    options.agentHarness = {
      modelPath = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        description = "Absolute path to the GGUF model file for llama-server (no ~ expansion).";
      };
      modelUrl = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "URL to download the GGUF model from if modelPath does not exist.";
      };
    };

    config = {
      environment.systemPackages = with inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}; [
        pi
        claude-code
      ] ++ [ pkgs.llama-cpp llamaCtl ];

      services.llama-cpp = lib.mkIf (cfg.modelPath != null) {
        enable = true;
        model = cfg.modelPath;
        host = "127.0.0.1";
        port = 8080;
        # --metrics: Prometheus endpoint (off by default). --slots: on by
        # default, set explicitly. Dashboard static-serving is wired only in
        # the darwin module (the M1 harness host).
        extraFlags = [ "--gpu-layers" "99" "--metrics" "--slots" ];
      };

      # Write pi models config declaratively for root; users should symlink or copy
      environment.etc."pi-agent/models.json" = {
        text = mkPiModelsJson { contextWindow = null; };
        mode = "0444";
      };

    };
  };

  # The llama.cpp Monitor Dashboard (abhiFSD/llama.cpp-Monitor-Dashboard): a
  # single static HTML file, zero deps, all client-side. It polls /metrics and
  # /slots. We serve it from llama-server's own static-file server (--path),
  # reachable at http://localhost:8080/monitor.html. No Python sidecar (that
  # only surfaces the same OS-level memory numbers Activity Monitor shows; for
  # real model memory use `footprint <pid>` / `memory_pressure`).
  llamaDashboardDir = ../features/llama-dashboard;

  darwinModule = { config, pkgs, lib, ... }: let
    cfg = config.agentHarness;
    llamaServerBin = "${pkgs.llama-cpp}/bin/llama-server";
    piModelsFile = pkgs.writeText "pi-models.json" (mkPiModelsJson {
      # With --kv-unified set (see launchd args), each slot gets the full
      # ctxSize from a shared buffer, so ctxSize is the real per-agent window.
      contextWindow = if cfg.contextSplit.enable then cfg.contextSplit.ctxSize else null;
    });
    llamaCtl = pkgs.writeShellScriptBin "llamactl" ''
      MODEL_PATH="${cfg.modelPath}"
      MODEL_URL="${if cfg.modelUrl != null then cfg.modelUrl else ""}"

      case "$1" in
        status)  launchctl list | grep llama-server || echo "llama-server: not running" ;;
        start)   launchctl start local.llama-server ;;
        stop)    launchctl stop local.llama-server ;;
        restart) launchctl stop local.llama-server && launchctl start local.llama-server ;;
        logs)    tail -f /tmp/llama-server.log ;;
        errors)  tail -f /tmp/llama-server.err ;;
        ping)
          response=$(${pkgs.curl}/bin/curl -sf http://127.0.0.1:8080/v1/models 2>&1) || {
            echo "error: server not reachable at http://127.0.0.1:8080"
            exit 1
          }
          echo "$response" | ${pkgs.jq}/bin/jq -r '.data[].id' 2>/dev/null \
            && echo "ok: server is up" \
            || echo "ok: server is up (no models listed)"
          ;;
        monitor)
          open http://127.0.0.1:8080/monitor.html
          ;;
        mem)
          pid=$(${pkgs.procps}/bin/pgrep -f llama-server | head -1)
          if [ -z "$pid" ]; then echo "llama-server not running"; exit 1; fi
          # footprint reports phys_footprint (dirty+compressed+wired) — the
          # honest per-process cost, the same number Xcode's gauge uses and a
          # truer figure than Activity Monitor's blended column.
          echo "== model process (pid $pid) =="
          footprint "$pid" 2>/dev/null | grep -iE 'phys_footprint|footprint:' | head -3
          echo "== system memory pressure =="
          memory_pressure 2>/dev/null | tail -3
          ;;
        setup-harness)
          mkdir -p "$HOME/.pi/agent"
          ln -sf ${piModelsFile} "$HOME/.pi/agent/models.json"
          echo "ok: linked $HOME/.pi/agent/models.json"
          ;;
        download)
          if [ -z "$MODEL_URL" ]; then
            echo "error: no modelUrl configured in agentHarness"
            exit 1
          fi
          echo "Model URL:  $MODEL_URL"
          echo "Saved to:   $MODEL_PATH"
          printf "Download this model? [y/N] "
          read -r reply
          if [ "$reply" != "y" ] && [ "$reply" != "Y" ]; then
            echo "Aborted."
            exit 0
          fi
          mkdir -p "$(dirname "$MODEL_PATH")"
          ${pkgs.curl}/bin/curl -L --progress-bar -o "$MODEL_PATH" "$MODEL_URL"
          ;;
        *)
          echo "Usage: llamactl {status|start|stop|restart|logs|errors|ping|monitor|mem|setup-harness|download}"
          exit 1
          ;;
      esac
    '';
  in {
    imports = [ inputs.pi-orchestrator.modules.darwin.pi-orchestrator ];

    options.agentHarness = {
      modelPath = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Absolute path to the GGUF model file for llama-server (no ~ expansion).";
      };
      modelUrl = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "URL to download the GGUF model from if modelPath does not exist.";
      };

      # See pi-orchestrator/PLAN.md "Context budget".
      # One llama-server, one model load (2 loads of a ~30GB model won't fit
      # in 64GB). --parallel 2 with EXPLICIT --kv-unified so each slot gets the
      # full ctxSize from a shared buffer. (Without --kv-unified, explicit
      # --parallel disables the unified buffer and --ctx-size is divided across
      # slots: 64k -> 32k/slot, which surfaced as an "exceeds context size
      # (32000)" 400 error.) Slot pinning isn't possible via pi's
      # OpenAI-compatible API; relies on --slot-prompt-similarity to keep
      # each agent on its own slot in practice — soft guarantee, worst case
      # is a reprocessed prompt, not corrupted context.
      contextSplit = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Run llama-server with --parallel 2 so the pi-orchestrator and its builder child each get a slot.";
        };
        ctxSize = lib.mkOption {
          type = lib.types.int;
          default = 64000;
          description = "Per-slot context window. Paired with explicit --kv-unified so each slot gets this full amount from a shared buffer (not divided across slots).";
        };
      };
    };

    config = {
      environment.systemPackages = with inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}; [
        pi
        claude-code
      ] ++ [ pkgs.llama-cpp llamaCtl ];

      # User LaunchAgent for llama-server (Metal GPU offload via -ngl).
      # contextSplit.enable adds --parallel 2 + --ctx-size; see option doc above.
      launchd.user.agents.llama-server = lib.mkIf (cfg.modelPath != null) {
        serviceConfig = {
          Label = "local.llama-server";
          ProgramArguments = [
            llamaServerBin
            "--model" cfg.modelPath
            "--host" "127.0.0.1"
            "--port" "8080"
            "--gpu-layers" "99"
            # Observability: Prometheus /metrics (off by default) + /slots (on
            # by default, set explicitly), and serve the static monitor.html
            # dashboard from the built-in file server (-> /monitor.html).
            "--metrics"
            "--slots"
            "--path" "${llamaDashboardDir}"
          ] ++ lib.optionals cfg.contextSplit.enable [
            "--parallel" "2"
            "--ctx-size" (toString cfg.contextSplit.ctxSize)
            # kv_unified only AUTO-enables when slots are auto; setting
            # --parallel 2 makes slots explicit, which turns it OFF, and then
            # --ctx-size becomes the pooled total DIVIDED across slots (64k ->
            # 32k/slot, the "exceeds context size (32000)" error). Enable it
            # explicitly so each slot gets the full --ctx-size from one shared
            # buffer.
            "--kv-unified"
            "--slot-prompt-similarity" "0.10" # pinned explicitly, sticky-slot routing depends on it
          ];
          RunAtLoad = false;
          KeepAlive = false;
          StandardOutPath = "/tmp/llama-server.log";
          StandardErrorPath = "/tmp/llama-server.err";
        };
      };

    };
  };

in {
  flake.nixosModules.agent-harness = nixosModule;
  flake.modules.darwin.agent-harness = darwinModule;
}
