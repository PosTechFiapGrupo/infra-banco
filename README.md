# Infraestrutura - Banco de Dados (RDS MySQL)

Este repositório contém código Terraform para provisionar infraestrutura de banco de dados AWS RDS MySQL.

## Recursos Provisionados

- **VPC** com sub-redes públicas e privadas
- **Instância RDS MySQL 8.0** com suporte Multi-AZ
- **Grupo de Parâmetros DB** para ajuste de performance do MySQL
- **Grupo de Sub-redes DB** para posicionamento do RDS
- **Security Groups** para controle de acesso ao RDS
- **Secrets Manager** para credenciais do banco de dados:
  - Credenciais master
  - Credenciais do usuário da aplicação
  - Credenciais do usuário de migração
  - Credenciais do usuário admin
- **Políticas IAM** para acesso aos secrets
- **Alarmes CloudWatch** para monitoramento:
  - Utilização de CPU
  - Conexões do banco de dados
  - Latência de leitura/escrita
  - Espaço de armazenamento livre
  - Memória disponível
  - IOPS de leitura/escrita
- **Tópico SNS** para alertas (opcional, apenas prod)

## Pré-requisitos

- Terraform >= 1.13.0
- AWS CLI configurado com credenciais apropriadas
- Bucket S3 para armazenamento de estado remoto
- Tabela DynamoDB para bloqueio de estado

## Uso

### 1. Configurar Backend

Edite `backend.tf` para configurar o backend de estado remoto:

```hcl
terraform {
  backend "s3" {
    bucket         = "your-terraform-state-bucket"
    key            = "infra-db/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}
```

### 2. Configurar Variáveis

Copie `terraform.tfvars.example` para `terraform.tfvars` e atualize os valores:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edite `terraform.tfvars` com seus valores específicos.

### 3. Inicializar Terraform

```bash
terraform init
```

### 4. Planejar Mudanças

```bash
terraform plan
```

### 5. Aplicar Infraestrutura

```bash
terraform apply
```

### 6. Revisar Outputs

Após aplicar, visualize os outputs:

```bash
terraform output
```

## Configuração

### Variáveis Obrigatórias

- `aws_region` - Região AWS para os recursos
- `environment` - Nome do ambiente (dev, staging, prod)
- `project_name` - Nome do projeto para nomenclatura de recursos

### Configuração do Banco de Dados

- `db_instance_class` - Classe da instância RDS (padrão: `db.t3.micro`)
- `db_allocated_storage` - Armazenamento inicial em GB (padrão: 20)
- `db_max_allocated_storage` - Armazenamento máximo para autoscaling (padrão: 100)
- `db_backup_retention_period` - Período de retenção de backup em dias (padrão: 7)
- `db_name` - Nome do banco de dados (padrão: `tech_challenge`)

### Configuração de Segurança

- `allowed_security_group_ids` - Lista de IDs de security groups permitidos para acessar o RDS
- `allowed_cidr_blocks` - Lista de blocos CIDR permitidos para acessar o RDS

**Nota**: Pelo menos um de `allowed_security_group_ids` ou `allowed_cidr_blocks` deve ser fornecido para acesso ao RDS.

### Configuração de Monitoramento

- `enable_monitoring` - Habilitar monitoramento aprimorado (padrão: `true`)
- `enable_performance_insights` - Habilitar Performance Insights (padrão: `true`)
- `alert_email` - Email para alertas CloudWatch (opcional, apenas prod)

## Outputs

Este módulo retorna os seguintes valores que podem ser referenciados por outros repositórios de infraestrutura:

