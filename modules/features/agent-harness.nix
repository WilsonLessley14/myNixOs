{ self, inputs, lib, ... }:

let
  # Shared pi models.json pointing at local llama-server OpenAI-compatible endpoint
  piModelsJson = builtins.toJSON {
    providers = {
      llama-cpp = {
        baseUrl = "http://localhost:8080/v1";
        api = "openai-completions";
        apiKey = "none";
        models = [ { id = "local"; } ];
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
        extraFlags = [ "--gpu-layers" "99" ];
      };

      # Write pi models config declaratively for root; users should symlink or copy
      environment.etc."pi-agent/models.json" = {
        text = piModelsJson;
        mode = "0444";
      };

    };
  };

  darwinModule = { config, pkgs, lib, ... }: let
    cfg = config.agentHarness;
    llamaServerBin = "${pkgs.llama-cpp}/bin/llama-server";
    piModelsFile = pkgs.writeText "pi-models.json" piModelsJson;
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
          echo "Usage: llamactl {status|start|stop|restart|logs|errors|ping|setup-harness|download}"
          exit 1
          ;;
      esac
    '';
  in {
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
    };

    config = {
      environment.systemPackages = with inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}; [
        pi
        claude-code
      ] ++ [ pkgs.llama-cpp llamaCtl ];

      # User LaunchAgent for llama-server (Metal GPU offload via -ngl)
      launchd.user.agents.llama-server = lib.mkIf (cfg.modelPath != null) {
        serviceConfig = {
          Label = "local.llama-server";
          ProgramArguments = [
            llamaServerBin
            "--model" cfg.modelPath
            "--host" "127.0.0.1"
            "--port" "8080"
            "--gpu-layers" "99"
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
