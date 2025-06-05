---
layout: post
title: FastAPI 구조화
author: jblim0125
date: 2025-06-02
category: 2025
tags: [FastAPI]
---

## FastAPI 구조화

FastAPI는 파이썬의 타입 힌트와 데코레이터(어노테이션)를 적극적으로 활용해서 함수 단위로 API 엔드포인트를 정의하는 것이 특징입니다.

**주요 특징**  

1. 함수 단위 작성  
    - 각 API 엔드포인트는 일반적인 파이썬 함수로 작성합니다.  
    - 함수명, 파라미터, 반환값에 타입을 지정해주면 FastAPI가 이를 문서화하고, 요청/응답의 검증도 자동으로 해줍니다.  
2. 어노테이션(데코레이터) 사용  
    - @app.get(), @app.post(), @app.put() 등 HTTP 메서드에 맞는 데코레이터를 사용하여 라우팅을 설정합니다.
    - 예시:

        ```python
        from fastapi import FastAPI

        app = FastAPI()

        @app.get("/hello")
        def read_hello():
            return {"message": "Hello World"}
        ```

3. 타입 힌트
    - 파라미터와 반환값에 타입 힌트를 지정하면, FastAPI가 자동으로 데이터 검증, 문서화(Swagger, ReDoc)까지 해줍니다.

---

**문제점**  

개인적으로 프로그램의 덩치가 커지면 관리가 어려워 질 것으로 판담 됨.  
따라서 OOP 구조로 코드를 정리해서 작성하면 좋을 것 같아 다음과 같이 구조화를 진행
(아래 예시는 샘플)

```text
your_app/
│
├─ app/
│   ├─ __init__.py
│   ├─ main.py        # FastAPI 인스턴스 & 엔트리포인트
│   ├─ config.py      # 환경설정
│   ├─ logger.py      # 로거 세팅
│   ├─ db.py          # DB 연결 관리
│   └─ api/
│       ├─ __init__.py
│       └─ hello.py   # 예시 엔드포인트
│
└─ run.py             # uvicorn 실행 스크립트
```

## 샘플 코드

1. 'app/config.py'

    pydantic - `BaseSettings` 을 활용하여 `os.env`, `.env` 파일을 처리할 수 있도록 함.

    ```python
    from pydantic import BaseSettings

    class Settings(BaseSettings):
        db_url: str = "sqlite:///./test.db"
        log_level: str = "INFO"

    settings = Settings()
    ```

2. '/app/logger.py'

    ```python
    import logging

    def get_logger(name: str):
        logger = logging.getLogger(name)
        if not logger.hasHandlers():
            handler = logging.StreamHandler()
            formatter = logging.Formatter("[%(asctime)s] %(levelname)s - %(name)s - %(message)s")
            handler.setFormatter(formatter)
            logger.addHandler(handler)
        logger.setLevel(logging.INFO)
        return logger
    ```

3. 'app/db.py'

    ```python
    class Database:
        def __init__(self, db_url: str):
            self.db_url = db_url
            self.conn = None

        async def connect(self):
            # 실제 DB 연결로 바꿔서 사용하세요 (예: asyncpg, databases 등)
            print(f"Connecting to DB at {self.db_url}")
            self.conn = "connected"  # 예시

        async def disconnect(self):
            print("Disconnecting DB")
            self.conn = None

    db = Database("sqlite:///./test.db")
    ```

4. 'app/api/hello.py'

    ```python
    from fastapi import APIRouter

    router = APIRouter()

    @router.get("/hello")
    async def read_hello():
        return {"message": "Hello World"}
    ```

5. 'app/main.py'

    ```python
    from fastapi import FastAPI
    from app.config import settings
    from app.logger import get_logger
    from app.db import db
    from app.api.hello import router as hello_router

    logger = get_logger(__name__)

    class AppFactory:
        @staticmethod
        def create_app() -> FastAPI:
            app = FastAPI(
                title="OOP FastAPI Sample",
                lifespan=AppFactory.lifespan
            )
            app.include_router(hello_router)
            return app

        @staticmethod
        async def lifespan(app: FastAPI):
            # 앱 시작 시
            logger.info("App starting... Connecting DB.")
            await db.connect()
            yield
            # 앱 종료 시
            logger.info("App shutting down... Disconnecting DB.")
            await db.disconnect()

    app = AppFactory.create_app()
    ```

6. 'run.py'

    ```python
    import uvicorn

    if __name__ == "__main__":
        uvicorn.run(
            "app.main:app",
            host="0.0.0.0",
            port=8000,
            reload=True
        )
    ```

## Database 관련

끝으로 FastAPI의 의존성 주입 기능을 활용하여 처리할 수 없는 부분들도 있어
글로벌로 데이터베이스를 관리하고, 커넥션 풀에서 할당받아 동작하도록 구성한 샘플을 기록용으로 남긴다.

```python
import asyncio
import logging
from contextlib import asynccontextmanager
from typing import Optional

logger = logging.getLogger("client_pool")

# 예시 클라이언트 (DB/외부 API/등등)
class AsyncDBClient:
    def __init__(self, conn_id):
        self.conn_id = conn_id
        self.closed = False

    async def query(self, sql):
        # 실제 쿼리 수행
        return f"result from {self.conn_id}: {sql}"

    async def close(self):
        self.closed = True
        logger.info(f"Closed connection: {self.conn_id}")

class ClientPool:
    def __init__(self, size: int = 5):
        self.size = size
        self.pool = asyncio.Queue(maxsize=size)
        self._initialized = False

    async def init_pool(self):
        if self._initialized:
            return
        for i in range(self.size):
            await self.pool.put(AsyncDBClient(f"conn-{i+1}"))
        self._initialized = True
        logger.info(f"Initialized client pool with {self.size} connections.")

    async def acquire(self, timeout: Optional[float] = None) -> AsyncDBClient:
        try:
            if timeout:
                client = await asyncio.wait_for(self.pool.get(), timeout)
            else:
                client = await self.pool.get()
            logger.debug(f"Acquired client {client.conn_id}")
            return client
        except asyncio.TimeoutError:
            logger.error("Timed out while waiting for a free client from the pool.")
            raise

    async def release(self, client: AsyncDBClient):
        if client.closed:
            # 필요하다면 새 커넥션을 만들어서 pool에 보충
            logger.warning(f"Released client {client.conn_id} is closed. Creating new connection.")
            client = AsyncDBClient(client.conn_id)
        await self.pool.put(client)
        logger.debug(f"Released client {client.conn_id} back to pool")

    async def close_all(self):
        while not self.pool.empty():
            client = await self.pool.get()
            await client.close()
        logger.info("All clients in the pool are closed.")

    @asynccontextmanager
    async def get_client(self, timeout: Optional[float] = None):
        client = await self.acquire(timeout)
        try:
            yield client
        finally:
            await self.release(client)

# 전역 pool 인스턴스
client_pool = ClientPool(size=5)
```
