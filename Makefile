.PHONY: report-validate report-brief report-closeout skill-lint test-scripts init-run

INPUT ?= verification-driven-development/references/report-template.md
STAMP ?= $(shell date +%Y%m%d-%H%M%S)

report-brief:
	@./scripts/render-verification-brief.sh "$(INPUT)"

report-validate:
	@./scripts/validate-vdd-report.sh "$(INPUT)"

report-closeout: report-validate
	@echo "Closeout validated:"
	@echo "  Report: $(INPUT)"

skill-lint:
	@./scripts/lint-skill.sh

test-scripts:
	@./tests/test-vdd-scripts.sh

init-run:
	@./scripts/init-vdd-run.sh "$(STAMP)"
