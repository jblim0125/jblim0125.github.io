---
layout: post
title: VSCode 상에서 Lombok 관련 코드 에러 인식 해결 과정
author: jblim0125
date: 2025-08-25
category: 2025
tags: [VSCode, Lombok] 
---

## 개요

Java 를 이용해 기능을 개발하는 경우 `어노테이션`을 활용해 코드 개발양을 줄일 수 있어 많이 이용하게 된다.
최근 `VSCode`와 다양한 LLM들 `Github Copilot`, `Gemini`, `Claude` 을 활용한 개발 과정에서
부딪힌 문제에 대한 해결 과정을 공유(기록)한다.

## 오류
`VSCode` 상에서 코드를 열어서 편집하려고 하면 `Annotation`을 이용해 처리된 코드들에 대해서 오류로 인식한다.

- 오류 1
    `@RequiredArgsConstructor` 을 활용해 의존성 주입되도록 한 코드에서 `variable ... not initialized in the default constructor` 가 발생.

- 오류 2
    `@slf4j` 를 선언하고 코드 상에서 `log` 사용 시 `cannot find symbol` 오류 발생 

## 해결 방법

lombok 의 버전은 1.18.32 -> 1.18.38로 번경하여 해결되었다.

## 상세 설명

- 왜 Lombok 버전 변경이 효과 있었는가?
    - VSCode Java 확장은 내부적으로 Eclipse JDT Language Server를 기반으로 돌아가는데, Lombok은 이 언어 서버의 AST 처리 과정에 깊숙이 들어옵니다.
    - 특정 Lombok 버전(예: 1.18.32)은 JDK나 JDT의 최신 변경사항과 호환성 문제가 있어 annotation processor가 제대로 인식되지 않는 경우가 보고되었습니다.
    - 1.18.38에서는 이런 JDK 17+ / 최신 JDT 관련 호환성 버그가 해결되었기 때문에, 단순히 버전 업으로 문제가 사라진 것입니다.

아래는 Lombok 1.18.38 버전의 릴리스 노트(변경사항)을 기준으로, 어떤 개선이 있었는지 구체적으로 정리한 내용입니다.

1. Eclipse 기반 언어 서버 관련 버그 수정 (BUGFIX)
    - 최근 Eclipse 또는 해당 기반의 VSCode Java 언어 서버에서 "negative length" 오류가 발생하던 문제를 수정했습니다. ￼
    - 추론하건대 이 오류는 Lombok이 AST(Document)에 적용되는 패치 과정에서 발생했던 것으로, 언어 서버가 정상 작동하지 않았던 원인이었을 가능성이 높습니다.

2. VSCode 리팩터링 관련 문제 수정 (BUGFIX)
    - VSCode의 “extract local variable” 리팩터링 기능 사용 시, Lombok으로 생성된 메서드를 참조하는 경우 모든 호출 위치를 바꾸지 못하던 문제가 해결되었습니다. ￼

결론 — VSCode Lombok 인식 문제 해결과의 연관성

| 문제 원인                                                 | 연관된 변경사항                                              |
| --------------------------------------------------------- | ------------------------------------------------------------ |
| VSCode Java 언어 서버에서 발생하던 "negative length" 오류 | v1.18.38의 Eclipse/언어 서버 관련 버그 수정 덕분에 해결 가능 |
| 리팩터링 시 Lombok 생성된 메서드 처리 누락                | v1.18.38의 VSCode 리팩터링 버그 수정 덕분에 안정적으로 처리  |
| 최신 JDK (예: JDK 24) 사용 시 발생하는 Lombok 호환 문제   | v1.18.38에서 JDK 24 지원 추가로 해결 가능                    |