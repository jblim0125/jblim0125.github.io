---
layout: post
title: LangGraph Tutorials(Tool And Route)
author: jblim0125
date: 2025-05-12
category: 2025
tags: [LangGraph]
---

## 개요

LangGraph 를 이용해 사용자의 질문에 따라 LLM과 외부 리소스(Tool)을 사용하는 아주 간단한 내용을 알아보겠습니다.

## 설명

LangGraph 에서 노드와 엣지를 이용해 분기를 통해 보다 많은 작업을 할 수 있도록 한다는 내용은 앞서 알아보았습니다.
여기서 분기를 선택하는 부분 역시 LLM을 이용하고 노드에서의 작업도 LLM에 의해 동작되도록 하는 방법을 알아볼 것 입니다.

![alt text](/assets/images/langgraph/leason02/router01.png)

## 소스 코드

우선 코드를 먼저 살펴보겠습니다.

```python
import os
from dotenv import load_dotenv
from pathlib import Path
from langchain_openai import ChatOpenAI
from IPython.display import Image, display
from langgraph.graph import StateGraph, START, END
from langgraph.graph import MessagesState
from langgraph.prebuilt import ToolNode
from langgraph.prebuilt import tools_condition
from langchain_core.messages import HumanMessage

# LLM 이용을 위해 OpenAI 의 API 키를 입력으로 받습니다.
def _set_env(var: str):
    if not os.environ.get(var):
        os.environ[var] = getpass.getpass(f"{var}: ")

_set_env("OPENAI_API_KEY")

# OpenAI Chat 클라이언트 초기화
llm = ChatOpenAI(model="gpt-4o")

# 곱하기를 처리하는 도구(Function) 정의
def multiply(a: int, b: int) -> int:
    """Multiply a and b.

    Args:
        a: first int
        b: second int
    """
    return a * b

# LLM 에 곱하기 툴을 바인드(연결)합니다.
llm_with_tools = llm.bind_tools([multiply])

# 메시지를 곱하기 툴이 바인드되어 있는 LLM을 호출하는 노드 선언
def tool_calling_llm(state: MessagesState):
    return {"messages": [llm_with_tools.invoke(state["messages"])]}

# 메시지를 이용하는 상태 그래프를 정의합니다.
builder = StateGraph(MessagesState)

# 그래프에 노드를 추가
builder.add_node("tool_calling_llm", tool_calling_llm)
builder.add_node("tools", ToolNode([multiply]))

# 그래프 상 노드 연결
builder.add_edge(START, "tool_calling_llm")
builder.add_conditional_edges(
    "tool_calling_llm",
    # If the latest message (result) from assistant is a tool call -> tools_condition routes to tools
    # If the latest message (result) from assistant is a not a tool call -> tools_condition routes to END
    tools_condition,
)
builder.add_edge("tools", END)

# 그래프 빌드
graph = builder.compile()
graph.name = "RouterGraph"
```

위 그래프를 그림으로 나타내면 다음과 같습니다.

![router02.png](/assets/images/langgraph/leason02/router02.png)

## 실행

> Hello, what is 2 multiplied by 2?

```shell
================================ Human Message =================================

Hello, what is 2 multiplied by 2?
================================== Ai Message ==================================
Tool Calls:
  multiply (call_kunKvXnDZ5EI7TmhzG36Qy44)
 Call ID: call_kunKvXnDZ5EI7TmhzG36Qy44
  Args:
    a: 2
    b: 2
================================= Tool Message =================================
Name: multiply

4
```

사용자 메시지로 곱하기를 질문하였고, LLM은 도구(Tool[Multiply])를 호출(곱하기 노드)하라고 응답을 주었습니다.
(툴 아이디와 파라미터 정보(Args)를 포함하여 전달해 줌.)
`LangGraph`는 이 응답을 이용해 `ToolNode[Multiply]` 노드를 호출하고 사용자 요청에 응답하였습니다.

> tool 호출 기능을 사용해 보았어. 잘 되고 있어?

