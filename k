apiVersion: v1
kind: Secret
metadata:
  name: banking-secrets
  namespace: __NAMESPACE__
type: Opaque
stringData:
  POSTGRES_DB: bankingdb
  POSTGRES_USER: bankuser
  POSTGRES_PASSWORD: bankpass_dev
  DATABASE_URL: postgresql://bankuser:bankpass_dev@postgres-service:5432/bankingdb
  SPRING_DATASOURCE_URL: jdbc:postgresql://postgres-service:5432/bankingdb
  SPRING_DATASOURCE_USERNAME: bankuser
  SPRING_DATASOURCE_PASSWORD: bankpass_dev
  NODE_ENV: development