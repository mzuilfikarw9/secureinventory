from collections.abc import Iterator
from typing import Any

import pytest
from fastapi.testclient import TestClient

from app.main import app, products

client = TestClient(app)

PRODUCT: dict[str, Any] = {"id": 1, "name": "Widget", "quantity": 10, "price": "9.99"}


@pytest.fixture(autouse=True)
def clear_products() -> Iterator[None]:
    products.clear()
    yield
    products.clear()


def test_list_products_is_empty_initially() -> None:
    response = client.get("/products")

    assert response.status_code == 200
    assert response.json() == []


@pytest.mark.parametrize("price", ["9.99", 9.99])
def test_create_product_returns_201(price: Any) -> None:
    response = client.post("/products", json={**PRODUCT, "price": price})

    assert response.status_code == 201
    assert response.json() == PRODUCT


def test_created_product_is_listed() -> None:
    client.post("/products", json=PRODUCT)

    response = client.get("/products")

    assert response.status_code == 200
    assert response.json() == [PRODUCT]


def test_duplicate_id_returns_409_and_keeps_original() -> None:
    client.post("/products", json=PRODUCT)

    response = client.post("/products", json={**PRODUCT, "name": "Other"})

    assert response.status_code == 409
    assert response.json() == {"detail": "Product 1 already exists"}
    assert client.get("/products").json() == [PRODUCT]


@pytest.mark.parametrize(
    "overrides",
    [
        {"id": 0},
        {"id": "1"},
        {"name": "   "},
        {"quantity": -1},
        {"price": "1.999"},
        {"price": "-1"},
    ],
)
def test_invalid_product_returns_422(overrides: dict[str, Any]) -> None:
    response = client.post("/products", json={**PRODUCT, **overrides})

    assert response.status_code == 422
    assert response.json()["detail"][0]["loc"][0] == "body"
    assert products == {}


def test_missing_field_returns_422() -> None:
    body = {k: v for k, v in PRODUCT.items() if k != "price"}

    response = client.post("/products", json=body)

    assert response.status_code == 422
    assert products == {}


def test_malformed_json_returns_422() -> None:
    response = client.post(
        "/products", content="not json", headers={"Content-Type": "application/json"}
    )

    assert response.status_code == 422
    assert products == {}


def test_openapi_documents_post_request_body() -> None:
    operation = app.openapi()["paths"]["/products"]["post"]
    schema = operation["requestBody"]["content"]["application/json"]["schema"]

    assert operation["requestBody"]["required"] is True
    assert set(schema["required"]) == {"id", "name", "quantity", "price"}
