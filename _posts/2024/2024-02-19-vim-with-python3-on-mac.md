---
layout: post
title: VIM with python3 on Mac
author: jblim0125
date: 2024-02-16
category: 2024
---

## VIM with Python3

VIM 의 python3 활성화 방법  

1. python 활성화 상태 확인 방법

    ```shell
    $ vim version | grep python
    +cmdline_hist      +langmap           -python            +viminfo
    +cmdline_info      +libcall           +python3           +virtualedit
    링크: clang -o vim -lm -lncurses -lsodium -liconv -lintl -framework AppKit -L/opt/homebrew/opt/lua/lib -llua5.4 -mmacosx-version-min=14.0 -fstack-protector-strong -L/opt/homebrew/opt/perl/lib/perl5/5.38/darwin-thread-multi-2level/CORE -lperl -L/opt/homebrew/opt/python@3.12/Frameworks/Python.framework/Versions/3.12/lib/python3.12/config-3.12-darwin -lpython3.12 -framework CoreFoundation -lruby.3.2 -L/opt/homebrew/Cellar/ruby/3.2.2_1/lib 
    ```

    위와 같이 `+python3` 로 출력되어야 vim 에서 python3가 활성화 된 것이다.

2. vim 삭제  

    ```shell
    brew uninstall vim
    ```

3. python3 설치와 alias 설정  
    python3 설치 후 사용하고 있는 `shell` 설정에서 python alias 추가  

    `.zsh` or `.bash_profile`  

    ```shell
    alias python="python3"
    ```

4. 재부팅  

    재부팅 없이 `vim` 설치 시 `python3` 활성화 안 됨  

5. vim 설치 및 확인  

    ```shell
    brew install vim
    ```

6. vim alias 설정  
    homebrew 이용해 설치한 `VIM` 위치 `/usr/local/bin/vim`  

    ```shell
    alias vim=/usr/local/bin/vim
    ```

7. VIM python3 활성화 확인  

    ```shell
    $ vim --version | grep python
    output:
        +conceal           +linebreak         +python3           +visual
    ```
