---
title: 맥 VSCode 키반복 활성화 
author: jblim0125
date: 2024-02-15
category: 2024
layout: post
---

VSCode vim plugin 사용 상태에서 키 반복이 되지 않는 경우

터미널에서 다음 명령을 실행 -> VSCode 재시동

```shell
defaults write com.microsoft.VSCode ApplePressAndHoldEnabled -bool false
```