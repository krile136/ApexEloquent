# List of all Apex classes in the project for the uninstall command.
# Alphabetized for readability.
CLASSES = \
    AbstractAggregateClause \
    AbstractConditionClause \
    AbstractEntry \
    AverageClause \
    CountClause \
    CountDistinctClause \
    Eloquent \
    EloquentTest \
    Entry \
    EntryTest \
    EqualConditionClause \
    EqualConditionClauseTest \
    ExcludeConditionClause \
    ExcludeConditionClauseTest \
    FieldStructure \
    FieldStructureTest \
    GreaterThanConditionClause \
    GreaterThanConditionClauseTest \
    GreaterThanOrEqualConditionClause \
    GreaterThanOrEqualConditionClauseTest \
    GroupByClause \
    IAggregateClause \
    IConditionClause \
    IEloquent \
    IEntry \
    InConditionClause \
    InConditionClauseTest \
    InSubQueryConditionClause \
    InSubQueryConditionClauseTest \
    IncludesConditionClause \
    IncludesConditionClauseTest \
    IsNotNullConditionClause \
    IsNotNullConditionClauseTest \
    IsNullConditionClause \
    IsNullConditionClauseTest \
    LessThanConditionClause \
    LessThanConditionClauseTest \
    LessThanOrEqualConditionClause \
    LessThanOrEqualConditionClauseTest \
    LikeConditionClause \
    LikeConditionClauseTest \
    MaxClause \
    MinClause \
    MockEloquent \
    MockEloquentTest \
    MockEntry \
    MockEntryTest \
    NotEqualConditionClause \
    NotEqualConditionClauseTest \
    NotInConditionClause \
    NotInConditionClauseTest \
    NotInSubQueryConditionClause \
    NotInSubQueryConditionClauseTest \
    NotLikeConditionClause \
    NotLikeConditionClauseTest \
    Scribe \
    ScribeTest \
    SumClause

# Filter the CLASSES variable to get only the test classes (those ending with "Test").
TEST_CLASSES = $(filter %Test,$(CLASSES))

# Helper variable to convert spaces to commas.
comma := ,
empty :=
space := $(empty) $(empty)
TEST_CLASSES_COMMA_SEPARATED = $(subst $(space),$(comma),$(TEST_CLASSES))

.PHONY: deploy clean redeploy test

# 1. delete classes
# bulk delete can not continue when error occured.
# so, we need to delete classes one by one.
uninstall:
	@echo "Cleaning classes from org..."
	@for class in $(CLASSES); do \
		echo "Deleting ApexClass:$$class"; \
		sf project delete source --metadata ApexClass:$$class || echo "Skip: $$class not deleted"; \
		done

# 2. restore classes
# deleting classes make local classes disappear.
# so, we need to restore classes from git.
restore:
	@echo "Restoring deleted classes from git..."
	git checkout .

# 3. deploy classes
install:
	@echo "Deploying all Apex classes from ApexEloquent directory..."
	@sf project deploy start --source-dir . --wait 10 || exit 1

# 4. test classes
# Runs all tests defined in the TEST_CLASSES variable.
test: install
	@echo "Running ApexEloquent tests..."
	@sf apex run test --class-names "$(TEST_CLASSES_COMMA_SEPARATED)" --result-format human --code-coverage --wait 10

# 5. redeploy（clean → restore → deploy）
redeploy: uninstall restore install
