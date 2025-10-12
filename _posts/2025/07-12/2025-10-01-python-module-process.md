---
layout: post
title: Nexus 를 활용한 앱 관리
author: jblim0125
date: 2025-10-01
category: 2025
tags: [Python, Nexus, Import_module]
---

## 1. 개요

현재 Python(FastAPI) 을 이용해 LLM을 이용한 앱을 개발하고 있다.
최근 배포 및 코드 개발 및 관리에 어려움이 있어 방안을 고민하면서 이 글을 작성한다.

## 2. 현재 구조

보일러플레이트 코드와 앱 코드를 디렉토리 기준으로 분리하고, 동작하도록 설계되어 있다.

* Boilerplate  
    * 구성  
        - run.py - main 이자 uvicorn 을 활용한 fastapi 실행
        - api : fastapi 설정, RESTApi 정의, Response 처리
        - core : Config
        - service_util : Studio, ObjectStorage(Upload) 관련 
        - utils : rabbitmq, vector storage, minio 
    * App 실행 방식
        `from service.graph import graphio_app_flow` 형태로 service 에서 생성(컴파일)된 그래프`graphio_app_flow`를 호출하는 방식
* App : 
    services 디렉토리 내 graph.py 파일의 `graphio_app_flow` 인스턴스를 고정한 상태로
    node, edge, tool 등을 정의하고 코드들을 추가
    필요한 코드들을 모두 services 디렉토리에 위치시켜 개발 

### 배포 방식

현재 앱 배포는 2개의 과정이 있고, 각 과정은 다음과 같다.

#### 미리보기

1. service 디렉토리의 파일들과 requirements.txt 파일을 업로드
2. App-Platform 은 수신한 파일들을 보일러플레이트 코드가 위치한 곳에 파일들을 복사
3. requirements.txt 파일을 이용해 의존성 패키지 설치
4. 보일러플레이트 코드를 실행하여 앱 검증

#### 실행

1. 앱 기본 이미지(보일러플레이트) 활용
2. services 디렉토리 마운트
3. pip 를 이용해 패키지 설치
4. 앱 실행

### 장점

- 관심사 분리: 보일러플레이트(실행·인프라)와 App(도메인 로직) 디렉토리 분리로 역할 명확.
- 재사용성: 공통 유틸(rabbitmq, vector store, minio, 업로드) 재사용로 중복 감소.
- 개발자 경험: App은 graphio_app_flow만 제공하면 동작. 빠른 프리뷰 루프 가능.
- 배포 속도: 실행 단계에서 “기본 이미지 + services 마운트”로 이미지 재빌드 없이 핫스왑 가능.

### 단점

- 강한 결합: `from service.graph import graphio_app_flow`에 하드코딩. 
- 스케일링 제약: 단일 uvicorn 프로세스 전제에 가까움. 워커 수, 프로세스 모델, 오토스케일 전략 불명확.
- 배포 표준 미흡: CI/CD, 헬스체크, 롤백, 관측성(로그/메트릭/트레이싱) 언급 부재.

### 리스크

- 성능 변동성: 마운트 I/O + 최초 의존성 설치로 스타트업 지연.

### 개선 포인트(요약)

- 스케일링 프로필: gunicorn+uvicorn workers, 헬스체크/리드니스, 오토스케일 파라미터 명시.
- 플러그인화: MQ/스토리지/벡터스토어를 인터페이스화하고 프로바이더 주입.
- 엔트리포인트 확장: graphio_app_flow 검색 규약(엔트리포인트/모듈 디스커버리) 지원.

## 3. 변경 구조 

- 보일러플레이트 - 앱 연동 정의 : Interface
- Interface 상속, 프로바이더 형태로 앱을 개발
- 개발된 앱은 nexus 에 등록
- 앱 미리보기/실행 시 Nexus 정보(패키지 이름 및 버전)를 입력

### 구조

#### 보일러플레이트

