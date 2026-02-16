.PHONY: report-validate report-brief report-closeout failover-issue skill-lint test-scripts init-run

INPUT ?= verification-driven-development/references/report-template.md
STAMP ?= $(shell date +%Y%m%d-%H%M%S)
FAILOVER_SUMMARY ?= validator crashed during closeout
FAILOVER_STACKTRACE ?= tests/fixtures/errors/vdd-stacktrace.txt

report-brief:
	@./scripts/render-verification-brief.sh "$(INPUT)"

report-validate:
	@./scripts/validate-vdd-report.sh "$(INPUT)"

report-closeout: report-validate
	@echo "Closeout validated:"
	@echo "  Report: $(INPUT)"

failover-issue:
	@./scripts/render-vdd-failover-issue.sh \
		--summary "$(FAILOVER_SUMMARY)" \
		--stacktrace-file "$(FAILOVER_STACKTRACE)"

skill-lint:
	@./scripts/lint-skill.sh

test-scripts:
	@./tests/test-vdd-scripts.sh

init-run:
	@./scripts/init-vdd-run.sh "$(STAMP)"
