from fastapi import FastAPI, HTTPException, Request, status
from fastapi.exceptions import RequestValidationError
from pydantic import ValidationError

from app.models import Product

app = FastAPI(title="SecureInventory")

products: dict[int, Product] = {}


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}


@app.get("/products")
def list_products() -> list[Product]:
    return list(products.values())


# The body is validated from raw JSON because Product is strict: FastAPI's
# default body parsing passes Python values, which strict Decimal rejects.
@app.post(
    "/products",
    status_code=status.HTTP_201_CREATED,
    openapi_extra={
        "requestBody": {
            "required": True,
            "content": {"application/json": {"schema": Product.model_json_schema()}},
        }
    },
)
async def create_product(request: Request) -> Product:
    try:
        product = Product.model_validate_json(await request.body())
    except ValidationError as exc:
        raise RequestValidationError(
            [{**err, "loc": ("body", *err["loc"])} for err in exc.errors(include_url=False)]
        ) from exc

    if product.id in products:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"Product {product.id} already exists",
        )

    products[product.id] = product
    return product
