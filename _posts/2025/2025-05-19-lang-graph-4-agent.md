---
layout: post
title: LangGraph Tutorials(Agent)
author: jblim0125
date: 2025-05-19
category: 2025
tags: [LangGraph]
---

**리뷰**  

우리는 이전 시간에 라우터를 이용해 사용자 입력에 따라 도구(Tool)을 호출할지 여부를 위해 엣지를 이용해 보았습니다.

![router](/assets/images/langgraph/agent/image.png)

### 이번 장 목표

이제 이를 일반적인 에이전트 아키텍처로 확장하여 사용해 보겠습니다.
AI로 하여금 사용자의 질문에 대해 스스로 도구를 선택하고, 그 도구를 사용하여 답변을 생성하도록 하겠습니다.
추가로 메모리를 사용하여 이전 대화 내용을 기억하도록 하겠습니다.

![agent-1](/assets/images/langgraph/agent/image-1.png)

OPEN AI와 LangSmith 정보를 환경 변수로 설정합니다.

```python
import os, getpass

def _set_env(var: str):
    if not os.environ.get(var):
        os.environ[var] = getpass.getpass(f"{var}: ")

_set_env("OPENAI_API_KEY")
_set_env("LANGSMITH_API_KEY")
os.environ["LANGSMITH_TRACING"] = "true"
os.environ["LANGSMITH_PROJECT"] = "langchain-academy"
```

다수의 도구를 사용하기 위해서는 LangGraph의 `bind_tools` 메소드를 사용하여 LLM과 도구를 연결해야 합니다.

```python
from langchain_openai import ChatOpenAI

def multiply(a: int, b: int) -> int:
    """Multiply a and b.

    Args:
        a: first int
        b: second int
    """
    return a * b

# This will be a tool
def add(a: int, b: int) -> int:
    """Adds a and b.

    Args:
        a: first int
        b: second int
    """
    return a + b

def divide(a: int, b: int) -> float:
    """Divide a and b.

    Args:
        a: first int
        b: second int
    """
    return a / b

tools = [add, multiply, divide]
llm = ChatOpenAI(model="gpt-4o")
llm_with_tools = llm.bind_tools(tools)
```

이제 LLM 연결을 위한 노드를 작성합니다.

```python
from langgraph.graph import MessagesState
from langchain_core.messages import HumanMessage, SystemMessage

# System message
sys_msg = SystemMessage(content="You are a helpful assistant tasked with performing arithmetic on a set of inputs.")

# Node
def assistant(state: MessagesState):
   return {"messages": [llm_with_tools.invoke([sys_msg] + state["messages"])]}
```

노드 선언 및 엣지를 이용하여 노드를 연결하여 그래프를 작성합니다.
주목할 부분은 `assistant` 노드의 결과에 따라 도구를 호출할지 여부를 결정하는 엣지입니다. 

```python
from langgraph.graph import START, StateGraph
from langgraph.prebuilt import tools_condition, ToolNode
from IPython.display import Image, display

# Graph
builder = StateGraph(MessagesState)

# Define nodes: these do the work
builder.add_node("assistant", assistant)
builder.add_node("tools", ToolNode(tools))

# Define edges: these determine how the control flow moves
builder.add_edge(START, "assistant")
builder.add_conditional_edges(
    "assistant",
    # If the latest message (result) from assistant is a tool call -> tools_condition routes to tools
    # If the latest message (result) from assistant is a not a tool call -> tools_condition routes to END
    tools_condition,
)
# Add edges from tools to assistant
builder.add_edge("tools", "assistant")
react_graph = builder.compile()

# Show
display(Image(react_graph.get_graph(xray=True).draw_mermaid_png()))
```

![mermaid_png](/assets/images/langgraph/agent/image-2.png)

이제 그래프를 실행해 보겠습니다.

```python
messages = [HumanMessage(content="Add 3 and 4.")]
messages = react_graph.invoke({"messages": messages})
for m in messages['messages']:
    m.pretty_print()
```

**output**  

```text
================================ Human Message =================================

Add 3 and 4.
================================== Ai Message ==================================
Tool Calls:
  add (call_zZ4JPASfUinchT8wOqg9hCZO)
 Call ID: call_zZ4JPASfUinchT8wOqg9hCZO
  Args:
    a: 3
    b: 4
================================= Tool Message =================================
Name: add

7
================================== Ai Message ==================================

The sum of 3 and 4 is 7.
```

조금 더 복잡한 예제를 살펴보겠습니다.

```python
messages = [HumanMessage(content="Add 3 and 4. Multiply the output by 2. Divide the output by 5")]
messages = react_graph.invoke({"messages": messages})
for m in messages['messages']:
    m.pretty_print()
```

**output**  