- gunicorn + uvicorn + fastapi 를 이용한 코어 유지
- 앱 연동 : Nexus에 배포된 패키지를 `import_module`로 로드
- ENV(Yaml) 등 동적으로 dist_name(배포본 이름), module_path(임포트 경로), version_spec(예: >=1.2,<2) 을 적용하여 로드

**설정 예 (운영용)**

```yaml
# config/config.yml (운영 환경)
connect_app_info:
  dist_name: "javis"                    # pip/Nexus 배포 이름
  module_path: "javis.app"              # Nexus 패키지 내 모듈 경로
  version_spec: ">=1.2,<2"              # 버전 범위
  app_mode: "production"                # 운영 모드

# 또는 Robot 앱
connect_app_info:
  dist_name: "robot"
  module_path: "robot.app"
  version_spec: ">=2.1,<3"
  app_mode: "production"
```

**설정 예 (개발용)**

```yaml
# config/config.yml (개발 환경)
connect_app_info:
  # 개발 시에는 로컬 모듈 직접 로드
  dist_name: null                       # Nexus 패키지 체크 생략
  module_path: "src.app.javis.javis"    # 로컬 개발 경로
  version_spec: null                    # 버전 체크 생략
  app_mode: "development"               # 개발 모드
  local_path: "./src/app/javis"         # 로컬 앱 경로 (선택사항)

# 또는 Robot 앱 개발
connect_app_info:
  dist_name: null
  module_path: "src.app.robot.robot"
  version_spec: null
  app_mode: "development"
  local_path: "./src/app/robot"
```

**앱 로드**

# core/loader.py

```python
from importlib import import_module
from importlib.metadata import version, PackageNotFoundError
from packaging.specifiers import SpecifierSet
from fastapi import HTTPException
import sys
import os
from pathlib import Path

class ImplConfig:
    def __init__(self, dist_name=None, module_path=None, version_spec=None, 
                 app_mode="production", local_path=None):
        self.dist_name = dist_name
        self.module_path = module_path
        self.version_spec = SpecifierSet(version_spec) if version_spec else None
        self.app_mode = app_mode
        self.local_path = local_path

def load_app(cfg: ImplConfig):
    """개발/운영 환경에 따른 앱 로드"""
    
    if cfg.app_mode == "development":
        return _load_development_app(cfg)
    else:
        return _load_production_app(cfg)

def _load_development_app(cfg: ImplConfig):
    """개발 환경 앱 로드 - 로컬 모듈 직접 로드"""
    try:
        # 로컬 경로가 지정된 경우 sys.path에 추가
        if cfg.local_path:
            abs_path = os.path.abspath(cfg.local_path)
            if abs_path not in sys.path:
                sys.path.insert(0, abs_path)
        
        # 모듈 로드
        mod = import_module(cfg.module_path)
        
        # 모듈 리로드 지원 (개발 시 코드 변경 반영)
        import importlib
        importlib.reload(mod)
        
        app_class = getattr(mod, 'App')
        app = app_class()
        
        # 인터페이스 체크
        if not hasattr(app, "get_graph"):
            raise HTTPException(status_code=500, detail="app missing 'get_graph' method")
        
        return app
        
    except ImportError as e:
        raise HTTPException(
            status_code=500, 
            detail=f"Development module import failed: {e}"
        )

def _load_production_app(cfg: ImplConfig):
    """운영 환경 앱 로드 - Nexus 패키지 로드"""
    # 1) 배포본 버전 확인
    try:
        installed = version(cfg.dist_name)
    except PackageNotFoundError:
        raise HTTPException(
            status_code=503, 
            detail=f"'{cfg.dist_name}' not installed"
        )

    if cfg.version_spec and installed not in cfg.version_spec:
        raise HTTPException(
            status_code=503,
            detail=f"'{cfg.dist_name}' version {installed} not in spec '{cfg.version_spec}'"
        )

    # 2) 모듈 로드
    try:
        mod = import_module(cfg.module_path)
        app_class = getattr(mod, 'App')
        app = app_class()
        
        # 인터페이스 체크
        if not hasattr(app, "get_graph"):
            raise HTTPException(status_code=500, detail="app missing 'get_graph' method")
        
        return app
        
    except (ImportError, AttributeError) as e:
        raise HTTPException(
            status_code=500, 
            detail=f"Production module load failed: {e}"
        )
```

