DEPLOY_CLASSES = \
  WhereClauseInterface \
  AbstractWhereClause \
  ObjectWhereClause \
  ObjectWhereClause_T \
  ListWhereClause \
  ListWhereClause_T \
  SubQueryWhereClause \
  SubQueryWhereClause_T \
  WhereClauseFactory \
  WhereClauseFactory_T \
	ParentClause \
	ParentClause_T \
	OrderByClause \
	OrderByClause_T \
  Query \
	Query_T \
  RepositoryInterface \
  MockRepository \
	MockRepository_T \
  Repository \
	Repository_T \
	EvaluatorInterface \
	Evaluator \
	Evaluator_T \
	MockEvaluator \
	MockEvaluator_T \
  FieldStructure \
  FieldStructure_T \
  AbstractEvaluator

.PHONY: deploy clean redeploy

# 1. delete classes
# bulk delete can not continue when error occured.
# so, we need to delete classes one by one.
uninstall:
	@echo "Cleaning classes from org..."
	@for class in $(DEPLOY_CLASSES); do \
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

# 4. redeploy（clean → restore → deploy）
redeploy: uninstall restore install