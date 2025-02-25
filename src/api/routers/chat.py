from typing import Annotated
from fastapi import APIRouter, Depends, Body
from fastapi.responses import StreamingResponse
from src.api.database.rds_utils import create_or_get_user, save_request, save_response
from src.api.models.bedrock import BedrockModel
from src.api.schema import ChatRequest, ChatResponse, ChatStreamResponse
from src.api.setting import DEFAULT_MODEL

router = APIRouter(
    prefix="/chat",
    dependencies=[Depends(api_key_auth)],
)

@router.post("/completions", response_model=ChatResponse | ChatStreamResponse, response_model_exclude_unset=True)
async def chat_completions(
        chat_request: Annotated[
            ChatRequest,
            Body(
                examples=[
                    {
                        "model": "anthropic.claude-3-sonnet-20240229-v1:0",
                        "messages": [
                            {"role": "system", "content": "You are a helpful assistant."},
                            {"role": "user", "content": "Hello!"},
                        ],
                    }
                ],
            ),
        ],
):
    if chat_request.model.lower().startswith("gpt-"):
        chat_request.model = DEFAULT_MODEL

    # Create or get a bogus user
    user = create_or_get_user("bogus_user")

    # Save the request
    request = save_request(user["id"], chat_request.model_dump())

    # Process the request
    model = BedrockModel()
    model.validate(chat_request)
    if chat_request.stream:
        # Handle streaming response
        async def generate():
            async for chunk in model.chat_stream(chat_request):
                yield chunk
            # Save the response
            save_response(request["id"], json.loads(chunk.decode("utf-8")))

        return StreamingResponse(
            content=generate(), media_type="text/event-stream"
        )
    else:
        # Handle synchronous response
        chat_response = model.chat(chat_request)
        # Save the response
        save_response(request["id"], chat_response.model_dump())
        return chat_response