**코어: 라우터**

# core/routers/work.py
```python
from fastapi import APIRouter, Depends, HTTPException
from functools import lru_cache
from typing import Dict, Any
import time
import logging
from .config import settings
from interface.app_interface import AppResponse, GraphState

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/work")

@lru_cache
def _get_app():
    """앱 인스턴스 로드 (캐시됨)"""
    from core.loader import ImplConfig, load_app
    cfg = ImplConfig(**settings.work_impl)
    return load_app(cfg)

@router.post("", response_model=AppResponse)
def run_work(payload: Dict[str, Any], app=Depends(_get_app)):
    """작업 실행 - 보일러플레이트에서 Graph 실행과 응답 처리"""
    start_time = time.time()
    
    try:
        # 입력 검증
        if not payload.get("query"):
            return AppResponse(
                success=False,
                message="Query is required",
                error_code="INVALID_INPUT"
            )
        
        # Graph State 생성 (보일러플레이트에서 표준화)
        graph_state = GraphState(
            query=payload["query"],
            session_id=payload.get("session_id", "default"),
            context=payload.get("context", {})
        )
        
        # 외부 모듈에서 Graph 인스턴스 획득
        graph = app.get_graph()
        
        # Graph 실행
        result = graph.invoke(graph_state.dict())
        
        # 응답 생성 (보일러플레이트에서 표준화)
        execution_time = time.time() - start_time
        
        return AppResponse(
            success=True,
            data={
                "response": result.get("response"),
                "sources": result.get("sources", []),
                "confidence": result.get("confidence", 0.0),
                "metadata": result.get("metadata", {})
            },
            message="Request processed successfully",
            execution_time=execution_time
        )
        
    except Exception as e:
        execution_time = time.time() - start_time
        logger.error(f"Work execution failed: {e}")
        
        return AppResponse(
            success=False,
            message=f"Execution failed: {str(e)}",
            error_code="EXECUTION_ERROR",
            execution_time=execution_time
        )

@router.get("/info")
def get_app_info(app=Depends(_get_app)):
    """앱 정보 조회"""
    return app.get_info()

@router.get("/health")
def health_check(app=Depends(_get_app)):
    """헬스 체크"""
    try:
        graph = app.get_graph()
        return {"status": "healthy", "graph_available": graph is not None}
    except Exception as e:
        return {"status": "unhealthy", "error": str(e)}
```

**외부(앱) 모듈 인터페이스**

외부 모듈이 구현해야 하는 표준 인터페이스를 정의합니다. 이를 통해 보일러플레이트와 앱 간의 결합도를 낮추고 확장성을 확보합니다.

```python
# interface/app_interface.py
from abc import ABC, abstractmethod
from typing import Any
from langgraph.graph import CompiledGraph
from pydantic import BaseModel

class AppInterface(ABC):
    """외부 앱 모듈이 구현해야 하는 인터페이스"""
    
    @abstractmethod
    def get_graph(self) -> CompiledGraph:
        """
        LangGraph 컴파일된 그래프 인스턴스 반환
        
        Returns:
            CompiledGraph: 실행 가능한 그래프 인스턴스
        """
        pass
    
    @abstractmethod
    def get_info(self) -> dict:
        """
        앱 정보 반환 (버전, 설명 등)
        
        Returns:
            dict: 앱 메타데이터
        """
        pass

# 보일러플레이트에서 사용할 표준 응답 모델
class AppResponse(BaseModel):
    """앱 실행 결과 표준 응답 모델 (보일러플레이트에서 정의)"""
    success: bool
    data: Any = None
    message: str = None
    error_code: str = None
    execution_time: float = None

# 보일러플레이트에서 사용할 표준 상태 모델
class GraphState(BaseModel):
    """LangGraph 실행을 위한 표준 상태 모델 (보일러플레이트에서 정의)"""
    query: str
    session_id: str = "default"
    context: dict = {}
    response: str = None
    sources: list = []
    confidence: float = 0.0
    metadata: dict = {}
```

