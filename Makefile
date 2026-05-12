.PHONY: help doctor split-kql validate package

help:
	@printf '%s\n' \
		'Targets:' \
		'  make doctor     Check local tooling and repo layout' \
		'  make split-kql  Split 05-detection/detection-pack.kql into generated/kql/*.kql' \
		'  make validate   Run deployability checks' \
		'  make package    Create generated/redteam-phase2.zip'

doctor:
	@scripts/doctor.sh

split-kql:
	@scripts/split-kql.sh

validate: doctor split-kql
	@printf '\n[ok] Deployment checks completed.\n'

package: validate
	@scripts/package.sh
