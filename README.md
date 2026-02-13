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

Generate standardized closeout outputs:

```bash
# Render standardized Verification Brief (chat-ready) to stdout from a full report
./scripts/render-verification-brief.sh \
  .agent/runs/$(date +%Y%m%d-%H%M%S)/verification-report.md

# Validate report format before closeout
./scripts/validate-vdd-report.sh \
  .agent/runs/$(date +%Y%m%d-%H%M%S)/verification-report.md

# Convenience Make target for Verification Brief (stdout)
make report-brief \
  INPUT=.agent/runs/$(date +%Y%m%d-%H%M%S)/verification-report.md

# Validate markdown closeout format
make report-closeout \
  INPUT=.agent/runs/$(date +%Y%m%d-%H%M%S)/verification-report.md
```

Default closeout expectation in VDD:
- Produce markdown report by default: `verification-report.md`
- Render Verification Brief directly in chat (not as a default `.md` artifact).

Standardized templates:
- Full report: `verification-driven-development/references/report-template.md`
- Verification Brief (chat format): `verification-driven-development/references/verification-brief-template.md`

The Verification Brief generator reads these sections from the full report template/content:
- `## Verification Brief Claim`
- `## Verification Brief Evidence`
- `## Verification Brief How YOU Can Run This`

`How YOU Can Run This` is validated for operator realism:
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
