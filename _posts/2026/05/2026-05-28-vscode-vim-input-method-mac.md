---
layout: post
title: macOS VSCode Vim 확장에서 한영 입력기 자동 전환 설정
author: jblim0125
date: 2026-05-28
category: 2026
tags: [VSCode, Vim, macOS]
---

## 개요

macOS에서 VSCode의 [VSCodeVim](https://marketplace.visualstudio.com/items?itemName=vscodevim.vim)
확장을 쓰다 보면 한글 입력기 때문에 겪는 고질적인 불편이 있습니다.
한글로 문장을 입력하다가 `Esc`를 눌러 Normal 모드로 빠져나온 뒤 `dd`, `yy`, `:w` 같은
명령을 누르면, 입력기가 여전히 한글 상태라서 `ㅇㅇ`, `ㄴㄴ` 처럼 엉뚱한 글자가 들어가고
명령이 먹지 않습니다. 매번 손으로 한영 키를 눌러 영문으로 바꿔야 하는 것이죠.

이 글에서는 다음을 다룹니다.

- 왜 이 문제가 생기는지 (Vim 모드와 입력기의 상태 불일치)
- `autoSwitchInputMethod` 설정으로 자동 전환하는 방법
- `im-select` 설치와 설정값
- `{im}` placeholder가 무엇이고 왜 하드코딩하면 안 되는지
- 동작 원리와 트러블슈팅

## 문제의 본질: 모드와 입력기는 서로 모른다

Vim은 모드 기반 에디터입니다. Insert 모드에서는 글자를 입력하고, Normal 모드에서는
`h j k l`, `dd`, `:wq` 같은 **영문 명령**을 받습니다. 그런데 macOS의 입력기(IME) 상태는
Vim의 모드와 전혀 연동되지 않습니다. 둘은 서로의 존재를 모릅니다.

그래서 이런 시퀀스가 발생합니다.

```text
Insert 모드 + 한글 입력기 → "안녕하세요" 입력
Esc (Normal 모드 진입)     → 입력기는 여전히 한글 상태
dd 입력 시도              → 실제로는 "ㅇㅇ"가 들어가 명령 실패
```

해결의 핵심은 단순합니다. **Vim 모드가 바뀌는 순간 입력기도 함께 바꿔주는 것**입니다.

- Normal 모드로 들어갈 때 → 입력기를 영문(ABC)으로 강제 전환
- Insert 모드로 돌아올 때 → 직전에 쓰던 입력기(예: 한글)로 복원

VSCodeVim은 이 동작을 `autoSwitchInputMethod` 설정으로 지원합니다. 다만 입력기를
읽고 바꾸는 실제 작업은 외부 CLI 도구에 위임하는데, 그 도구가 `im-select`입니다.

## 사전 준비: im-select 설치

`im-select`는 현재 입력기를 조회하거나 특정 입력기로 전환해주는 작은 macOS CLI 도구입니다.
Homebrew로 설치합니다.

```sh
brew tap daipeihust/tap
brew install im-select
```

설치 후 경로를 확인합니다. **Apple Silicon과 Intel Mac의 경로가 다릅니다.**

```sh
which im-select
# Apple Silicon: /opt/homebrew/bin/im-select
# Intel Mac:     /usr/local/bin/im-select
```

이 경로는 뒤의 설정에 그대로 넣어야 하므로 자신의 환경에 맞는 값을 확인해 두세요.

도구가 잘 동작하는지 직접 테스트해 봅니다. 인자 없이 실행하면 **현재 입력기 ID**를
출력합니다.

```sh
$ im-select
com.apple.keylayout.ABC
```

이제 한영 키를 눌러 한글 입력기로 바꾼 뒤 다시 실행하면, 한글 입력기의 ID가 나옵니다.

```sh
$ im-select
com.apple.inputmethod.Korean.2SetKorean
```

(한글 입력기 ID는 환경에 따라 다를 수 있습니다. 뒤에서 설명하듯 설정에서는 이 ID를
직접 알 필요가 없습니다.)

## VSCode 설정

`settings.json`(`Cmd+Shift+P` → `Preferences: Open User Settings (JSON)`)에 다음을 추가합니다.

```json
"vim.autoSwitchInputMethod.enable": true,
"vim.autoSwitchInputMethod.defaultIM": "com.apple.keylayout.ABC",
"vim.autoSwitchInputMethod.obtainIMCmd": "/opt/homebrew/bin/im-select",
"vim.autoSwitchInputMethod.switchIMCmd": "/opt/homebrew/bin/im-select {im}"
```

각 키의 의미는 다음과 같습니다.

- `enable`: 자동 전환 기능 on/off.
- `defaultIM`: Normal 모드에서 강제할 기본 입력기. 영문 레이아웃인
  `com.apple.keylayout.ABC`를 넣습니다. (이 값도 `im-select`로 확인한 값입니다.)
- `obtainIMCmd`: 현재 입력기를 **읽어오는** 명령. Insert 모드를 떠날 때 "지금 어떤
  입력기를 쓰고 있었는지" 저장하기 위해 실행됩니다.
- `switchIMCmd`: 입력기를 **바꾸는** 명령. 여기에 반드시 `{im}` placeholder가 있어야 합니다.

## 핵심: {im} placeholder

가장 흔한 실수가 `switchIMCmd`에 전환할 입력기를 직접 박아 넣는 것입니다.

```json
// 잘못된 설정 — 검증 에러가 납니다
"vim.autoSwitchInputMethod.switchIMCmd": "/opt/homebrew/bin/im-select com.apple.keylayout.ABC"
```

이렇게 하면 VSCodeVim이 다음과 같은 에러를 띄웁니다.

```text
vim.autoSwitchInputMethod.switchIMCmd is incorrect, it should contain the placeholder {im}.
```

이유는 `switchIMCmd`가 **두 가지 상황에서 서로 다른 입력기로** 호출되기 때문입니다.

- Normal 모드 진입 시 → `{im}`을 `defaultIM`(ABC)으로 치환해 실행
- Insert 모드 복귀 시 → `{im}`을 **직전에 저장해 둔 입력기**(예: 한글)로 치환해 실행

즉 `{im}`은 VSCodeVim이 **런타임에 상황에 맞는 입력기 ID로 갈아끼우는 자리**입니다.
여기에 `com.apple.keylayout.ABC`를 하드코딩하면 항상 영문으로만 전환되어,
"Insert 모드로 돌아갈 때 한글 복원"이라는 절반의 기능이 통째로 사라집니다.
그래서 확장이 아예 검증 단계에서 `{im}` 누락을 막는 것입니다.

올바른 설정은 placeholder를 그대로 둡니다.

```json
"vim.autoSwitchInputMethod.switchIMCmd": "/opt/homebrew/bin/im-select {im}"
```

여기서 한 가지 더 짚을 점은 `obtainIMCmd`와 `switchIMCmd`의 **비대칭**입니다.
`obtainIMCmd`에는 `{im}`이 없는 게 정상입니다. 이 명령은 현재 입력기를 **읽기만**
하므로 인자가 필요 없습니다. 반대로 `switchIMCmd`는 입력기를 **쓰는**(전환) 명령이라
"무엇으로 바꿀지"를 받아야 하고, 그 자리가 `{im}`입니다.

## 동작 원리 정리

전체 흐름을 시퀀스로 보면 다음과 같습니다.

```text
[Insert 모드에서 한글 입력 중]
        │
        │  Esc  (Normal 모드 진입)
        ▼
  obtainIMCmd 실행   →  현재 입력기(한글) ID를 VSCodeVim이 기억
  switchIMCmd 실행   →  {im}=defaultIM(ABC)  →  영문으로 전환
        │
        │  i / a / o  (Insert 모드 복귀)
        ▼
  switchIMCmd 실행   →  {im}=기억해 둔 한글 ID  →  한글로 복원
```

핵심은 `obtainIMCmd`가 "떠날 때의 입력기"를 기억해 두기 때문에, 굳이 한글 입력기의
ID를 설정에 적지 않아도 자동으로 복원된다는 점입니다. 그래서 일본어·중국어 등 다른
입력기를 섞어 쓰더라도 같은 설정으로 동작합니다.

## 트러블슈팅

- **에러: `... should contain the placeholder {im}`**
  `switchIMCmd`에 입력기 ID를 하드코딩한 경우입니다. `{im}`으로 되돌리세요.

- **전환이 전혀 안 됨**
  `which im-select`로 경로를 다시 확인하세요. Apple Silicon(`/opt/homebrew`)과
  Intel(`/usr/local`)의 경로가 다릅니다. 설정의 절대경로가 실제 경로와 일치해야 합니다.

- **Normal 모드 전환은 되는데 한글 복원이 안 됨**
  `obtainIMCmd`가 비어 있거나 잘못된 경우입니다. 이 명령이 있어야 "떠날 때 입력기"를
  기억할 수 있습니다.

- **`defaultIM` 값이 의심스러울 때**
  영문 입력 상태에서 `im-select`를 실행해 나온 값을 그대로 넣으세요. 보통
  `com.apple.keylayout.ABC`이지만, US 레이아웃 등 환경에 따라 다를 수 있습니다.

- **설정 변경이 즉시 반영 안 됨**
  VSCode를 재시작하거나 `Developer: Reload Window`를 실행해 보세요.

## 정리

VSCodeVim의 한영 자동 전환은 결국 세 가지로 요약됩니다.

- 입력기 조회·전환은 `im-select` CLI에 위임한다.
- `obtainIMCmd`는 떠날 때 입력기를 기억하고(인자 없음), `switchIMCmd`는 그것을
  복원하거나 기본 입력기로 바꾼다(`{im}` 필수).
- `{im}`은 상황에 따라 다른 입력기 ID로 치환되는 자리이므로 절대 하드코딩하지 않는다.

이 설정 한 번이면 한글로 글을 쓰다 `Esc`를 눌렀을 때 자동으로 영문 명령 모드가 되고,
다시 `i`를 누르면 한글로 돌아오는, 모드와 입력기가 자연스럽게 맞물리는 환경을 얻을 수 있습니다.