- `rds_endpoint` - Endpoint RDS MySQL
- `rds_port` - Porta RDS MySQL (3306)
- `rds_database_name` - Nome do banco de dados
- `rds_instance_id` - Identificador da instância RDS
- `rds_security_group_id` - ID do security group do RDS
- `rds_master_secret_arn` - ARN do secret de credenciais master
- `rds_app_secret_arn` - ARN do secret de credenciais do usuário da aplicação
- `rds_migration_secret_arn` - ARN do secret de credenciais do usuário de migração
- `rds_admin_secret_arn` - ARN do secret de credenciais do usuário admin
- `vpc_id` - ID da VPC
- `private_subnet_ids` - IDs das sub-redes privadas
- `public_subnet_ids` - IDs das sub-redes públicas
- `app_secrets_read_policy_arn` - ARN da política IAM para acesso de leitura aos secrets da aplicação
- `migration_secrets_read_policy_arn` - ARN da política IAM para acesso de leitura aos secrets de migração

## Integração com Outros Repositórios

### Referenciando de infra-k8s

```hcl
# Em infra-k8s/terraform/main.tf
data "terraform_remote_state" "db" {
  backend = "s3"
  config = {
    bucket = "your-terraform-state-bucket"
    key    = "infra-db/terraform.tfstate"
    region = "us-east-1"
  }
}

# Usar outputs
locals {
  db_endpoint = data.terraform_remote_state.db.outputs.rds_endpoint
  db_port     = data.terraform_remote_state.db.outputs.rds_port
  db_secret_arn = data.terraform_remote_state.db.outputs.rds_app_secret_arn
}

# Permitir que o security group da aplicação acesse o RDS
resource "aws_security_group_rule" "app_to_rds" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.app.id
  security_group_id        = data.terraform_remote_state.db.outputs.rds_security_group_id
}
```

## Configuração de Usuários do Banco de Dados

Após o provisionamento, execute os scripts SQL em `db-scripts/` para criar usuários do banco de dados:

1. Conecte-se ao RDS usando as credenciais master do Secrets Manager
2. Execute os scripts em ordem:
   - `app_user.sql`
   - `migration_user.sql`
   - `admin_user.sql`

**Importante**: Substitua `CHANGE_ME_IN_SECRETS_MANAGER` pelas senhas reais do Secrets Manager.

## Notas de Segurança

1. **Senhas**: Todas as senhas são geradas pelo Terraform e armazenadas no Secrets Manager
2. **Controle de Acesso**: O security group do RDS permite acesso apenas de security groups ou blocos CIDR especificados
3. **Criptografia**: O armazenamento do RDS é criptografado em repouso
4. **Rede**: O RDS é implantado em sub-redes privadas sem acesso público
5. **Monitoramento**: Alarmes CloudWatch configurados para métricas-chave
6. **Backups**: Backups automatizados habilitados com retenção configurável

## Manutenção

### Atualizando Instância RDS

Para alterar a classe da instância ou armazenamento:

1. Atualize as variáveis em `terraform.tfvars`
2. Execute `terraform plan` para revisar as mudanças
3. Execute `terraform apply` para aplicar as mudanças

**Nota**: Algumas mudanças (como classe da instância) podem causar indisponibilidade.

### Rotacionando Senhas

As senhas são armazenadas no Secrets Manager. Para rotacionar:

1. Atualize a senha no Secrets Manager
2. Atualize a senha do usuário do banco de dados usando SQL
3. Atualize a configuração da aplicação para usar a nova senha

## Solução de Problemas

### Não é Possível Conectar ao RDS

1. Verifique se as regras do security group permitem acesso do seu IP/security group
2. Verifique a configuração da VPC e sub-redes
3. Verifique se a instância RDS está no estado `available`
4. Verifique os logs do CloudWatch para erros de conexão

### Alto Uso de CPU/Memória

1. Revise as métricas do CloudWatch
2. Verifique o log de consultas lentas
3. Considere atualizar a classe da instância
4. Revise os padrões de consulta da aplicação

## Otimização de Custos

- Use `db.t3.micro` para desenvolvimento
- Habilite autoscaling de armazenamento para evitar superprovisionamento
- Defina períodos de retenção de backup apropriados
- Use Multi-AZ apenas para ambientes de produção
- Monitore recursos não utilizados e faça limpeza

## Suporte

Para problemas ou dúvidas, consulte:
- [Documentação AWS RDS](https://docs.aws.amazon.com/rds/)
- [Documentação do Provider AWS do Terraform](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