**외부(앱) 모듈: 구현**

실제 앱 모듈에서 인터페이스를 구현하는 예시입니다.

```python
# javis/app.py (외부 모듈)
import logging
from langgraph.graph import CompiledGraph
from interface.app_interface import AppInterface

logger = logging.getLogger(__name__)

class App(AppInterface):
    """JAVIS 앱 구현체 - Graph 인스턴스만 제공"""
    
    def __init__(self):
        self._graph = None
        self._initialize()
    
    def _initialize(self):
        """그래프 초기화"""
        try:
            from javis.graph import create_javis_graph
            self._graph = create_javis_graph()
            logger.info("JAVIS graph initialized successfully")
        except Exception as e:
            logger.error(f"Failed to initialize JAVIS graph: {e}")
            raise
    
    def get_graph(self) -> CompiledGraph:
        """컴파일된 그래프 인스턴스 반환"""
        if self._graph is None:
            raise RuntimeError("Graph not initialized")
        return self._graph
    
    def get_info(self) -> dict:
        """앱 정보 반환"""
        return {
            "name": "javis",
            "version": "1.2.0",
            "description": "JAVIS AI Assistant Application",
            "dependencies": {
                "langchain": ">=0.1.0",
                "openai": ">=1.0.0"
            },
            "graph_initialized": self._graph is not None
        }

# javis/graph.py (그래프 정의)
from langgraph import StateGraph
from javis.nodes import QueryProcessor, ResponseGenerator
from interface.app_interface import GraphState

def create_javis_graph():
    """JAVIS 그래프 생성 - 표준 GraphState 사용"""
    graph = StateGraph(GraphState)
    
    # 노드 추가
    graph.add_node("process_query", QueryProcessor())
    graph.add_node("generate_response", ResponseGenerator())
    
    # 엣지 추가
    graph.add_edge("process_query", "generate_response")
    
    # 진입점 설정
    graph.set_entry_point("process_query")
    graph.set_finish_point("generate_response")
    
    return graph.compile()

# javis/nodes.py (노드 구현 예시)
class QueryProcessor:
    """쿼리 처리 노드"""
    def __call__(self, state: dict) -> dict:
        # 쿼리 전처리 로직
        query = state.get("query", "")
        processed_query = query.strip().lower()
        
        return {
            **state,
            "processed_query": processed_query,
            "metadata": {"processing_step": "query_processed"}
        }

class ResponseGenerator:
    """응답 생성 노드"""
    def __call__(self, state: dict) -> dict:
        # 응답 생성 로직 (실제로는 LLM 호출 등)
        processed_query = state.get("processed_query", "")
        
        response = f"처리된 응답: {processed_query}"
        
        return {
            **state,
            "response": response,
            "confidence": 0.85,
            "sources": ["knowledge_base"],
            "metadata": {
                **state.get("metadata", {}),
                "generation_step": "response_generated"
            }
        }
```

**주요 변경 사항 정리**

1. **역할 분리 명확화**:
   - 외부 모듈: Graph 인스턴스만 제공 (`get_graph()`)
   - 보일러플레이트: Graph 실행, 상태 관리, HTTP 응답 처리

2. **표준화된 인터페이스**:
   - `GraphState`: 모든 그래프에서 사용할 표준 상태 모델
   - `AppResponse`: HTTP 응답을 위한 표준 모델
   - 실행 시간, 메타데이터 등 운영에 필요한 정보 포함

