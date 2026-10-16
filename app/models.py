from decimal import Decimal

from pydantic import BaseModel, ConfigDict, Field


class Product(BaseModel):
    model_config = ConfigDict(strict=True, str_strip_whitespace=True)

    id: int = Field(ge=1)
    name: str = Field(min_length=1, max_length=100)
    quantity: int = Field(ge=0)
    price: Decimal = Field(ge=0, decimal_places=2)
