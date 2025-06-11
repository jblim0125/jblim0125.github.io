---
layout: post
title: Python Formatter 설정(PyCharm)
author: jblim0125
date: 2025-06-10
category: 2025
tags: [Python, Code_Style]
---

## 개요

다음은 Pycharm 기준 코드 스타일 가이드입니다.  
이 가이드는 코드의 일관성을 유지하고 가독성을 향상시키기 위해 작성되었습니다.  

### 0. `pyproject.toml`

pyproject.toml 파일을 프로젝트 루트에 추가하여 코드 스타일을 관리합니다.

```yaml
# ---------------------
# Black 코드 포맷터 설정
# ---------------------
[tool.black]
line-length = 100                     # 한 줄 최대 길이 (black 기본: 88, 팀 스타일에 맞게 설정)
target-version = ["py311"]            # 지원하는 Python 버전 (복수도 가능)
skip-string-normalization = false     # 문자열 따옴표 자동 변경 허용 (true면 원래 따옴표 유지)
skip-magic-trailing-comma = false     # 마지막 요소 콤마 자동 추가 허용

# ---------------------
# isort 설정 (Black 호환)
# ---------------------
[tool.isort]
profile = "black"                    # Black과 호환되는 import 정렬 규칙 사용
line_length = 100                    # Black과 동일한 줄 길이 설정
src_paths = ["src", "tests"]
#known_first_party = ["my_project"]  # 현재 프로젝트 내부 패키지 이름
multi_line_output = 3                # 다중 import 시 hanging indent 스타일 (Black 스타일)
include_trailing_comma = true        # 마지막 import에 쉼표 붙임 (Black과 일치)
use_parentheses = true               # 괄호를 사용해 여러 줄 import (Black과 일치)
ensure_newline_before_comments = true  # 주석 앞에 빈 줄 보장

# 특정 폴더 제외 (예: 마이그레이션 폴더 등)
skip = ["migrations", "__pycache__"]

# gitignore 파일의 설정도 무시 대상에 포함
skip_gitignore = true
```

### 1. Use `black` for formatting

black 포맷터는 Python 코드 스타일을 자동으로 적용해주는 도구입니다.
black 포맷터는 Pycharm v2025.1 기준 기본(Tools 에 탑재되어 있음)으로 제공되는 기능으로
개발 환경(env)에 `black` 패키지만 설치되어 있다면 활성화를 쉽게 진행할 수 있다.

1. 설치

    ```bash
    pip install black
    ```

2. 활성화 방법(Pycharm 기준)

    1. Settings -> Tools > Black
    2. Enable "On code format"
    3. Enable "On save"

    취향에 따라 On code format과 On save를 선택 합니다.

### 2. Use `isort` for sorting imports

isort 는 Python 코드에서 import 문을 정렬해주는 도구입니다.
isort 는 Pycharm 에서 기본 연동은 제공되지 않으나, 
`External Tools`에 추가하여 사용하거나, `File Watchers` 기능을 통해 자동으로 import를 정렬할 수 있습니다.

1. 설치 방법  

    isort 설치 후 isort 의 경로를 확인 합니다.

   ```bash
    pip install isort
    which isort  
    # 설치된 isort 경로 확인
    ```

2. **`External Tools` 설정 방법**  
    이 기능을 활용하는 경우 파일 선택 후 우클릭을 통해 external tool -> isort 를 선택하여 import를 정렬할 수 있습니다.

    1. Settings -> Tools -> External Tools
    2. Add new tool
    3. Name: `isort`
    4. Program: `{isort path}`
    5. Arguments: `$FilePathRelativeToProjectRoot$`
    6. Working directory: `$ProjectFileDir$`

3. **`File Watchers`로 설정하는 방법은 다음과 같습니다.**
    이 기능을 활용할 경우 파일 저장 시 자동으로 import가 정렬됩니다.
   > 주의 : `File Watchers`는 파일 저장 시 자동으로 실행되므로, 
   > 파일이 저장될 때마다 import가 정렬됩니다. 이로 인해 불필요한 변경 사항이 발생할 수 있습니다.

    1. Settings -> Tools -> File Watchers
    2. Add new watcher
    3. Name: `isort`
    4. File type: `Python`
    5. Scope: `Project Files`
    6. Program: `{isort path}`
    7. Arguments: `$FilePathRelativeToProjectRoot$`
    8. Working directory: `$ProjectFileDir$`

4. 추천 방법
   `External Tools` 등록 후 기존 `import optimization` 단축키(ctrl + option + o) 를 isort 로 변경하여 사용하는 것을 추천합니다.

### 3. Run In Command Line

코드 스타일을 커맨드라인에서 확인하고 적용하려면 다음 명령어를 사용할 수 있습니다.

```bash
# 코드 스타일 확인
black --check .
# 코드 스타일 확인 상세
black --check --diff .
# 코드 스타일 적용
black .
# import 정렬 확인
isort --check .
# import 정렬 확인 상세
isort --check --diff .
# import 정렬 적용
isort .
```

### 4. Ignore Formatting

특정 파일이나 디렉토리에 대해 코드 스타일 적용을 무시하려면, 해당 파일 상단에 다음 주석을 추가합니다.

```python
# fmt: off
# isort: skip_file
```

특정 라인에 대해서만 무시하려면 다음과 같이 작성합니다.

```python
## 라인에 대해서 무시하도록 설정하거나, 
## 블록 단위로 무시하도록 설정할 수 있다.
## 방법은 아래와 같다.

import os  # isort: skip
import time
import sys

str_variable = "This line will not be formatted"  # fmt: skip

# fmt: off
def example_function1():
    pass  
# fmt: on

def example_function2():
    pass
```

### 5. Git Hook

Git Hook 을 사용하여 커밋 시 자동으로 코드 스타일을 적용할 수 있습니다.
이를 통해 팀원들이 일관된 코드 스타일을 유지할 수 있습니다.

```bash
# pre-commit 설치
pip install pre-commit
pre-commit install
```

이후 `.pre-commit-config.yaml` 파일을 프로젝트 루트에 추가하여 다음과 같이 설정합니다.

```yaml
default_language_version:
  python: python3.11
repos:
  - repo: https://github.com/psf/black
    rev: 24.10.0
    hooks:
      - id: black
        name: "Black - Python code formatter"
        types: [python]
        entry: black
        language: python
  - repo: https://github.com/pycqa/isort
    rev: 6.0.1
    hooks:
      - id: isort
        name: "isort - Python import sorter"
        types: [python]
        entry: isort
        language: python
```
