# Makefile (raiz)
# Requisitos:
# - terraform, awscli, python3
# - Para db-apply-eks: kubectl configurado apontando pro cluster na mesma VPC do RDS

TFVARS        ?= terraform.tfvars
BOOTSTRAP_DIR ?= bootstrap
NS            ?= grupo19

# lê do terraform.tfvars (assume valores entre aspas: key = "value")
PROJECT_NAME := $(shell sed -nE 's/^\s*project_name\s*=\s*"([^"]+)".*$$/\1/p' $(TFVARS) | head -n1)
ENVIRONMENT  := $(shell sed -nE 's/^\s*environment\s*=\s*"([^"]+)".*$$/\1/p' $(TFVARS) | head -n1)
AWS_REGION   := $(shell sed -nE 's/^\s*aws_region\s*=\s*"([^"]+)".*$$/\1/p' $(TFVARS) | head -n1)

# arquivo tfvars "mínimo" para o bootstrap (evita warnings de variáveis não declaradas)
BOOTSTRAP_TFVARS := $(BOOTSTRAP_DIR)/bootstrap.auto.tfvars

# pasta temporária p/ sql renderizado
DB_TMP_DIR := .tmp/db
DB_ENV_FILE := $(DB_TMP_DIR)/db.env
DB_SQL_APP := $(DB_TMP_DIR)/app_user.sql
DB_SQL_MIG := $(DB_TMP_DIR)/migration_user.sql
DB_SQL_ADM := $(DB_TMP_DIR)/admin_user.sql

.PHONY: bootstrap-vars bootstrap bootstrap-output init plan apply all clean-bootstrap \
        db-env db-sql db-apply-local db-apply-eks db-clean

bootstrap-vars:
	@test -f "$(TFVARS)" || (echo "ERROR: $(TFVARS) não encontrado na raiz." && exit 1)
	@test -n "$(PROJECT_NAME)" || (echo "ERROR: project_name não encontrado em $(TFVARS) (precisa estar entre aspas)." && exit 1)
	@test -n "$(ENVIRONMENT)"  || (echo "ERROR: environment não encontrado em $(TFVARS) (precisa estar entre aspas)." && exit 1)
	@test -n "$(AWS_REGION)"   || (echo "ERROR: aws_region não encontrado em $(TFVARS) (precisa estar entre aspas)." && exit 1)
	@mkdir -p "$(BOOTSTRAP_DIR)"
	@printf 'project_name = "%s"\nenvironment  = "%s"\naws_region   = "%s"\n' \
	  "$(PROJECT_NAME)" "$(ENVIRONMENT)" "$(AWS_REGION)" > "$(BOOTSTRAP_TFVARS)"
	@echo "bootstrap vars geradas em: $(BOOTSTRAP_TFVARS)"

bootstrap: bootstrap-vars
	cd "$(BOOTSTRAP_DIR)" && terraform init
	cd "$(BOOTSTRAP_DIR)" && terraform apply -auto-approve -var-file=bootstrap.auto.tfvars

bootstrap-output:
	@cd "$(BOOTSTRAP_DIR)" && terraform output -raw terraform_state_bucket

init:
	rm -rf .terraform
	@BUCKET="$$(cd "$(BOOTSTRAP_DIR)" && terraform output -raw terraform_state_bucket 2>/dev/null)" ; \
	if [ -z "$$BUCKET" ]; then \
	  echo "ERROR: não consegui ler terraform_state_bucket do bootstrap."; \
	  echo "Dica: rode 'make bootstrap' primeiro."; \
	  exit 1; \
	fi ; \
	echo "Usando bucket=$$BUCKET region=$(AWS_REGION) key=infra/$(NS)/terraform.tfstate" ; \
	terraform init -reconfigure \
	  -backend-config="bucket=$$BUCKET" \
	  -backend-config="key=infra/$(NS)/terraform.tfstate" \
	  -backend-config="region=$(AWS_REGION)" \
	  -backend-config="encrypt=true" \
	  -backend-config="use_lockfile=true"


plan:
	terraform plan -var-file="$(TFVARS)"

apply:
	terraform apply -var-file="$(TFVARS)"

all: bootstrap init plan apply

clean-bootstrap:
	rm -f "$(BOOTSTRAP_TFVARS)"

