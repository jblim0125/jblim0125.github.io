---
layout: post
title: Python Logging 사용과 모듈 별 로그 레벨 설정
author: jblim0125
date: 2025-10-15
category: 2025
tags: [Python, Logging]
---

## 개요

Python의 표준 로깅(logging) 모듈은 애플리케이션 동작 관찰과 문제 진단에 핵심입니다. 이 글에서는 다음을 다룹니다.

- 빠른 시작: 기본 사용법과 포맷
- 로거/핸들러/포매터/필터 구조 이해
- 모듈(패키지) 별 로그 레벨 설정 방법 3가지
- 실전 예제와 출력 샘플
- 트러블슈팅, 성능 팁, 체크리스트

## 빠른 시작: 가장 단순한 설정

```python
import logging

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s [%(name)s] %(message)s",
)

logger = logging.getLogger(__name__)
logger.info("Hello logging")
logger.debug("This is hidden because level=INFO")
```

- `basicConfig`는 한 번만 효과가 있습니다. 이후에 핸들러가 이미 붙은 상태에서 다시 호출하면 무시됩니다.
- 항상 모듈 단위로 `logging.getLogger(__name__)`를 사용하세요. 계층적 제어가 쉬워집니다.

## 로깅 구성 요소 간단 이해

- Logger: 메시지를 기록하는 주체. 이름이 계층 구조로 연결됩니다(`a`, `a.b`, `a.b.c`).
- Handler: 기록을 내보내는 대상(콘솔, 파일, Syslog, HTTP, Rotating 등).
- Formatter: 로그 라인의 포맷(시간/레벨/로거명/메시지 등).
- Filter: 특정 레코드만 통과시키는 필터(모듈/컨텍스트별 필터링).

핸들러는 자체 레벨을 가질 수 있으며, 로거 레벨과 핸들러 레벨 둘 다 만족해야 출력됩니다.

## 모듈 별 로그 레벨 설정 방법 3가지

### 방법 A: 코드로 직접 제어(getLogger + setLevel)

```python
# main.py
import logging
from app.service import svc

root = logging.getLogger()
root.setLevel(logging.INFO)

console = logging.StreamHandler()
console.setFormatter(logging.Formatter("%(levelname)s [%(name)s] %(message)s"))
root.addHandler(console)

# 모듈 별 레벨
logging.getLogger("app").setLevel(logging.DEBUG)        # 우리 코드
logging.getLogger("urllib3").setLevel(logging.WARNING)  # 외부 라이브러리 억제

svc()

# app/service.py
import logging
log = logging.getLogger(__name__)

def svc():
    log.debug("service debug detail")
    log.info("service info")
```

출력 예시(요약):

```
DEBUG [app.service] service debug detail
INFO  [app.service] service info
```

### 방법 B: dictConfig로 선언형 구성

```python
import logging.config

LOGGING = {
    "version": 1,
    "disable_existing_loggers": False,
    "formatters": {
        "standard": {
            "format": "%(asctime)s %(levelname)s [%(name)s] %(message)s",
            "datefmt": "%Y-%m-%d %H:%M:%S",
        }
    },
    "handlers": {
        "console": {
            "class": "logging.StreamHandler",
            "level": "INFO",
            "formatter": "standard",
            "stream": "ext://sys.stdout",
        },
        "file": {
            "class": "logging.handlers.TimedRotatingFileHandler",
            "level": "DEBUG",
            "formatter": "standard",
            "filename": "logs/app.log",
            "when": "midnight",
            "backupCount": 7,
            "encoding": "utf-8",
        },
    },
    "loggers": {
        "app": {"level": "DEBUG", "handlers": ["console", "file"], "propagate": False},
        "urllib3": {"level": "WARNING", "handlers": ["console"], "propagate": False},
    },
    "root": {"level": "INFO", "handlers": ["console"]},
}

logging.config.dictConfig(LOGGING)
```

- 선언형으로 재사용이 쉽고, 테스트/운영 프로파일 전환에도 유리합니다.
- `propagate: False`로 중복 로그를 방지할 수 있습니다.

### 방법 C: 계층 맵으로 일괄 적용(설정 파일 기반)

`config.yml` 파일에서 계층적 로그 레벨을 설정하고 런타임에 일괄 적용할 수 있습니다:

