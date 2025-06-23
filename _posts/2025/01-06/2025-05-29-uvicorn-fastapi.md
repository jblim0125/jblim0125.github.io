---
layout: post
title: FastAPI 와 Uvicorn
author: jblim0125
date: 2025-05-29
category: 2025
tags: [FastAPI, Uvicorn]
---

## Python Uvicorn & FastAPI 활용 정리

### FastAPI와 Uvicorn 개요

**FastAPI**  

- 최신 Python 기반 웹 프레임워크  
- 타입 힌팅, 자동 문서화(Swagger), 비동기 지원(Async/Await) 등 현대적 기능 지원  
- API 개발 생산성과 성능 모두를 만족

**Uvicorn**  

- ASGI(Asynchronous Server Gateway Interface) 기반 Python 웹 서버  
- 빠르고 가볍고, 비동기 처리를 효율적으로 지원  
- FastAPI와 매우 궁합이 잘 맞음

### FastAPI와 Uvicorn의 관계

- FastAPI는 ASGI 애플리케이션을 만듭니다.
- 실제 서비스 운영 환경에서는 WSGI가 아닌 **ASGI 서버**가 필요합니다.
- Uvicorn은 FastAPI를 실행하는 가장 대표적인 ASGI 서버입니다.

### FastAPI 애플리케이션 실행 방법

#### 직접 실행 (내장 서버 사용)

내장 서버(`uvicorn.run()`) 방식은 **개발용**입니다.
자세한 내용은 Gunicorn + Uvicorn Worker 방식 단락을 참고.

```python
from fastapi import FastAPI

app = FastAPI()

@app.get("/")
def read_root():
    return {"Hello": "World"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="127.0.0.1", port=8000, reload=True)
```

- reload=True 옵션으로 코드 변경 시 자동 재시작 가능
- 실제 배포 환경에서는 권장하지 않음

#### Uvicorn을 통한 실행 (권장)

터미널에서 직접 Uvicorn 명령어로 FastAPI 실행 (실제 서비스/운영에 적합)

```shell
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

- `main:app` : main.py 파일의 app 객체
- `--reload` : 개발용 옵션 (배포 환경에서는 빼는 것이 좋음)
- 운영 환경에서는 `--workers` 옵션으로 멀티프로세싱 가능

```shell
uvicorn main:app --host 0.0.0.0 --port 8000 --workers 4
```

#### Gunicorn + Uvicorn Worker 조합

Gunicorn은 WSGI 서버이지만, UvicornWorker를 활용해 ASGI 앱(FastAPI)도 실행 가능
대규모 서비스 운영에서 활용

```shell
gunicorn main:app -k uvicorn.workers.UvicornWorker --bind 0.0.0.0:8000 --workers 4
```

- Gunicorn의 안정적인 프로세스 관리와 Uvicorn의 비동기 성능 결합
- 대형 프로젝트/서비스에서 선호

#### ASGI 서버 종류와 선택

- Uvicorn: 가장 널리 쓰이며, FastAPI 공식 문서에서도 추천
- Hypercorn: HTTP/2, QUIC 등 다양한 프로토콜 지원
- Daphne: Django Channels에서 주로 사용
- Gunicorn + Uvicorn Worker: 대규모 서비스에서 안정성과 확장성을 모두 챙김