3. **간소화된 외부 모듈**:
   - HTTP 관련 로직 제거
   - 비즈니스 로직(Graph)에만 집중
   - 에러 처리는 보일러플레이트에서 담당

4. **향상된 보일러플레이트**:
   - 표준화된 Graph 실행 파이프라인
   - 통합된 에러 처리 및 로깅
   - 헬스체크, 앱 정보 조회 등 운영 기능

**패키지 구조와 배포**

```
javis/
├── setup.py              # 패키지 설정
├── requirements.txt       # 의존성
├── javis/
│   ├── __init__.py
│   ├── app.py            # App 클래스 (메인 진입점)
│   ├── graph.py          # LangGraph 정의
│   ├── nodes/            # 그래프 노드들
│   │   ├── __init__.py
│   │   ├── query_processor.py
│   │   └── response_generator.py
│   ├── state.py          # 그래프 상태 정의
│   └── utils/            # 유틸리티
└── tests/               # 테스트 코드
```

**setup.py 예시**

```python
from setuptools import setup, find_packages

setup(
    name="javis",
    version="1.2.0",
    description="JAVIS AI Assistant Application",
    packages=find_packages(),
    install_requires=[
        "langchain>=0.1.0",
        "openai>=1.0.0",
        "pydantic>=2.0.0"
    ],
    python_requires=">=3.9",
    entry_points={
        "console_scripts": [
            "javis=javis.cli:main",
        ],
    },
    classifiers=[
        "Development Status :: 4 - Beta",
        "Intended Audience :: Developers",
        "Programming Language :: Python :: 3.9",
    ]
)
```


## 4. 개발 환경 구성

### 디렉토리 구조

```
project/
├── src/
│   ├── boilerplate/                 # 보일러플레이트 코드
│   │   ├── run.py                   # FastAPI 실행 진입점
│   │   ├── core/
│   │   │   ├── __init__.py
│   │   │   ├── config.py            # 설정 로드
│   │   │   ├── loader.py            # 앱 로더 (개발/운영 지원)
│   │   │   └── routers/
│   │   │       ├── __init__.py
│   │   │       └── work.py          # API 라우터
│   │   ├── interface/
│   │   │   ├── __init__.py
│   │   │   └── app_interface.py     # 앱 인터페이스 정의
│   │   └── utils/                   # 공통 유틸리티
│   │       ├── rabbitmq.py
│   │       ├── vector_store.py
│   │       └── minio.py
│   └── app/                         # 앱 개발 디렉토리
│       ├── javis/
│       │   ├── __init__.py
│       │   ├── javis.py             # JAVIS 앱 (App 클래스)
│       │   ├── graph.py             # LangGraph 정의
│       │   ├── nodes/               # 그래프 노드들
│       │   │   ├── __init__.py
│       │   │   ├── query_processor.py
│       │   │   └── response_generator.py
│       │   └── utils/               # JAVIS 전용 유틸리티
│       └── robot/
│           ├── __init__.py
│           ├── robot.py             # Robot 앱 (App 클래스)
│           ├── graph.py             # Robot 전용 그래프
│           ├── nodes/               # Robot 노드들
│           └── utils/               # Robot 전용 유틸리티
├── config/
│   ├── config.yml                   # 메인 설정 파일
│   ├── config.dev.yml              # 개발용 설정
│   └── config.prod.yml             # 운영용 설정
├── tests/                           # 테스트 코드
│   ├── test_javis.py
│   └── test_robot.py
├── requirements.txt                 # 보일러플레이트 의존성
├── requirements.dev.txt            # 개발 의존성
└── docker-compose.yml              # 개발 환경 구성
```

### 개발 환경 설정

**config/config.dev.yml**

