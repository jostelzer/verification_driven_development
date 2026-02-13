.PHONY: report-validate report-brief report-closeout

INPUT ?= verification-driven-development/references/report-template.md
STAMP ?= $(shell date +%Y%m%d-%H%M%S)

report-brief:
	@./scripts/render-verification-brief.sh "$(INPUT)"

report-validate:
	@./scripts/validate-vdd-report.sh "$(INPUT)"

report-closeout: report-validate
	@echo "Closeout validated:"
	@echo "  Report: $(INPUT)"
