---
layout: post
title: ElasticSearch 클러스터 구성과 한글 검색 최적화
author: jblim0125
date: 2025-01-10
category: 2025
---

## 개요

Elasticsearch(또는 OpenSearch)는 클러스터로 구성 시 데이터를 분산 저장하고 검색 속도를 극대화할 수 있다.  

## 클러스터 구성

클러스터는 여러 개의 노드로 구성되며, 각 노드는 데이터를 저장하고 쿼리를 처리하는 역할을 합니다.

1. 클러스터 노드 유형  
    - Master Node: 클러스터 상태 관리 및 작업 조율.
    - Data Node: 데이터 저장 및 검색 작업 처리.
    - Ingest Node: 데이터 전처리 파이프라인 관리.
    - Coordinating Node: 클라이언트 요청을 분산 처리.

2. 설정 방법  
    각 노드의 elasticsearch.yml (또는 OpenSearch 설정 파일)에서 노드 유형 지정:

    ```config
    node.roles: [master, data]  # 필요한 역할 설정
    cluster.name: my-cluster
    node.name: node-1
    network.host: 0.0.0.0
    discovery.seed_hosts: ["node1:9300", "node2:9300"]
    cluster.initial_master_nodes: ["node1", "node2"]
    ```

    *Docker를 사용한다면 노드별로 컨테이너를 분리하고 설정을 적용.*  

## 데이터 분산 저장

데이터를 분산 저장하려면 다음을 고려합니다.

1. Shard 및 Replica
    - 데이터를 샤드(Shard)로 분할하여 클러스터의 각 노드에 분산 저장.
    - Replica를 설정하여 고가용성과 내결함성을 확보.

2. 해시 기반 분산
    Elasticsearch/OpenSearch는 내부적으로 `Consistent Hashing 알고리즘`을 사용하여 데이터가 어느 샤드에 저장될지 결정합니다.
    특정 필드로 검색이 잦은 경우 특정 필들의 `routing` 을 이용해 분산 저장하고 빠른 검색 결과를 받을 수 있다.
    Routing Key를 사용:

    ```http
    PUT /my-index/_doc/1?routing=user123
    {
        "user": "user123",
        "message": "Hello, world!"
    }
    ```

    *Routing Key를 설정하면 동일한 Key에 해당하는 데이터는 항상 동일한 샤드에 저장.*

## 비동기 검색 구현

비동기 검색은 대량 데이터 검색 시 클라이언트의 대기 시간을 줄이고 응답 속도를 개선하는 데 유용하다.

1. Scroll API  
    대량 데이터 검색 시 Scroll API를 사용하여 결과를 분할하여 처리.

    ```http
    POST /my-index/_search?scroll=1m
    {
        "size": 100,
        "query": {
            "match_all": {}
        }
    }
    ```

    *응답의 _scroll_id를 사용하여 추가 페이지 요청*

    ```http
    POST /_search/scroll
    {
        "scroll": "1m",
        "scroll_id": "DXF1ZXJ5QW5..."
    }
    ```

## 데이터 저장 - 검색엔진 저장

**매핑(mapping)이란?**  

엘라스틱서치에서 매핑은 인덱스의 필드와 그 필드의 데이터 유형, 분석 방법을 정의하는 과정입니다. 매핑은 데이터를 효과적으로 저장하고 검색 결과를 최적화하는 데 중요한 역할을 합니다.  

**매핑의 주요 요소**  

1. 필드 유형 (Field Types):  
    - 데이터의 종류를 지정 (예: text, keyword, integer, date 등).  
2. 텍스트 분석기 (Analyzer):  
    - 텍스트 필드를 색인할 때 사용할 분석기를 정의 (예: standard, whitespace, n-gram).  
3. 속성 (Attributes):  
    - index: 필드를 색인할지 여부를 지정.  
    - store: 데이터를 저장할지 여부를 지정.  
    - boost: 특정 필드의 검색 중요도를 조정.  
4. Nested 및 Object 필드:  
    - JSON 구조를 그대로 유지하면서 계층 구조 데이터를 저장.  

**자연어 검색을 위한 매핑 전략**  

자연어 검색을 지원하려면 아래와 같은 설정을 매핑에 포함해야 합니다:

1. 필드 유형 설계  
    - text: 긴 텍스트를 색인하고 검색할 때 사용.
    - keyword: 정렬, 필터링, 정확한 일치를 위해 사용.
    - date: 날짜 데이터 처리.
    - float/integer: 수치 데이터 처리.

2. 검색 최적화를 위한 분석기 설정  
    - 기본적으로 standard 분석기를 사용하되, 필요 시 다음 분석기를 추가:  
    - n-gram 분석기: 부분 단어 검색(오타 대응).  
    - custom analyzer: 불용어 제거, 어근 추출 등을 포함한 맞춤형 분석기.  

