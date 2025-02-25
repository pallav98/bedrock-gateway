from typing import Annotated
from fastapi import APIRouter, Depends, Body
from src.api.database.rds_utils import create_or_get_user, save_request, save_response
from src.api.models.bedrock import get_embeddings_model
from src.api.schema import EmbeddingsRequest, EmbeddingsResponse
from src.api.setting import DEFAULT_EMBEDDING_MODEL

router = APIRouter(
    prefix="/embeddings",
    dependencies=[Depends(api_key_auth)],
)

@router.post("", response_model=EmbeddingsResponse)
async def embeddings(
        embeddings_request: Annotated[
            EmbeddingsRequest,
            Body(
                examples=[
                    {
                        "model": "cohere.embed-multilingual-v3",
                        "input": [
                            "Your text string goes here"
                        ],
                    }
                ],
            ),
        ],
):
    if embeddings_request.model.lower().startswith("text-embedding-"):
        embeddings_request.model = DEFAULT_EMBEDDING_MODEL

    # Create or get a bogus user
    user = create_or_get_user("bogus_user")

    # Save the request
    request = save_request(user["id"], embeddings_request.model_dump())

    # Process the request
    model = get_embeddings_model(embeddings_request.model)
    embeddings_response = model.embed(embeddings_request)

    # Save the response
    save_response(request["id"], embeddings_response.model_dump())

    return embeddings_response