```text
================================ Human Message =================================

Add 3 and 4. Multiply the output by 2. Divide the output by 5
================================== Ai Message ==================================
Tool Calls:
  add (call_i8zDfMTdvmIG34w4VBA3m93Z)
 Call ID: call_i8zDfMTdvmIG34w4VBA3m93Z
  Args:
    a: 3
    b: 4
================================= Tool Message =================================
Name: add

7
================================== Ai Message ==================================
Tool Calls:
  multiply (call_nE62D40lrGQC7b67nVOzqGYY)
 Call ID: call_nE62D40lrGQC7b67nVOzqGYY
  Args:
    a: 7
    b: 2
================================= Tool Message =================================
Name: multiply

14
================================== Ai Message ==================================
Tool Calls:
  divide (call_6Q9SjxD2VnYJqEBXFt7O1moe)
 Call ID: call_6Q9SjxD2VnYJqEBXFt7O1moe
  Args:
    a: 14
    b: 5
================================= Tool Message =================================
Name: divide

2.8
================================== Ai Message ==================================

The final result after performing the operations \( (3 + 4) \times 2 \div 5 \) is 2.8.
```

이제 질문을 추가해 봅시다.

```python
messages = [HumanMessage(content="Multiply that by 2.")]
messages = react_graph.invoke({"messages": messages})
for m in messages['messages']:
    m.pretty_print()
```

**output**  

```text
================================ Human Message =================================

Multiply that by 2.
================================== Ai Message ==================================

Could you please provide the number you want to multiply by 2?
```

이전 대화 내용을 기억하고 있지 않기 때문에, 그래프에서는 이전에 계산한 결과를 알지 못합니다.
하지만 `LangGraph`는 체크포인터를 사용하여 각 단계 후에 그래프 상태를 자동으로 저장할 수 있습니다.
체크포인터를 이용하면 `LangGraph` 에 내장된 메모리 저장 기능을 이용해 마지막 메시지(상태)로부터
시작할 수 있도록 합니다. 가장 쉽게 사용할 수 있는 체크포인터 중 하나는 `MemorySaver`로 키-값 형태의
메모리 저장소입니다. 우리가 해야 할 일은 간단히 체크포인터로 그래프를 컴파일하는 것뿐입니다.
그러면 그래프에 메모리가 생깁니다!

이제 메모리를 추가하여 이전 대화 내용을 기억하도록 하겠습니다.

```python
from langgraph.checkpoint.memory import MemorySaver
memory = MemorySaver()
react_graph_memory = builder.compile(checkpointer=memory)
```

메모리를 사용할 때는 `thread_id` 을 지정해야 합니다.
이 `thread_id`는 우리의 그래프 메시지(상태)를 수집 저장합니다.

다음 그림을 살펴보면 :

- 체크포인터는 그래프의 모든 단계에서 상태를 기록합니다.  
- 이 체크포인터는 스레드에 기록되며,  
- 우리는 `thread_id`를 사용하여 해당 스레드에 액세스할 수 있습니다.  

![checkpoint](/assets/images/langgraph/agent/image-3.png)

```python
# Specify a thread
config = {"configurable": {"thread_id": "1"}}

# Specify an input
messages = [HumanMessage(content="Add 3 and 4.")]

# Run
messages = react_graph_memory.invoke({"messages": messages},config)
for m in messages['messages']:
    m.pretty_print()
```

**output**  

```text
================================ Human Message =================================

Add 3 and 4.
================================== Ai Message ==================================
Tool Calls:
  add (call_MSupVAgej4PShIZs7NXOE6En)
 Call ID: call_MSupVAgej4PShIZs7NXOE6En
  Args:
    a: 3
    b: 4
================================= Tool Message =================================
Name: add

7
================================== Ai Message ==================================

The sum of 3 and 4 is 7.
```

동일한 `thread_id` 를 사용하면 이전에 기록된 체크포인트에서 진행할 수 있습니다!
아래와 같이 사용자 메시지를 `thread_id`가 포함된 config를 사용하여 실행해 보겠습니다.

다음 코드 실행 시 이전 실행 결과와 추가한 메시지가 연결되어 실행되는 것을 볼 수 있습니다. 

```python
messages = [HumanMessage(content="Multiply that by 2.")]
messages = react_graph_memory.invoke({"messages": messages}, config)
for m in messages['messages']:
    m.pretty_print()
```

**output**  

```text
================================ Human Message =================================

Add 3 and 4.
================================== Ai Message ==================================
Tool Calls:
  add (call_J1PBycN06V22NEDNaWkZwmUJ)
 Call ID: call_J1PBycN06V22NEDNaWkZwmUJ
  Args:
    a: 3
    b: 4
================================= Tool Message =================================
Name: add

7
================================== Ai Message ==================================

The sum of 3 and 4 is 7.
================================ Human Message =================================

Multiply that by 2.
================================== Ai Message ==================================
Tool Calls:
  multiply (call_6a2XlUBJNnBxZS5K7VrfQH36)
 Call ID: call_6a2XlUBJNnBxZS5K7VrfQH36
  Args:
...
14
================================== Ai Message ==================================

The result of multiplying 7 by 2 is 14.
```

### 마무리

다양한 툴을 사용하여 LLM과 연결하고, 이를 통해 사용자의 질문에 대해 스스로 도구를 선택하고,
그 도구를 사용하여 답변을 생성하도록 하는 에이전트 아키텍처를 구현해 보았습니다.