```yaml
# 개발 환경 설정
app:
  debug: true
  hot_reload: true
  log_level: "DEBUG"

# JAVIS 앱 개발 시
connect_app_info:
  dist_name: null                    # Nexus 체크 비활성화
  module_path: "src.app.javis.javis" # 로컬 모듈 경로
  version_spec: null                 # 버전 체크 비활성화
  app_mode: "development"
  local_path: "./src/app/javis"      # 모듈 검색 경로

# Robot 앱 개발 시 (설정 변경만으로 전환)
# connect_app_info:
#   dist_name: null
#   module_path: "src.app.robot.robot"
#   version_spec: null
#   app_mode: "development"
#   local_path: "./src/app/robot"

# 개발용 외부 서비스
database:
  url: "sqlite:///./dev.db"          # 로컬 SQLite

redis:
  url: "redis://localhost:6379"      # 로컬 Redis

vector_store:
  type: "local"                      # 로컬 벡터 스토어
  path: "./data/vectors"
```

**src/app/javis/javis.py (개발용 JAVIS 앱)**

```python
# src/app/javis/javis.py
import logging
from langgraph.graph import CompiledGraph
from src.boilerplate.interface.app_interface import AppInterface

logger = logging.getLogger(__name__)

class App(AppInterface):
    """JAVIS 앱 - 개발 환경용"""
    
    def __init__(self):
        self._graph = None
        self._initialize()
    
    def _initialize(self):
        """개발 환경에서 그래프 초기화"""
        try:
            # 상대 경로로 그래프 모듈 import
            from .graph import create_javis_graph
            self._graph = create_javis_graph()
            logger.info("JAVIS development graph initialized")
        except Exception as e:
            logger.error(f"Failed to initialize JAVIS graph: {e}")
            raise
    
    def get_graph(self) -> CompiledGraph:
        """그래프 인스턴스 반환"""
        if self._graph is None:
            raise RuntimeError("Graph not initialized")
        return self._graph
    
    def get_info(self) -> dict:
        """앱 정보 반환"""
        return {
            "name": "javis",
            "version": "dev",
            "description": "JAVIS AI Assistant (Development)",
            "mode": "development",
            "graph_initialized": self._graph is not None
        }
```

**src/app/robot/robot.py (개발용 Robot 앱)**

```python
# src/app/robot/robot.py
import logging
from langgraph.graph import CompiledGraph
from src.boilerplate.interface.app_interface import AppInterface

logger = logging.getLogger(__name__)

class App(AppInterface):
    """Robot 앱 - 개발 환경용"""
    
    def __init__(self):
        self._graph = None
        self._initialize()
    
    def _initialize(self):
        """Robot 그래프 초기화"""
        try:
            from .graph import create_robot_graph
            self._graph = create_robot_graph()
            logger.info("Robot development graph initialized")
        except Exception as e:
            logger.error(f"Failed to initialize Robot graph: {e}")
            raise
    
    def get_graph(self) -> CompiledGraph:
        """그래프 인스턴스 반환"""
        if self._graph is None:
            raise RuntimeError("Graph not initialized")
        return self._graph
    
    def get_info(self) -> dict:
        """앱 정보 반환"""
        return {
            "name": "robot",
            "version": "dev",
            "description": "Robot Control Assistant (Development)",
            "mode": "development",
            "graph_initialized": self._graph is not None
        }
```

### 개발 워크플로우

**1. 개발 환경 시작**

```bash
# 개발 환경 설정
export ENVIRONMENT=development
export CONFIG_PATH=./config/config.dev.yml

# 의존성 설치
pip install -r requirements.txt
pip install -r requirements.dev.txt

# 보일러플레이트 실행 (JAVIS 앱)
cd src/boilerplate
python run.py

# 또는 Robot 앱으로 전환 (config.dev.yml 수정 후)
python run.py
```

**2. 앱 전환 (JAVIS ↔ Robot)**

```bash
# config/config.dev.yml 에서 connect_app_info 섹션만 변경
# 서버 재시작하면 다른 앱으로 전환됨

# JAVIS 모드
connect_app_info:
  module_path: "src.app.javis.javis"
  local_path: "./src/app/javis"

# Robot 모드  
connect_app_info:
  module_path: "src.app.robot.robot"
  local_path: "./src/app/robot"
```

