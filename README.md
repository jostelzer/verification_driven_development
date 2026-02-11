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