```shell
================================ Human Message =================================

LLM 과 Tool 사용해 보았는데 Tool 호출은 어떻게 되는거야?
================================== Ai Message ==================================

Tool 호출은 일반적으로 주어진 작업을 수행하기 위해 외부 기능을 사용하는 과정입니다. 
주어진 도구의 명세에 따라 필요한 입력값을 제공하면 그에 따른 출력을 받게 됩니다
...
...
```

---

## 결론

LangGraph에서 ToolNode를 선언하고 도구(툴)를 바인딩할 때, 어떤 툴을 선택할지는 주로 개발자(혹은 애플리케이션 설계자)가 정하지만, 그 선택을 LLM이 자동으로 하도록 구성할 수도 있습니다.

### 툴 선택 기준은 누가 정하는가?

1. 개발자가 미리 정해놓은 툴 세트

    LangGraph에서 ToolNode를 만들 때, 사용 가능한 툴 목록을 정의하고 해당 툴들을 LLM이 사용할 수 있게 등록합니다.
    이때 툴의 정의(이름, 설명, 인자 등)는 개발자가 작성하며, 예를 들면 다음과 같은 형태입니다:

    ```python
    tools = [
        Tool(
            name="search_weather",
            func=search_weather_function,
            description="현재 위치 기반으로 날씨를 검색합니다.",
        ),
        Tool(
            name="calculate_distance",
            func=calculate_distance_function,
            description="두 지점 간의 거리를 계산합니다.",
        )
    ]
    ```

2. LLM이 상황에 따라 툴을 선택함

    LangGraph는 일반적으로 `OpenAI`의 `function calling` 또는 `tool calling` 기능을 사용합니다.
    이때 LLM은 주어진 질문이나 명령에 따라 어떤 툴이 가장 적절한지를 판단해 호출합니다.

    이를 가능하게 하려면 툴의 이름과 설명이 충분히 명확하고, LLM이 툴의 기능을 이해할 수 있도록 설명이 잘 전달되어야 합니다.

    즉:
    - 개발자: 어떤 툴들을 제공할지 결정
    - LLM: 주어진 입력에 따라 어떤 툴을 사용할지 결정

### 툴 정보는 어떻게 전달되는가?

LLM이 툴을 선택하려면 툴에 대한 정보가 내부적으로 LLM에게 전달되어야 합니다.
LangChain이나 LangGraph에서는 다음과 같은 흐름이 일반적입니다:

1. 툴의 스펙 정의
   이름, 설명, 입력 파라미터 (JSON Schema 형식 등)
2. LLM에게 전달
   OpenAI나 Anthropic과 같은 LLM에게 tool_choice=auto 또는 function_call="auto" 옵션을 설정하여, 툴 설명과 함께 프롬프트가 전달됩니다.
3. LLM의 판단
   입력된 사용자 요청과 툴 설명을 바탕으로, 어떤 툴을 사용할지 선택

따라서 툴 정보를 LLM이 인식할 수 있도록 구조화해서 보내는 것이 매우 중요합니다.

### 예시 시나리오

```python
llm_with_tools = ChatOpenAI(
    model="gpt-4",
    tools=tools,  # 툴 목록 등록(서울 날씨 정보를 조합하여 제공하는 도구, 강릉 날씨 정보를 조합하여 제공하는 도구, ..)
    tool_choice="auto"  # LLM이 자동으로 선택
)
```

사용자가 “오늘 서울 날씨 어때?“라고 입력하면 LLM은 "search_weather" 툴이 날씨 관련이므로 적절하다고 판단하고 자동으로 호출합니다.

### 정리

| 역할          | 주체                 | 설명                                   |
| ------------- | -------------------- | -------------------------------------- |
| 툴 정의       | 개발자               | 어떤 툴을 만들고, 어떤 기능을 제공할지 |
| 툴 선택(실행) | LLM (자동 선택)      | 사용자 입력과 툴 설명 기반으로 툴 선택 |
| 툴 정보 제공  | LangGraph/프레임워크 | 툴의 기능, 파라미터 등을 LLM에게 전달  |