**3. 핫 리로드 개발**

```python
# core/loader.py 에서 개발 모드 시 모듈 리로드 지원
# 코드 변경 시 자동으로 새로운 버전 로드
import importlib
importlib.reload(mod)  # 개발 모드에서만 실행
```

**4. 테스트**

```bash
# 단위 테스트
pytest tests/test_javis.py
pytest tests/test_robot.py

# 통합 테스트
pytest tests/ -v

# 앱 전환 테스트
python scripts/test_app_switch.py
```

### 개발 고려사항

**1. 코드 격리와 재사용**
- 각 앱은 독립적인 디렉토리에서 개발
- 공통 유틸리티는 보일러플레이트에서 제공
- 앱별 전용 유틸리티는 각 앱 디렉토리 내에서 관리

**2. 설정 관리**
- 환경별 설정 파일 분리 (dev/prod)
- 설정 변경만으로 앱 전환 가능
- 민감 정보는 환경 변수로 관리

**3. 디버깅과 로깅**
- 개발 모드에서 상세 로깅 활성화
- 앱별 로거 네임스페이스 분리
- FastAPI 디버그 모드 지원

**4. 의존성 관리**
- 보일러플레이트 공통 의존성과 앱별 의존성 분리
- 개발용 도구들은 별도 requirements 파일로 관리
- 버전 충돌 방지를 위한 가상환경 사용

**5. 성능 고려사항**
- 개발 모드에서 모듈 리로드로 인한 메모리 사용량 증가 주의
- 그래프 초기화 시간 모니터링
- 로컬 개발 시 외부 의존성 최소화

## 5. 운영 환경 배포 및 관리

### 운영 배포 프로세스

**1. Nexus에 앱 패키지 업로드**

```bash
# JAVIS 앱 패키지화
cd src/app/javis
python setup.py sdist bdist_wheel

# Nexus에 업로드
twine upload --repository-url http://nexus.company.com/repository/pypi-hosted/ dist/*

# Robot 앱도 동일한 방식
cd src/app/robot
python setup.py sdist bdist_wheel
twine upload --repository-url http://nexus.company.com/repository/pypi-hosted/ dist/*
```

**2. 운영 서버에 패키지 설치**

```bash
# Nexus 인덱스 설정
pip install --extra-index-url http://nexus.company.com/repository/pypi-all/simple/ javis==1.2.0

# 또는 Robot 앱
pip install --extra-index-url http://nexus.company.com/repository/pypi-all/simple/ robot==2.1.0
```

**3. 운영 설정 및 배포**

```yaml
# config/config.prod.yml
app:
  debug: false
  log_level: "INFO"
  workers: 4

connect_app_info:
  dist_name: "javis"
  module_path: "javis.app"
  version_spec: ">=1.2,<2"
  app_mode: "production"

# 운영용 외부 서비스
database:
  url: "postgresql://user:pass@db.company.com:5432/app_db"

redis:
  url: "redis://redis.company.com:6379"

vector_store:
  type: "pinecone"
  api_key: "${PINECONE_API_KEY}"
```

**4. 앱 전환 및 롤백**

```bash
# 설정 변경으로 앱 전환
# config.prod.yml에서 connect_app_info만 수정
connect_app_info:
  dist_name: "robot"        # javis -> robot으로 변경
  module_path: "robot.app"
  version_spec: ">=2.1,<3"

# 서비스 재시작
systemctl restart app-service

# 롤백 시 이전 설정으로 복원 후 재시작
```

### 운영 팁

**1. 캐시 무효화**
```python
# 환경변수로 핫스왑 시 _handler.cache_clear() 호출 엔드포인트를 관리용으로 두기
@router.post("/admin/reload")
def reload_app():
    _get_app.cache_clear()
    return {"status": "cache cleared"}
```

**2. 권한 관리**
- 코어 프로세스에서 런타임 pip 설치는 권장하지 않음
- 배포 파이프라인에서 사전 설치

