# Verification-Driven Development Skill

## README FOR HUMANS

<img src="verification-driven-development/assets/vdd.png" alt="Verification-Driven Development logo" width="50%" />

Build fast, with proof, and let the agent do the heavy lifting.

This skill gives your agent a strict verification-first operating mode:
- The agent plans the implementation and verification path.
- The agent runs the commands, inspects real outputs, and fixes failures iteratively.
- The agent only closes when checks pass and evidence is captured.

You provide the goal and access; the agent drives execution end to end.
Result: reliable delivery without manual babysitting.

Install with the Skill Installer (for coding agents):

```text
Install from GitHub URL: https://github.com/jostelzer/verification_driven_development/tree/main/verification-driven-development
```

Or use the local installer script:

```bash
# Codex
./install.sh --target codex

# Claude Code
./install.sh --target claude

# Cursor (project rule in <project>/.cursor/rules)
./install.sh --target cursor --cursor-project /path/to/your/project
```

Then restart your coding agent (or refresh skills), and invoke with:
- `$verification-driven-development`
- `VDD` (acronym)

Generate a professionally formatted PDF report from Markdown:

```bash
# Direct script interface
./scripts/render-report-pdf.sh \
  verification-driven-development/references/report-template.md \
  .agent/runs/$(date +%Y%m%d-%H%M%S)/verification-report.pdf

# Optional: keep normalized Markdown used for PDF rendering
NORMALIZED_MD_OUT=/tmp/report.normalized.md \
  ./scripts/render-report-pdf.sh \
  verification-driven-development/references/report-template.md \
  /tmp/verification-report.pdf

# Generate standardized gist (chat-ready) from a full report
./scripts/render-gist.sh \
  verification-driven-development/references/report-template.md \
  .agent/runs/$(date +%Y%m%d-%H%M%S)/verification-gist.md

# Validate report format before closeout
./scripts/validate-vdd-report.sh \
  .agent/runs/$(date +%Y%m%d-%H%M%S)/verification-report.md

# Convenience Make target
make report-pdf \
  INPUT=verification-driven-development/references/report-template.md \
  OUTPUT=.agent/runs/$(date +%Y%m%d-%H%M%S)/verification-report.pdf

# Convenience Make targets for gist and full package
make report-gist \
  INPUT=verification-driven-development/references/report-template.md \
  GIST_OUTPUT=.agent/runs/$(date +%Y%m%d-%H%M%S)/verification-gist.md

make report-package \
  INPUT=verification-driven-development/references/report-template.md

# Validate + render pdf + render gist
make report-closeout \
  INPUT=.agent/runs/$(date +%Y%m%d-%H%M%S)/verification-report.md \
  OUTPUT=.agent/runs/$(date +%Y%m%d-%H%M%S)/verification-report.pdf \
  GIST_OUTPUT=.agent/runs/$(date +%Y%m%d-%H%M%S)/verification-gist.md
```

Default closeout expectation in VDD:
- Attempt all three artifacts by default:
1. `verification-report.md`
2. `verification-report.pdf`
3. `verification-gist.md`

If PDF rendering fails after an in-agent attempt, closeout may continue with markdown + gist, but the report must include exact PDF failure details (command, exit status, stderr signal).

Rendering defaults are defined in:
- `verification-driven-development/references/pandoc-pdf.yaml`

The renderer uses Pandoc defaults when supported, and automatically falls back
to equivalent pinned CLI options on older Pandoc versions.

PDF export normalizes status badges to deterministic text values:
- `🟩 VERIFIED ✅` -> `[VERIFIED]`
- `🟨 READY FOR HUMAN VERIFICATION 🧑‍🔬` -> `[READY FOR HUMAN VERIFICATION]`
- `🟥 BLOCKED ⛔` -> `[BLOCKED]`

Standardized templates:
- Full report: `verification-driven-development/references/report-template.md`
- Gist (chat format): `verification-driven-development/references/gist-template.md`

The gist generator reads these sections from the full report template/content:
- `## Gist Claim`
- `## Gist Evidence`
- `## Gist Human Run`

`How Human Can Run This` is validated for operator realism:
- Must include concrete bash commands plus `Pass signal:` and `Fail signal:`.
- Must not reference ad-hoc harness scripts from `.agent/runs`, `/tmp`, or `playwright/check/spec` files.

`validate-vdd-report.sh` enforces required report sections and format fields before closeout.

To uninstall:

```bash
# Remove from agents/codex/claude
./uninstall.sh --target auto

# Remove Cursor project rule
./uninstall.sh --target cursor --cursor-project /path/to/your/project
```

## README FOR AGENTS

Dear agentic colleague, start here and follow the pointers:

- `verification-driven-development/SKILL.md`: the operating rules and workflow.
- `verification-driven-development/agents/openai.yaml`: UI metadata (chips/listing).
- `verification-driven-development/references/`: supporting references used by the skill.
- `install.sh`: install or update the skill.
- `uninstall.sh`: remove the skill from local skill directories.

## License

Apache License 2.0. See `LICENSE`.
