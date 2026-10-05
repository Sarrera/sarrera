# Maintenance, Backup & Updates

Procedures for operating, backing up, and updating the Sarrera platform.

---

## 1. Database Backups (PostgreSQL)

The `ai-postgres` container stores all team budgets, virtual keys, and Langfuse trace records.

### Creating a Full Backup
To dump both the `litellm` and `langfuse` databases to an SQL archive:

```bash
docker exec -t ai-postgres pg_dumpall -c -U platform_admin | gzip > "sarrera_backup_$(date +%Y%m%d_%H%M%S).sql.gz"
```

### Restoring from Backup
```bash
gunzip < sarrera_backup_YYYYMMDD_HHMMSS.sql.gz | docker exec -i ai-postgres psql -U platform_admin -d postgres
```

---

## 2. MinIO S3 Object Storage Backup

Trace attachments and large prompt payloads are stored in MinIO:

```bash
# Using Docker cp or AWS CLI/MinIO Client (mc)
docker run --rm \
  --network ai-backend \
  -v $(pwd)/minio_backup:/backup \
  amazon/aws-cli:latest \
  --endpoint-url http://ai-minio:9000 \
  s3 sync s3://langfuse /backup/
```

---

## 3. Updating Container Images

To upgrade services to newer releases:

1. Pull updated container images:
   ```bash
   docker compose pull
   ```
2. Restart the stack with recreated containers:
   ```bash
   docker compose up -d --remove-orphans
   ```
3. Run the smoke test suite to verify post-update integrity:
   ```bash
   ./scripts/smoke-test.sh
   ```

> [!WARNING]
> Keep `langfuse` pinned to major version `2` (`langfuse:2`). Langfuse v3 introduces a mandatory ClickHouse dependency that alters the database architecture.

---

## 4. Pruning Logs and Volumes

To inspect disk space used by Docker volumes:
```bash
docker system df -v
```

To clean up stopped scratch containers and dangling build caches without deleting named volumes:
```bash
docker system prune -f
```