```yaml
log:
  level:
    # 기본 로그 레벨
    default: "INFO"  # 전체 애플리케이션 기본 로그 레벨
    # OpenSearch 관련 로그 레벨 (계층적 설정)
    opensearch: "WARNING"
    opensearchpy: "WARNING"
    opensearchpy.connection: "WARNING"
    opensearchpy.connection.base: "WARNING"
    opensearchpy.connection.http_urllib3: "WARNING"
    urllib3: "WARNING"
    urllib3.connectionpool: "WARNING"
    # 애플리케이션 모듈별 로그 레벨
    jblim: "INFO"
```

**계층적 로그 설정 구조:**
- `default`: 전체 애플리케이션의 기본 로그 레벨
- `{package.module}`: 개별 패키지나 모듈별 로그 레벨

이 맵을 적용하는 파이썬 코드는 다음과 같습니다.

```python
import logging, sys

def apply_hierarchical_levels(level_map: dict) -> None:
    default_level = level_map.get("default", "INFO").upper()

    root = logging.getLogger()
    root.setLevel(getattr(logging, default_level, logging.INFO))

    if not root.handlers:
        h = logging.StreamHandler(sys.stdout)
        h.setFormatter(logging.Formatter("%(asctime)s %(levelname)s [%(name)s] %(message)s"))
        h.setLevel(getattr(logging, default_level, logging.INFO))
        root.addHandler(h)

    for name, level in level_map.items():
        if name == "default":
            continue
        logger = logging.getLogger(name)
        logger.setLevel(getattr(logging, level.upper(), logging.INFO))
```

**디버깅이 필요한 경우** 로그 레벨을 일괄 변경하여 처리하거나 모듈 별 로그 레벨을 변경해 사용한다.

```yaml
log:
  level:
    default: "DEBUG"
    opensearch: "DEBUG"
  console_output: true
  file_output: true
```

## 핸들러/포매터 실전 레시피

- Console: 개발 중 즉시 확인
- File + Rotation: 운영 환경 기본. `RotatingFileHandler` 또는 `TimedRotatingFileHandler`
- JSON 포맷: 로그 수집기(Fluent Bit/Vector/Logstash) 연동 시 유용

크기 기준 로테이션 예시:

```python
from logging.handlers import RotatingFileHandler
handler = RotatingFileHandler("logs/app.log", maxBytes=5_000_000, backupCount=3)
handler.setFormatter(logging.Formatter("%(asctime)s %(levelname)s [%(name)s] %(message)s"))
logging.getLogger().addHandler(handler)
```

## 실전 예제: 전역 INFO, 우리 코드는 DEBUG

```text
project/
├─ main.py
└─ app/
   ├─ __init__.py
   └─ service.py
```

```python
# main.py
import logging, logging.config

LOGGING = {
    "version": 1,
    "disable_existing_loggers": False,
    "formatters": {"std": {"format": "%(asctime)s %(levelname)s [%(name)s] %(message)s"}},
    "handlers": {"console": {"class": "logging.StreamHandler", "formatter": "std"}},
    "root": {"level": "INFO", "handlers": ["console"]},
    "loggers": {"app": {"level": "DEBUG", "handlers": ["console"], "propagate": False}},
}

logging.config.dictConfig(LOGGING)

from app.service import run
run()

# app/service.py
import logging
log = logging.getLogger(__name__)

def run():
    log.debug("debug from app.service")
    log.info("info from app.service")
```

출력:

```
DEBUG [app.service] debug from app.service
INFO  [app.service] info from app.service
```

## 트러블슈팅 가이드

- 로그가 두 번 찍힘: 자식 로거 -> 부모(root) 전파 + 양쪽 핸들러 존재. 해결: `propagate=False` 또는 핸들러 정리
- `basicConfig` 무시됨: 이미 핸들러가 추가되어 있으면 무시됨. 기존 핸들러 제거 후 재구성
  
  ```python
  root = logging.getLogger()
  for h in root.handlers[:]:
      root.removeHandler(h)
  logging.basicConfig(...)
  ```

- 예외 스택: `logger.exception("msg")` 또는 `logger.error("msg", exc_info=True)`
- warnings 통합: `logging.captureWarnings(True)`

## 성능 영향과 팁

