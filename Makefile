.PHONY: report-pdf report-gist report-package

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

report-package: report-pdf report-gist
	@echo "Report package generated:"
	@echo "  PDF: $(OUTPUT)"
	@echo "  Gist: $(GIST_OUTPUT)"