3. 멀티-필드(Multi-Field) 설정
    - 하나의 필드를 다양한 방식으로 색인해 사용자의 다양한 검색 방식에 대응.
    - 예: title 필드를 text와 keyword 두 방식으로 색인.

**예제 : 매핑 정의**  

문서, 이미지, 영상 메타데이터 예제 매핑

```http
PUT /media_metadata
{
  "mappings": {
    "properties": {
      "title": {
        "type": "text",
        "fields": {
          "keyword": {
            "type": "keyword"
          }
        },
        "analyzer": "standard"
      },
      "description": {
        "type": "text",
        "analyzer": "standard"
      },
      "tags": {
        "type": "keyword"
      },
      "author": {
        "type": "text",
        "fields": {
          "keyword": {
            "type": "keyword"
          }
        }
      },
      "created_at": {
        "type": "date"
      },
      "file_type": {
        "type": "keyword"
      },
      "resolution": {
        "type": "text",
        "fields": {
          "keyword": {
            "type": "keyword"
          }
        }
      },
      "location": {
        "type": "geo_point"
      },
      "content_analysis": {
        "type": "nested",
        "properties": {
          "object_detected": {
            "type": "text"
          },
          "scene": {
            "type": "text"
          }
        }
      }
    }
  }
}
```

**매핑의 주요 부분 설명**  

1. title와 description:
    - text 타입으로 설정하여 자연어 검색이 가능하도록 함.
    - keyword 필드를 추가해 정확한 일치 검색을 지원.
2. tags:
    - keyword 타입으로 설정하여 필터링 및 정렬에 최적화.
3. author:
    - 검색과 정렬을 위해 멀티 필드로 설정.
4. location:
    - geo_point 타입으로 설정하여 지도 기반 검색 가능.
5. content_analysis:
    - nested 타입으로 설정해 계층적 데이터 구조를 색인.

**검색 최적화를 위한 추가 팁**  

1. Boosting:
    - 중요한 필드에 가중치를 부여해 검색 결과를 우선시.

    ```json
    "query": {
        "multi_match": {
            "query": "example",
            "fields": ["title^3", "description", "tags^2"]
        }
    }
    ```

    title 필드에 가중치 3배, tags에 2배를 적용.

2. Fuzzy Search:  
   - 오타를 포함한 검색 지원.

    ```json
    "query": {
        "match": {
            "title": {
                "query": "exampl",
                "fuzziness": "AUTO"
            }
        }
    }
    ```

3. Custom Analyzer 사용:  
   - 불용어 제거 및 어근 추출.

    ```http
    PUT /media_metadata
    {
        "settings": {
            "analysis": {
                "analyzer": {
                    "custom_analyzer": {
                        "type": "custom",
                        "tokenizer": "standard",
                        "filter": ["lowercase", "stop", "porter_stem"]
                    }
                }
            }
        },
        "mappings": {
            "properties": {
            "description": {
                    "type": "text",
                    "analyzer": "custom_analyzer"
                }
            }
        }
    }
    ```

## 한글 분석기 필요성

검색엔진에서 한글 분석기(예: 노리)를 추가해야 하는 이유는 한글의 고유한 언어적 특성을 효과적으로 처리하여 검색 품질을 높이고 데이터 분석을 정확하게 수행하기 위함입니다. 구체적인 이유는 다음과 같습니다:

1. 한국어의 특수성 처리  
    - 한국어는 조사, 어미 변화, 어근 등이 다양하게 조합되며, 이를 제대로 분석하지 않으면 정확한 검색 결과를 얻기 어렵습니다.  
    - 예를 들어, “먹다”, “먹고”, “먹으면” 등의 단어는 어근은 같지만 형태가 다릅니다. 한글 분석기는 이를 **어근(먹)**으로 추출하여 유사 단어를 효과적으로 검색할 수 있도록 돕습니다.  

2. 형태소 분석 지원
    - 한글 분석기는 한국어를 형태소 단위로 분리하여 의미 단위별로 인덱싱하고 검색이 가능하도록 합니다.  
    - 예: “학교에 갔다” → [“학교”, “에”, “가다”]  
    이를 통해 불필요한 문맥 차이로 인한 검색 누락을 방지할 수 있습니다.  

3. 어휘 다양성 처리  
    - 한국어에는 복합어와 합성어(예: “자동차” + “수리” = “자동차수리”)가 많아 이를 적절히 분리하거나 통합하지 않으면 검색 결과가 정확하지 않을 수 있습니다.  
    - 노리 분석기는 복합어를 분리하거나 검색어를 확장하여 더 나은 결과를 제공합니다.  

