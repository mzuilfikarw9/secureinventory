# SecureInventory

A FastAPI inventory service. Currently provides a health check and in-memory product endpoints.
Products are kept in memory and are lost when the server restarts.

## Setup

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements-dev.txt
```

## Run

```bash
uvicorn app.main:app --reload
```

Then check the health endpoint:

```bash
curl http://127.0.0.1:8000/health
# {"status":"ok"}
```

Create and list products:

```bash
curl -X POST http://127.0.0.1:8000/products \
  -H "Content-Type: application/json" \
  -d '{"id": 1, "name": "Widget", "quantity": 10, "price": "9.99"}'
# 201 Created; 409 if the id already exists; 422 if the input is invalid

curl http://127.0.0.1:8000/products
# [{"id":1,"name":"Widget","quantity":10,"price":"9.99"}]
```

## Test

```bash
pytest
```

## Docker

Build the image and run it as a non-root user:

```bash
docker build -t secureinventory:local .
docker run --rm -d --name secureinventory -p 8000:8000 secureinventory:local
```

Verify the running container:

```bash
docker exec secureinventory id
# uid=10001(app) gid=... groups=...

curl -i http://127.0.0.1:8000/health
# 200 {"status":"ok"}

curl -i http://127.0.0.1:8000/products
# 200 []

curl -i -X POST http://127.0.0.1:8000/products \
  -H "Content-Type: application/json" \
  -d '{"id": 1, "name": "Widget", "quantity": 10, "price": "9.99"}'
# 201 (repeating the same request returns 409)

curl -i http://127.0.0.1:8000/products
# 200 [{"id":1,"name":"Widget","quantity":10,"price":"9.99"}]
```

Stop the container (products are lost, as they are kept in memory):

```bash
docker stop secureinventory
```

## Secret scanning

Scan the Git history (all branches) and the working tree with
[Gitleaks](https://github.com/gitleaks/gitleaks) using its default rules.
Requires Docker; the pinned Gitleaks image runs with the repository mounted
read-only and no network access.

```bash
./scripts/secret-scan.sh
```

| Exit code | Meaning |
|---|---|
| 0 | No findings |
| 1 | Potential secrets found |
| 2 | Scan error |

Secret values are redacted in the output. JSON reports are written to
`reports/gitleaks/` (ignored by Git). Rule settings are in `.gitleaks.toml`.

Handling findings:

- **Real secret:** treat it as compromised. Revoke or rotate it first, then
  remove it from the code and load it from the environment or a secret
  manager. Rewriting Git history does not make a pushed secret safe again.
- **False positive:** confirm it without copying the value anywhere, then
  suppress only that finding, either by adding its `Fingerprint` from the
  report to `.gitleaksignore` with a comment, or with a `gitleaks:allow`
  comment on the line. Do not disable rules or exclude whole directories.
