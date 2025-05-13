---
layout: post
title: LangGraph Motivation
author: jblim0125
date: 2025-05-08
category: 2025
tags: [LangGraph]
---

## LangGraph Motivation

이 문서는 [LangGraph Motivation](https://files.cdn.thinkific.com/file_uploads/967498/attachments/ecd/3cc/6d3/LangChain_Academy_-_Introduction_to_LangGraph_-_Motivation.pdf)을 번역하고 제가 이해한 내용을 기반으로 작성하였습니다.

### LangChain 소개 및 LangGraph 개발 동기

1. LLM(대형 언어 모델)의 한계
    ![alt text](/assets/images/langgraph/langgraph-motivation/image.png)
    * 단일 언어 모델은 기능에 제약이 있습니다.
    * 도구 사용, 외부 컨텍스트 활용, 다단계 작업 등의 워크플로우를 스스로 수행하기 어렵습니다.

2. 그래서 많은 LLM 애플리케이션은 `Control Flow`을 사용합니다
    ![alt text](/assets/images/langgraph/langgraph-motivation/image-1.png)
    LLM 호출 전후로 동작(툴 호출, 검색 등)을 추가하여 더 많은 일을 할 수 있도록 합니다.
    이러한 흐름은 “체인(chain)”이라고 불리며, 고정된 워크플로우를 나타냅니다.
    > 참고 링크
    [https://en.wikipedia.org/wiki/Control_flow](https://en.wikipedia.org/wiki/Control_flow)
    [https://github.com/langchain-ai/rag-from-scratch](https://github.com/langchain-ai/rag-from-scratch)

3. 체인의 특징
    * 항상 같은 방식으로 실행되기 때문에 '신뢰성(reliability)'이 높습니다.
    * 하지만, 우리가 진짜 원하는 건 LLM 시스템이 스스로 제어 흐름을 결정하는 것입니다.
    ![alt text](/assets/images/langgraph/langgraph-motivation/image-2.png)

### Agent = LLM이 결정하는 제어 흐름

4. 에이전트(Agent)의 개념
    * 에이전트는 고정된 체인 대신, LLM이 스스로 제어 흐름을 선택하는 방식입니다.
    * 에이전트의 종류는 다양합니다:
      * 일반 자율 에이전트
      * 기억을 가지는 에이전트
      * 사람의 개입이 있는 에이전트(HITL)
      * 맞춤형 에이전트 등
    ![alt text](/assets/images/langgraph/langgraph-motivation/image-3.png)

### LangGraph의 역할

5. 신뢰성과 제어의 균형
    * LLM 기반 시스템은 유연하지만 예측 불가능하고, 체인은 예측 가능하지만 유연하지 않음.
    * LangGraph는 이 균형을 잡아줍니다.
      * 개발자가 일부 제어 흐름을 고정하고,
      * 나머지는 LLM이 결정하도록 구성합니다.

    ![alt text](/assets/images/langgraph/langgraph-motivation/image-4.png)