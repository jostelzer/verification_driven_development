.PHONY: report-validate manifest-validate report-brief human-card report-closeout failover-issue skill-lint test-scripts init-run

INPUT ?= verification-driven-development/references/report-template.md
MANIFEST ?= verification-driven-development/references/verification-manifest-template.json
STAMP ?= $(shell date +%Y%m%d-%H%M%S)
FAILOVER_SUMMARY ?= validator crashed during closeout
FAILOVER_STACKTRACE ?= tests/fixtures/errors/vdd-stacktrace.txt

report-brief:
	@./scripts/render-verification-brief.sh "$(INPUT)"

human-card:
	@./scripts/render-human-verification-card.sh "$(MANIFEST)"

report-validate:
	@./scripts/validate-vdd-report.sh "$(INPUT)"

manifest-validate:
	@./scripts/validate-vdd-manifest.sh "$(MANIFEST)"

report-closeout: report-validate
	@echo "Closeout validated:"
	@echo "  Report: $(INPUT)"
	@echo "  Manifest: $(MANIFEST)"

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