**3. 호환성 체크**
- 외부 모듈에 Requires-Python, 의존성 명시
- 충돌은 Nexus group로 해소

**4. 관측성**
- 로딩 결과를 /health에 노출(로드 성공 여부, 버전)
- 앱 전환 이벤트 로깅
- 성능 메트릭 수집

### 모니터링 및 관측성

**헬스체크 강화**

```python
@router.get("/health/detailed")
def detailed_health_check(app=Depends(_get_app)):
    """상세 헬스체크"""
    health_info = {
        "status": "unknown",
        "app_info": {},
        "dependencies": {},
        "performance": {}
    }
    
    try:
        # 앱 정보
        health_info["app_info"] = app.get_info()
        
        # 그래프 상태 확인
        graph = app.get_graph()
        
        # 성능 측정
        start_time = time.time()
        test_result = graph.invoke({
            "query": "health check test",
            "session_id": "health_check"
        })
        response_time = time.time() - start_time
        
        health_info["performance"] = {
            "response_time": response_time,
            "test_successful": test_result is not None
        }
        
        health_info["status"] = "healthy"
        
    except Exception as e:
        health_info["status"] = "unhealthy"
        health_info["error"] = str(e)
    
    return health_info
```

**메트릭 수집**

```python
from prometheus_client import Counter, Histogram

REQUEST_COUNT = Counter('app_requests_total', 'Total requests', ['app_name', 'status'])
REQUEST_DURATION = Histogram('app_request_duration_seconds', 'Request duration', ['app_name'])

@router.post("", response_model=AppResponse)
def run_work(payload: Dict[str, Any], app=Depends(_get_app)):
    app_info = app.get_info()
    app_name = app_info.get('name', 'unknown')
    
    start_time = time.time()
    try:
        # ... 기존 로직 ...
        REQUEST_COUNT.labels(app_name=app_name, status='success').inc()
        return response
    except Exception as e:
        REQUEST_COUNT.labels(app_name=app_name, status='error').inc()
        raise
    finally:
        REQUEST_DURATION.labels(app_name=app_name).observe(time.time() - start_time)
```

### CI/CD 파이프라인

```yaml
# .github/workflows/deploy.yml
name: Deploy Apps
on:
  push:
    branches: [main]
    paths: ['src/app/**']

jobs:
  detect-changes:
    runs-on: ubuntu-latest
    outputs:
      javis-changed: ${{ steps.changes.outputs.javis }}
      robot-changed: ${{ steps.changes.outputs.robot }}
    steps:
      - uses: actions/checkout@v2
      - uses: dorny/paths-filter@v2
        id: changes
        with:
          filters: |
            javis:
              - 'src/app/javis/**'
            robot:
              - 'src/app/robot/**'

  deploy-javis:
    needs: detect-changes
    if: needs.detect-changes.outputs.javis-changed == 'true'
    runs-on: ubuntu-latest
    steps:
      - name: Build and publish JAVIS
        run: |
          cd src/app/javis
          python setup.py sdist bdist_wheel
          twine upload dist/*

  deploy-robot:
    needs: detect-changes  
    if: needs.detect-changes.outputs.robot-changed == 'true'
    runs-on: ubuntu-latest
    steps:
      - name: Build and publish Robot
        run: |
          cd src/app/robot
          python setup.py sdist bdist_wheel
          twine upload dist/*
```

## 6. 결론

이 구조를 통해 다음과 같은 이점을 얻을 수 있습니다:

**개발 단계**:
- 로컬 환경에서 빠른 개발 및 테스트
- 앱별 독립적인 개발 환경
- 설정 변경만으로 앱 전환 가능

**운영 단계**:
- Nexus를 통한 체계적인 패키지 관리
- 버전 관리 및 롤백 지원
- 무중단 앱 전환 가능

**유지보수**:
- 명확한 관심사 분리
- 표준화된 인터페이스
- 확장 가능한 아키텍처

