# Local Models — on-machine llama.cpp runtime

Truth on disk (git install): docs page `website/docs/user-guide/local-models.md`,
handlers `hermes_cli/web_routers/local_models.py`, terminal flow
`hermes_cli/model_setup_flows_local.py`, engine/store `hermes_cli/local_runtime/`,
models in `<hermes-home>/models` (`models_dir` in status).

## Parity — never answer "that's desktop-only" without checking

The desktop pane (Settings → Providers → Local Models) and the `hermes model`
picker row **register the same handlers**: the CLI flow imports
`hermes_cli.web_routers.local_models` in-process, so both surfaces run one code
path (`model_setup_flows_local.py::_model_flow_local`).

| Capability | Desktop pane | `hermes model` picker | Headless alternative |
|---|---|---|---|
| Catalog priced for this machine (fit, ★ recommendation, size) | yes | yes | probe `local_models_catalog()` |
| Quickstart: pinned engine → model download → start server → set default | yes | yes | same picker; Ctrl+C pauses, re-pick resumes |
| Activate a model already on disk | yes | yes (row reads `<id> — <size> · on disk`) | drop a `.gguf` in `<hermes-home>/models` |
| Install / Update / Pause / Resume **buttons** | yes | no (Ctrl+C pause only) | — |
| Hugging Face "Find more models" + "Add model file" sideload | yes | **no CLI entry** (`/search`, `/search/files`, `/download-browsed`, `/sideload`) | download the GGUF yourself, then adopt it via the picker |
| Status-bar "System resources" readout | yes | n/a | `nvidia-smi`, Activity Monitor |

`hermes model` has **no non-interactive flag** (`--refresh`, `--portal-url`,
`--inference-url`, `--client-id`, `--scope`, `--no-browser`, `--timeout`,
`--ca-bundle`, `--insecure` only) — run it in a real terminal (or tmux), and use
the probe below when you need facts rather than a TUI.

## Probe the numbers without opening the UI (generalizes to any route-backed feature)

Router handlers are plain **sync** functions returning dicts (sync on purpose:
blocking urlopen/nvidia-smi/scans run in the threadpool), so import them with the
source tree's own venv and print exactly what the pane would render:

```bash
cd "$HERMES_HOME/hermes-agent" && venv/bin/python -c "
from hermes_cli.web_routers import local_models as lm
hw, st, cat = lm.local_models_hardware(), lm.local_models_status(), lm.local_models_catalog()
print('RAM', lm._human_gb(hw['ram_total_bytes']), 'uma', hw['uma'], 'vram', hw['vram_label'])
print('engine', st['runtime_installed'], st['configured_tag'], st['models_dir'], st['active_model_id'])
for r in cat['models']:
    print(r.get('fits'), r.get('recommended'), r['display_name'], r['size_label'], r.get('fit_summary'))
"
```

Use `<source>/venv/bin/python`, never the system python. The pattern applies to
any feature whose desktop UI is a web router: print the handler's return value
in-process instead of screenshotting a pane.

**Gating check** — a real feature can be *present but gated*; find the gate before
promising it. The local-models picker row is added only when
`local_models_available()` is True (PM pins an engine for this platform; CPU is
pinned on every target with any build, so False means nothing is installable):

```bash
venv/bin/python -c "from hermes_cli.model_setup_flows_local import local_models_available; print(local_models_available())"
```

Row registration lives in `hermes_cli/main_provider_setup.py` (filtered by
`LLAMACPP_ALIASES`); `hermes_cli/models_local.py` covers detecting servers you
already run (Ollama, LM Studio, llama-server).

## Fit is per-machine — probe before promising a download

`local_models_catalog()` prices every row against THIS machine: `fits`,
`recommended` (★ = highest quality that runs fully in GPU/unified memory at a
predicted ≥20 tok/s), `needs_engine`, `size_label` (download size of the build
selected for this hardware), `downloaded`, `downloaded_model_id`, `fit_summary`.

- The picker can come up **empty of catalog choices**: unfit rows stay listed with
a reason and the flow prints "N catalog model(s) need more memory or a newer
engine than this machine has", offering only on-disk models + "Leave unchanged".
Run the probe first — never walk a user through quickstart before checking that
something fits.
- Builds below 4-bit are never offered (quality loss is too severe), so a machine
that cannot run the 4-bit build even spilled to system RAM cannot run that model
at all — freeing RAM does not close a total-memory shortfall.
- Quickstart installs the engine **before** choosing the model, so GPU detection
can change which builds appear; `backend: auto` prefers CUDA/Vulkan, then the
platform builds, then CPU.

## Fallbacks when nothing in the catalog fits, or the user has their own model

1. **Adopt a GGUF.** Put the `.gguf` in `<hermes-home>/models` (the dir exists even
when empty — `status.models_dir`). `hermes model` → Local models lists it as an
on-disk row; selecting it installs the pinned engine, then activates it. Nothing
is copied or moved — the original file stays where it is.
2. **Point at a server you run.** A llama-server on `:8080` is detected
automatically. Extra ports: `hermes config set local_runtime.detect_ports '[8081]'`.
Or bind explicitly (an explicit entry wins over detection):
   ```bash
   hermes config set providers.llamacpp.base_url http://127.0.0.1:8081/v1
   hermes config set providers.llamacpp.model my-model
   hermes config set model.provider llamacpp
   hermes config set model.default my-model
   ```
   The `/model` → Local row and `provider: llamacpp` resolve to it. With nothing
reachable the error names the local runtime ("the local model server isn't
running") rather than unknown-provider/missing-key — a useful confirmation that
the wiring, not the address, is what to debug next.
3. **Other runtimes** — Ollama / MLX / manual builds: docs guides
`guides/local-ollama-setup` and `guides/local-llm-on-mac`.

## Config & lifecycle

```yaml
local_runtime:
  enabled: false     # true starts the managed server with Hermes; the "Use"/activate path sets it
  backend: auto      # auto | cuda | metal | vulkan | hip | cpu
  detect_ports: []   # extra ports to probe for a server you run yourself
```

- Selecting a local model is just `model.provider: llamacpp` + `model.default`.
- Engine versions come **only** from PM's lockfile (`pm/lock.json`, SHA-256 pinned)
— there is no `local_runtime.tag` override. An installed PM engine is reused at
boot without downloading; a new pin installs via the desktop update button.
- Ctrl+C pauses a download at a chunk boundary; picking the same model again
resumes from retained partials. Unpacking/verification/server-activation are
separate phases — a paused job is not a broken one.
- Idle models unload after 15 minutes and reload on the next message. The context
window starts GPU-sized and grows toward the native max; if it cannot grow,
Hermes compresses instead of claiming a window the server did not receive.
- Deleting a model removes every file it staged, including vision adapters and
speculative-decoding companions.
- Desktop on platforms outside macOS/Windows/Linux hides the pane unless launched
`hermes desktop --local`; the CLI row is unaffected by that flag.
- **Revert to cloud:** `hermes config set model.provider <p>` +
`hermes config set model.default <m>` (or re-run `hermes model`). Never hand-edit
`config.yaml` for any of this.
