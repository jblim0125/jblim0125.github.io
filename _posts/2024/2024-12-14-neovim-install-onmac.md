---
layout: post
title: NeoVim 설치 및 설정
author: jblim0125
date: 2024-12-14
category: 2024
---

## 배경

vim 플러그인을 설치한 경우 vscode 에서 한글 입력에 문제가 있어 NeoVim을 설치하고 neovim 플러그인을 사용해 보려고 한다.

## neovim 설치

```shell
brew install neovim
```

## neovim 설정

- 커서 설정  

```shell
set guicursor=n-v-c:block-Cursor/lCursor
set guicursor+=i:ver25-Cursor/lCursor
set guicursor+=r-cr:hor20
set guicursor+=o:hor50
set guicursor+=a:blinkon0
```

- 클립보드 설정

```shell
"" Copy/Paste/Cut
if has('unnamedplus')
  set clipboard=unnamed,unnamedplus
endif
```

## neovim 플러그인 설치

생산성을 위해 많은 단축키 설정이 필요할 수 있는데 이런 부분은 언제나 시간을 많이 잡아 먹으니까 패스...
