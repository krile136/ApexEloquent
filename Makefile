# Define a path to a dummy package.xml needed for destructive deploys.
# This file is used when only deleting components.
# You need to create this file yourself. It can be just:
# <?xml version="1.0" encoding="UTF-8"?><Package xmlns="http://soap.sforce.com/2006/04/metadata"><version>61.0</version></Package>
EMPTY_PACKAGE_XML = manifest/package-empty.xml

.PHONY: install uninstall reinstall test

# 1. install: Deploys all source code from the current directory.
install:
	@echo "Deploying all Apex classes from ApexEloquent directory..."
	@sf project deploy start --source-dir . --wait 10 || exit 1

# 2. uninstall: Deletes all classes from the org using a static 'uninstall.xml' manifest.
uninstall:
	@echo "Cleaning classes from org using static manifest..."
	@echo "Using destructive manifest: uninstall.xml"
	@sf project deploy start \
		--manifest $(EMPTY_PACKAGE_XML) \
		--post-destructive-changes manifest/uninstall.xml \
		--wait 10 || echo "Destructive deployment finished (some errors may be ignored)."

# 3. reinstall: A convenient target to first uninstall and then install the project.
reinstall: uninstall install

# 4. test: Runs ALL local Apex tests in the org.
test: install
	@echo "Running all local Apex tests..."
	@sf apex run test --test-level RunLocalTests --result-format human --code-coverage --wait 10
