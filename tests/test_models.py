from decimal import Decimal
from typing import Any

import pytest
from pydantic import ValidationError

from app.models import Product

VALID: dict[str, Any] = {
    "id": 1,
    "name": "Widget",
    "quantity": 10,
    "price": Decimal("9.99"),
}


def make(**overrides: Any) -> Product:
    return Product(**{**VALID, **overrides})


def test_valid_product() -> None:
    product = make()

    assert product.id == 1
    assert product.name == "Widget"
    assert product.quantity == 10
    assert product.price == Decimal("9.99")


def test_name_is_trimmed() -> None:
    assert make(name="  Widget  ").name == "Widget"


def test_boundary_values_are_accepted() -> None:
    product = make(name="x" * 100, quantity=0, price=Decimal("0"))

    assert len(product.name) == 100
    assert product.quantity == 0
    assert product.price == Decimal("0")


@pytest.mark.parametrize(
    ("field", "value"),
    [
        ("id", 0),
        ("id", -1),
        ("name", ""),
        ("name", "   "),
        ("name", "x" * 101),
        ("quantity", -1),
        ("price", Decimal("-0.01")),
        ("price", Decimal("1.999")),
        ("price", Decimal("NaN")),
    ],
)
def test_invalid_values_are_rejected(field: str, value: Any) -> None:
    with pytest.raises(ValidationError):
        make(**{field: value})


@pytest.mark.parametrize(
    ("field", "value"),
    [
        ("id", "1"),
        ("id", True),
        ("id", 1.0),
        ("name", 123),
        ("quantity", "10"),
        ("quantity", False),
        ("price", 9.99),
        ("price", "9.99"),
    ],
)
def test_wrong_types_are_rejected(field: str, value: Any) -> None:
    with pytest.raises(ValidationError):
        make(**{field: value})


@pytest.mark.parametrize("field", ["id", "name", "quantity", "price"])
def test_missing_field_is_rejected(field: str) -> None:
    data = {k: v for k, v in VALID.items() if k != field}

    with pytest.raises(ValidationError):
        Product(**data)
