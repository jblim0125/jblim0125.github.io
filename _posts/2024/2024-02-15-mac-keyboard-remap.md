---
title: 키보드 리매핑 on Mac
author: jblim0125
date: 2024-02-15
category: 2024
layout: post
---

하드웨어 기반의 Fn키를 사용하는 키보드의 경우 FN 키를 사용할 수 없음  
맥에서 제공하는 hidutil을 이용해 키보드 리매핑을 진행  
87키 키보드 기준(텐키리스) 아래와 같이 수행  

- Popup(application) -> Fn  
- Right-Command(한/영) -> F18
- Pause/Break -> Power  

풀 배열 맥 키보드  
![alt text](/assets/images/mac-key-remap/image01.png)

아래 링크는 hidutil을 이용해 키보드 리매핑을 도와주는 사이트이다.  
접속해서 원하는 설정을 추가한다.  
[리매핑 생성 사이트](https://hidutil-generator.netlify.app)

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.local.KeyRemapping</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/bin/hidutil</string>
        <string>property</string>
        <string>--set</string>
        <string>{"UserKeyMapping":[
            {
              "HIDKeyboardModifierMappingSrc": 0x700000048,
              "HIDKeyboardModifierMappingDst": 0x700000066
            },
            {
              "HIDKeyboardModifierMappingSrc": 0x7000000E7,
              "HIDKeyboardModifierMappingDst": 0x70000006D
            },
            {
              "HIDKeyboardModifierMappingSrc": 0x700000065,
              "HIDKeyboardModifierMappingDst": 0xFF00000003
            }
        ]}</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
</dict>
</plist>
```

터미널 or 파인더를 이용해 폴더를 생성

```shell
mkdir -p ~/Library/LaunchAgents
```

vi or 텍스트 편집기를 이용해 파일 생성  
이름 : com.local.KeyRemapping.plist  

한/영키 활성화를 위한 단축키 설정  
![단축키 설정](/assets/images/mac-key-remap/2024-02-15-17-23-27.png)

이제 설정한 FN + Break 키를 이용해 종료기능 사용 가능  