# -----------------------------
# DB (usuários/scripts)
# -----------------------------
# IMPORTANTE:
# - pressupõe que o terraform root tem outputs:
#   rds_master_secret_arn, rds_app_secret_arn, rds_migration_secret_arn, rds_admin_secret_arn
# - e que existem scripts em db-scripts/:
#   app_user.sql, migration_user.sql, admin_user.sql
#   contendo o placeholder: CHANGE_ME_IN_SECRETS_MANAGER
#   e o nome do DB (ex: tech_challenge) que pode ser substituído

db-env:
	@mkdir -p "$(DB_TMP_DIR)"
	@MASTER_ARN="$$(terraform output -raw rds_master_secret_arn 2>/dev/null)" ; \
	APP_ARN="$$(terraform output -raw rds_app_secret_arn 2>/dev/null)" ; \
	MIG_ARN="$$(terraform output -raw rds_migration_secret_arn 2>/dev/null)" ; \
	ADM_ARN="$$(terraform output -raw rds_admin_secret_arn 2>/dev/null)" ; \
	if [ -z "$$MASTER_ARN" ] || [ -z "$$APP_ARN" ] || [ -z "$$MIG_ARN" ] || [ -z "$$ADM_ARN" ]; then \
	  echo "ERROR: outputs de secrets ARNs não encontrados. Você já rodou 'make apply' na infra?"; \
	  echo "Dica: rode 'terraform output' e confira se existem rds_*_secret_arn."; \
	  exit 1; \
	fi ; \
	master_json="$$(aws secretsmanager get-secret-value --secret-id "$$MASTER_ARN" --query SecretString --output text --region "$(AWS_REGION)")" ; \
	app_json="$$(aws secretsmanager get-secret-value --secret-id "$$APP_ARN" --query SecretString --output text --region "$(AWS_REGION)")" ; \
	mig_json="$$(aws secretsmanager get-secret-value --secret-id "$$MIG_ARN" --query SecretString --output text --region "$(AWS_REGION)")" ; \
	adm_json="$$(aws secretsmanager get-secret-value --secret-id "$$ADM_ARN" --query SecretString --output text --region "$(AWS_REGION)")" ; \
	py='import json,sys; print(json.loads(sys.stdin.read())[sys.argv[1]])' ; \
	DB_HOST="$$(echo "$$master_json" | python3 -c "$$py" host)" ; \
	DB_PORT="$$(echo "$$master_json" | python3 -c "$$py" port)" ; \
	DB_NAME="$$(echo "$$master_json" | python3 -c "$$py" dbname)" ; \
	MASTER_USER="$$(echo "$$master_json" | python3 -c "$$py" username)" ; \
	MASTER_PASS="$$(echo "$$master_json" | python3 -c "$$py" password)" ; \
	APP_PASS="$$(echo "$$app_json" | python3 -c "$$py" password)" ; \
	MIG_PASS="$$(echo "$$mig_json" | python3 -c "$$py" password)" ; \
	ADM_PASS="$$(echo "$$adm_json" | python3 -c "$$py" password)" ; \
	printf 'DB_HOST=%s\nDB_PORT=%s\nDB_NAME=%s\nMASTER_USER=%s\nMASTER_PASS=%s\nAPP_PASS=%s\nMIG_PASS=%s\nADM_PASS=%s\n' \
	  "$$DB_HOST" "$$DB_PORT" "$$DB_NAME" "$$MASTER_USER" "$$MASTER_PASS" "$$APP_PASS" "$$MIG_PASS" "$$ADM_PASS" > "$(DB_ENV_FILE)" ; \
	echo "✅ Gerado: $(DB_ENV_FILE)"

db-sql: db-env
	@test -f "db-scripts/app_user.sql" || (echo "ERROR: db-scripts/app_user.sql não encontrado" && exit 1)
	@test -f "db-scripts/migration_user.sql" || (echo "ERROR: db-scripts/migration_user.sql não encontrado" && exit 1)
	@test -f "db-scripts/admin_user.sql" || (echo "ERROR: db-scripts/admin_user.sql não encontrado" && exit 1)
	@. "$(DB_ENV_FILE)" ; \
	sed "s/CHANGE_ME_IN_SECRETS_MANAGER/$${APP_PASS}/g; s/tech_challenge/$${DB_NAME}/g" db-scripts/app_user.sql > "$(DB_SQL_APP)" ; \
	sed "s/CHANGE_ME_IN_SECRETS_MANAGER/$${MIG_PASS}/g; s/tech_challenge/$${DB_NAME}/g" db-scripts/migration_user.sql > "$(DB_SQL_MIG)" ; \
	sed "s/CHANGE_ME_IN_SECRETS_MANAGER/$${ADM_PASS}/g; s/tech_challenge/$${DB_NAME}/g" db-scripts/admin_user.sql > "$(DB_SQL_ADM)" ; \
	echo "✅ SQL renderizado em $(DB_TMP_DIR)/"

