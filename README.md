# llama.cpp / Strata and Open WebUI

Two alternative AMD GPU stacks, each with its own standalone Compose file:

- `compose.llama.yaml`: llama.cpp + Open WebUI (default)
- `compose.strata.yaml`: Strata + Open WebUI, configured for Radeon AI PRO R9700 and Flash-Next GSQ-RCO

## llama.cpp

```bash
make run
make stop
```

Open http://localhost. The backend API is on port 8080.

### Model downloads for llama.cpp

```bash
make model-coder390
make model-davidau
make model-flash-next-sc117
```

## Strata

```bash
make run-strata
```

### Model downloads for Strata

```bash
make model-flash-next
```