- `DEBUG` 레벨: 로그 출력으로 인한 성능 저하 발생
- `INFO` 레벨: 최소한의 성능 영향
- `WARNING` 이상: 성능 영향 거의 없음

추가 팁:

- 문자열 결합 비용 줄이기: 지연 포맷 사용
    ```python
    logger.debug("heavy object: %s", obj)
    ```
- 빈번한 DEBUG 호출 보호
    ```python
    if logger.isEnabledFor(logging.DEBUG):
            logger.debug("expensive details: %s", compute())
    ```
- 핸들러(I/O)가 가장 비쌉니다. 운영에서는 콘솔 최소화, 파일 로테이션 필수

## 테스트에서의 로깅 검증(pytest)

```python
import logging

def test_log(caplog):
        logger = logging.getLogger("app")
        with caplog.at_level(logging.INFO, logger="app"):
                logger.info("hello")
        assert "hello" in caplog.text
```

## 체크리스트 ✅

- [ ] 라이브러리(패키지)에서는 로깅 구성하지 말고 로거만 노출(getLogger(__name__))
- [ ] 애플리케이션 엔트리포인트에서만 구성(dictConfig 권장)
- [ ] 전역 기본 INFO, 3rd-party WARNING, 우리 코드는 DEBUG
- [ ] 중복 로그 방지: `propagate=False`와 핸들러 중복 점검
- [ ] 운영: 파일 로테이션, 인코딩, 백업 보관 주기 설정
- [ ] 개발/운영 프로파일별 설정 분리 또는 계층 맵 적용


## Sample Source

```python
from dataclasses import dataclass
from pathlib import Path
from typing import Optional, Union, Dict
import logging, sys

@dataclass
class LoggingConfig:
    level: Union[str, Dict[str, str]] = "INFO"  # "INFO" 또는 {"default": "INFO", "urllib3": "WARNING", ...}
    format: str = "%(asctime)s %(levelname)s [%(name)s] %(message)s"
    console_output: bool = True
    file_output: bool = False
    log_file: str = "logs/app.log"

class LoggerManager:
    """Centralized logging manager."""

    def __init__(self, config: Optional[LoggingConfig] = None):
        self.config = config
        self._is_configured = False
        if config is not None:
            self.setup_logging()

    def setup_logging(self, config: Optional[LoggingConfig] = None) -> None:
        if config is not None:
            self.config = config
        if self.config is None:
            raise ValueError("Configuration is required to setup logging")

        log_config = self.config

        # 기본 로그 레벨 결정
        default_level = "INFO"
        if isinstance(log_config.level, dict):
            default_level = log_config.level.get("default", "INFO")
        else:
            default_level = str(log_config.level)

        # Configure root logger
        root_logger = logging.getLogger()
        root_logger.setLevel(getattr(logging, default_level.upper(), logging.INFO))

        # Clear existing handlers
        for handler in root_logger.handlers[:]:
            root_logger.removeHandler(handler)

        # Create formatter
        formatter = logging.Formatter(log_config.format)

        # Add console handler if enabled
        if log_config.console_output:
            console_handler = logging.StreamHandler(sys.stdout)
            console_handler.setLevel(getattr(logging, default_level.upper(), logging.INFO))
            console_handler.setFormatter(formatter)
            root_logger.addHandler(console_handler)

        # Add file handler if enabled
        if log_config.file_output:
            log_file_path = Path(log_config.log_file)
            log_file_path.parent.mkdir(parents=True, exist_ok=True)

            file_handler = logging.FileHandler(log_file_path)
            file_handler.setLevel(getattr(logging, default_level.upper(), logging.INFO))
            file_handler.setFormatter(formatter)
            root_logger.addHandler(file_handler)

        self._is_configured = True

        # 계층적 로그 레벨 설정 적용
        if isinstance(log_config.level, dict):
            self._apply_hierarchical_logging(log_config.level)

        logging.getLogger(__name__).info("Logging system initialized successfully")

    def _apply_hierarchical_logging(self, level_config: Dict[str, str]):
        """계층적 로그 레벨 설정을 적용합니다."""
        for logger_name, level in level_config.items():
            if logger_name == "default":
                continue  # default는 이미 root logger에 적용됨
            log_level = getattr(logging, str(level).upper(), logging.INFO)
            logger = logging.getLogger(logger_name)
            logger.setLevel(log_level)

```