# Tenta aplicar localmente (SÓ funciona se seu host tiver rota pra VPC do RDS)
db-apply-local: db-sql
	@command -v mysql >/dev/null 2>&1 || (echo "ERROR: mysql client não instalado (instale mysql-client)" && exit 1)
	@. "$(DB_ENV_FILE)" ; \
	echo "⚠️ Tentando conectar LOCAL em $$DB_HOST:$$DB_PORT/$$DB_NAME (vai falhar se o RDS for privado)..." ; \
	MYSQL_PWD="$$MASTER_PASS" mysql -h "$$DB_HOST" -P "$$DB_PORT" -u "$$MASTER_USER" "$$DB_NAME" < "$(DB_SQL_APP)" ; \
	MYSQL_PWD="$$MASTER_PASS" mysql -h "$$DB_HOST" -P "$$DB_PORT" -u "$$MASTER_USER" "$$DB_NAME" < "$(DB_SQL_MIG)" ; \
	MYSQL_PWD="$$MASTER_PASS" mysql -h "$$DB_HOST" -P "$$DB_PORT" -u "$$MASTER_USER" "$$DB_NAME" < "$(DB_SQL_ADM)" ; \
	echo "✅ Usuários aplicados (local)."

# Aplica via Pod no EKS (recomendado p/ RDS privado)
db-apply-eks: db-sql
	@command -v kubectl >/dev/null 2>&1 || (echo "ERROR: kubectl não encontrado" && exit 1)
	@. "$(DB_ENV_FILE)" ; \
	echo "Subindo pod temporário mysql-client e aplicando SQL via EKS..." ; \
	kubectl -n "$(NS)" delete pod db-mysql-client --ignore-not-found=true >/dev/null 2>&1 || true ; \
	kubectl -n "$(NS)" run db-mysql-client --image=mysql:8.0 --restart=Never --command -- sleep 3600 ; \
	kubectl -n "$(NS)" wait --for=condition=Ready pod/db-mysql-client --timeout=180s ; \
	kubectl -n "$(NS)" cp "$(DB_SQL_APP)" db-mysql-client:/tmp/app_user.sql ; \
	kubectl -n "$(NS)" cp "$(DB_SQL_MIG)" db-mysql-client:/tmp/migration_user.sql ; \
	kubectl -n "$(NS)" cp "$(DB_SQL_ADM)" db-mysql-client:/tmp/admin_user.sql ; \
	kubectl -n "$(NS)" exec db-mysql-client -- sh -lc 'MYSQL_PWD="'"$$MASTER_PASS"'" mysql -h "'"$$DB_HOST"'" -P "'"$$DB_PORT"'" -u "'"$$MASTER_USER"'" "'"$$DB_NAME"'" < /tmp/app_user.sql' ; \
	kubectl -n "$(NS)" exec db-mysql-client -- sh -lc 'MYSQL_PWD="'"$$MASTER_PASS"'" mysql -h "'"$$DB_HOST"'" -P "'"$$DB_PORT"'" -u "'"$$MASTER_USER"'" "'"$$DB_NAME"'" < /tmp/migration_user.sql' ; \
	kubectl -n "$(NS)" exec db-mysql-client -- sh -lc 'MYSQL_PWD="'"$$MASTER_PASS"'" mysql -h "'"$$DB_HOST"'" -P "'"$$DB_PORT"'" -u "'"$$MASTER_USER"'" "'"$$DB_NAME"'" < /tmp/admin_user.sql' ; \
	echo "✅ Usuários aplicados via EKS."; \
	kubectl -n "$(NS)" delete pod db-mysql-client --ignore-not-found=true >/dev/null 2>&1 || true

db-clean:
	rm -rf "$(DB_TMP_DIR)"
