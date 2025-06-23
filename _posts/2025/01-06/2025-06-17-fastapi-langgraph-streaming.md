---
layout: post
title: FastAPI - LangGraph(Chain) Streaming
author: jblim0125
date: 2025-06-17
category: 2025
tags: [FastAPI, LangGraph, Streaming]
---

## FastAPI + LangGraph + OpenAI 스트리밍 응답 구현하기

사용자 요청을 LangGraph 기반의 조건 분기 그래프와 함께 OpenAI에 전달하고, FastAPI로 실시간 스트리밍 응답을 제공하는 방법을 소개합니다.

## 목표

- `FastAPI` 서버에서 OpenAI 모델과 통신
- `LangGraph`로 다중 노드, 조건 분기 그래프 구성
- OpenAI의 ChatCompletion API를 `streaming`으로 처리
- 예외 처리 및 구조화된 응답 제공

## 필요한 라이브러리 설치

```bash
pip install fastapi uvicorn langgraph openai sse-starlette
```

## 디렉토리 구조

```text
project/
│
├─ main.py              # FastAPI 서버 진입점
├─ graph.py             # LangGraph 정의
└─ utils.py             # (선택) 예외 처리 유틸
```

## LangGraph 정의 (graph.py)

```python
from langgraph.graph import StateGraph, END
from typing import TypedDict, Literal
from openai import OpenAI
import asyncio

client = OpenAI()

class State(TypedDict):
    input: str
    stage: Literal["initial", "processing", "done"]
    result: str

async def node_1(state: State) -> State:
    prompt = f"사용자 입력: {state['input']}\n적절한 응답을 생성하세요."
    stream = client.chat.completions.create(
        model="gpt-4",
        messages=[{"role": "user", "content": prompt}],
        stream=True,
    )

    result = ""
    async for chunk in stream:
        if (delta := chunk.choices[0].delta.content):
            result += delta
            yield {"result": result, "stage": "processing"}

    yield {"result": result, "stage": "done"}

def route(state: State):
    return END if state["stage"] == "done" else "node_1"

def create_graph():
    builder = StateGraph(State)
    builder.add_node("node_1", node_1)
    builder.set_entry_point("node_1")
    builder.add_conditional_edges("node_1", route)
    return builder.compile()
```

## FastAPI 서버 (main.py)

```python
from fastapi import FastAPI, Request
from sse_starlette.sse import EventSourceResponse
from graph import create_graph

app = FastAPI()
graph = create_graph()

@app.get("/")
async def root():
    return {"message": "LangGraph Streaming API"}

@app.post("/chat")
async def chat(request: Request):
    body = await request.json()
    user_input = body.get("input")

    async def event_generator():
        state = {"input": user_input, "stage": "initial", "result": ""}
        async for update in graph.stream(state):
            yield {"event": "message", "data": update["result"]}

    return EventSourceResponse(event_generator())
```

## 예외 처리 (utils.py, 선택)

```python
from fastapi.responses import JSONResponse
from fastapi import Request

async def exception_handler(request: Request, exc: Exception):
    return JSONResponse(
        status_code=500,
        content={"message": f"서버 에러 발생: {str(exc)}"},
    )
```

FastAPI에 등록:

```python
app.add_exception_handler(Exception, exception_handler)
```

## 실행 방법

```sh
uvicorn main:app --reload
```

## 테스트 예시 (cURL)

```sh
curl -X POST http://localhost:8000/chat \
    -H "Content-Type: application/json" \
    -d '{"input": "LangGraph는 무엇인가요?"}'
```

응답은 text/event-stream 형식으로 반환되며, 실시간 스트리밍 결과를 확인할 수 있습니다.
