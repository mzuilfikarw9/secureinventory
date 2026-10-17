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