4. 문서 검색 성능 개선  
    - 한글 문서는 단순히 띄어쓰기로만 단어를 구분할 수 없기 때문에, 일반적인 분석기로는 검색 성능이 저하될 수 있습니다.  
    - 한글 분석기를 사용하면 불용어 처리, 중의성 해소, 단어 빈도 계산 등이 가능해져 검색 정확도와 성능이 크게 개선됩니다.  

5. 한글 사용자 경험 향상  
    - 한글 검색에 특화된 분석기를 사용하면 사용자 검색 의도에 맞는 결과를 제공할 수 있어, 검색 시스템의 사용자 경험(UX)을 크게 향상시킬 수 있습니다.  

6. 다양한 활용 가능성  
    - 데이터 분석: 텍스트 데이터에서 키워드 추출, 연관어 분석 등 고급 분석이 가능해집니다.  
    - 로그 분석: 한글 로그 데이터의 검색 및 분석이 쉬워집니다.  

결론적으로, 한글 분석기를 추가하면 한국어 데이터를 보다 정확하고 효율적으로 처리할 수 있으며, 이는 검색 품질 개선과 데이터 활용 가능성을 극대화하는 데 크게 기여합니다.  

## 한글 분석기 설정

한글 텍스트를 처리하기 위해서는 한글 특성에 맞는 `custom analyzer`를 설정해야 합니다. 한글은 형태소 기반 언어이기 때문에, 일반적인 토크나이저 대신 한글 전용 토크나이저(예: Nori 분석기)를 사용하는 것이 적합합니다.

아래는 한글 텍스트 처리를 위한 엘라스틱서치 Custom Analyzer 설정 예제입니다.

한글 Custom Analyzer 설정 예제

```http
PUT /korean_text_index
{
  "settings": {
    "analysis": {
      "tokenizer": {
        "nori_user_dict": {
          "type": "nori_tokenizer",
          "user_dictionary": "user_dict.txt" 
        }
      },
      "analyzer": {
        "korean_analyzer": {
          "type": "custom",
          "tokenizer": "nori_user_dict",
          "filter": ["lowercase", "nori_part_of_speech", "synonym_filter"]
        }
      },
      "filter": {
        "nori_part_of_speech": {
          "type": "nori_part_of_speech",
          "stoptags": ["E", "IC", "J", "MAG", "MM", "SP", "SSC", "SSO", "SC", "SE", "XPN", "XSA", "XSN", "XSV"]
        },
        "synonym_filter": {
          "type": "synonym",
          "synonyms": [
            "빨리, 신속히",
            "영화, 동영상",
            "자동차, 차량"
          ]
        }
      }
    }
  },
  "mappings": {
    "properties": {
      "title": {
        "type": "text",
        "analyzer": "korean_analyzer",
        "search_analyzer": "korean_analyzer"
      },
      "description": {
        "type": "text",
        "analyzer": "korean_analyzer",
        "search_analyzer": "korean_analyzer"
      }
    }
  }
}
```

설정 설명:

1. nori_tokenizer:  
    - 엘라스틱서치에서 제공하는 한글 형태소 분석기.  
    - user_dictionary를 활용하여 사용자 정의 사전을 추가할 수 있음.  
2. 사용자 정의 사전 (Optional):  
    - 사용자 정의 사전 파일(user_dict.txt)을 통해 자주 사용되거나 특정 도메인 단어를 명시적으로 정의.  
    - 예시 (user_dict.txt 파일 내용):  

    ```text
    엘라스틱
    검색엔진
    머신러닝
    ```

3. nori_part_of_speech 필터:
    - 특정 품사를 제거.  
    - 예: 조사(J), 부사(MAG), 접두사(XPN) 등 불필요한 품사를 제외하여 검색 결과를 정교화.  
4. synonym_filter:  
    - 동의어 처리를 통해 다양한 검색어 대응.  
    - 예: “자동차”를 검색하면 “차량”도 검색 결과에 포함.  
5. Analyzer 사용 위치:
    - **title**와 description 필드에 설정된 korean_analyzer를 사용해 텍스트를 색인 및 검색.

### 추가 설정 및 테스트

1. 샘플 데이터 삽입

    ```http
    POST /korean_text_index/_doc
    {
    "title": "자동차와 머신러닝",
    "description": "이 영화는 매우 신속히 진행된다."
    }
    ```

2. 검색 테스트

    ```http
    POST /korean_text_index/_search
    {
    "query": {
        "match": {
        "description": "빨리"
        }
    }
    }
    ```

    결과: “빨리”는 “신속히”와 동의어로 처리되어 검색에 포함.

추가 참고
    - 한글 데이터를 효과적으로 처리하려면 user_dictionary와 stoptags를 데이터 도메인에 맞게 조정하는 것이 중요합니다.
    - 한글 외의 다국어 데이터가 포함된 경우에는 별도의 분석기를 추가 설정해야 합니다.
