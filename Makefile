.PHONY: report-validate report-pdf report-gist report-package report-closeout

INPUT ?= verification-driven-development/references/report-template.md
STAMP ?= $(shell date +%Y%m%d-%H%M%S)
OUTPUT ?= .agent/runs/$(STAMP)/verification-report.pdf
GIST_OUTPUT ?= .agent/runs/$(STAMP)/verification-gist.md

report-pdf:
	@./scripts/render-report-pdf.sh "$(INPUT)" "$(OUTPUT)"
	@echo "PDF report generated at: $(OUTPUT)"

report-gist:
	@./scripts/render-gist.sh "$(INPUT)" "$(GIST_OUTPUT)"
	@echo "Gist generated at: $(GIST_OUTPUT)"

report-validate:
	@./scripts/validate-vdd-report.sh "$(INPUT)"

report-package: report-pdf report-gist
	@echo "Report package generated:"
	@echo "  PDF: $(OUTPUT)"
	@echo "  Gist: $(GIST_OUTPUT)"

report-closeout: report-validate report-pdf report-gist
	@echo "Closeout package generated (validated):"
	@echo "  PDF: $(OUTPUT)"
	@echo "  Gist: $(GIST_OUTPUT)"
