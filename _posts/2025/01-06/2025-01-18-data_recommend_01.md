---
layout: post
title: 추천 시스템
author: jblim0125
date: 2025-01-18
category: 2025
---

## 추천 시스템의 구조

추천 시스템의 전체적인 구조는 후보를 생성하는 단계와 랭킹을 매기는 단계로 구분된다.

### 후보 생성하는 단계

수백만개의 아이템 중 사용자의 활동 기록을 기반으로 후보가 될 만한 수백 여개의 아이템으로 선정하는 단계이다.
이러한 후보는 일반적으로 높은 정밀도로 사용자와 관련이 있고 협업 필터링(사용자간의 유사성)을 통해서만 광범위한 개인화를 제공한다.
리스트에서 최상의 리스트를 제시하기 위해서는 recall이 높은 후보 간의 상대적 중요성을 구분하기 위해 세밀한 수준의 표현이 필요하다.

### 랭킹을 매기는 단계

아이템과 사용자를 설명하는 Feature을 사용하여 원하는 목적 함수에 따라 각 아이템에 점수를 할당하여 가장 높은 점수를 받은 아이템이 점수에 따라 순위가 매겨져 사용자에게 표시된다.

![alt text](/assets/images/recommend/image-1.png)

### 추천 시스템의 종류

1. Contents-based Recommender System (컨텐츠 기반 추천시스템)

    사용자가 과거에 좋아했던 아이템을 파악하고 그 아이템과 비슷한 아이템을 추천한다.
    예시) '부산행'에 5점 평점을 준 사용자 → '명량' 보다는 '반도'를 더 좋아할 것이다.
    a. 사용자가 과거에 접한 아이템이면서 만족한 아이템
    b. 사용자가 좋아했던 아이템 중 일부 또는 전체와 비슷한 아이템 선정
    c. 선정된 아이템을 유저에게 추천

    ![alt text](/assets/images/recommend/image-2.png)

    Input : 사용자의 Item들에 대한 등급
    Output : 사용자의 등급 매기는 행위에 맞는 classifier를 생성

2. Collaborative Filtering Recommemder System (협업필터링 추천시스템)

    유사한 성향 또는 취향(관심사)을 갖는 다른 사용자가 좋아한 아이템을 현재 사용자에게 추천  
    예시) '부산행'에 5점 평점을 준 2명의 사용자 A, B -> 사용자 A가 과거 좋아했던 '반도'를 유저 B에게 추천
    a. 사용자 A와 사용자 B 모두 같은 아이템에 대해 비슷한 또는 같은 평가를 했다.  
    b. 이때, 사용자 A는 다른 아이템에도 비슷한 호감을 나타냈다.  
    c. 따라서, 사용자 A, B의 성향을 비슷할 것이므로, 다른 아이템을 사용자 B에게 추천한다.  

    Implicit Feeback이 적절  
    Input : 아이템들에 대한 사용자들의 등급  
    Output : 사용자와 비슷한 다른 사용자들을 판별, 그들의 아이템 등급  
    Steps :  
    a. 사용자-아이템 평가 매트릭스 만들기  
    b. 사용자-사용자 유사성 메트릭스, 코사인 유사도 계산  
    c. 유사한 사용자 탐색  
    d. 후보자 생성(유사한 사용자가 접한 아이템들의 ranking을 살핌)  
    e. 후보자 점수화(유사한 사용자가 가장 좋아하는 아이템부터 덜 좋아하는 책까지 순위 매김)  
    f. 후보 필터링 (이미 사용자가 접한 아이템은 제거)  

    - Memory-based  
      사용자가 아이템을 좋아하거나 평가했는지 또는 특정 사용자가 항목을 좋아하거나 평가했는지 여부와 같은 사용자 행동을 관찰한다.
      전처리 없이 raw-data에 적용한다. 구현하기 쉽고 추천 결과를 설명하기 쉽다는 장점이 있다.

      - User-based
          사용자와 유사한 사용자가 '구매/좋아요' 했다는 사실을 기반으로 사용자에게 추천
          ![alt text](/assets/images/recommend/image-6.png)

      - Item-based  
          "이 항목을 좋아한 사용자가 ###도 좋아했습니다".  
          사용자는 마음을 바꿀 수 있기 때문에 User-based(사용자 기반)보다 더 안정적이며 새로운
          사용자가 사이트를 방문한 경우, User-based보다 더 나은 방식이다.  

          ![alt text](/assets/images/recommend/image-5.png)

    - Model-based
      데이터가 아닌 모델을 기반으로 작업 속도를 높이는 추천시스템을 제공하고 더 나은 확장성을 제공한다. 차원 축소가 자주 사용되며
      이 접근법의 가장 유명한 유형은 행렬 분해이다.

      - Matrix Factorization(행렬 분해)  
        사용자로부터 피드백이 있는 경우, 사용자가 특정 영화를 보거나 특정 책을 읽고 등급을 부여한경우
        각 행은 특정 사용자를 나타내고 각 열은 특정 아이템을 나타내는 행렬 형식으로 나타낼 수 있습니다.
        사용자가 모든 아이템을 평가하는 것은 거의 불가능하므로 이 매트릭스에는 채워지지 않은 값이 많이 있습니다.
        이를 희소성(Sparsity)이라고 합니다. 매트릭스 분해 방법은 잠재 요인 세트를 찾고 이러한 요인을 사용하여 사용자
        선호도를 결정하는 데 사용됩니다. 잠재 정보는 사용자 행동을 분석하여 알 수 있다.  
        1. 랜덤 사용자-아이템 매트릭스 초기화  
        2. rating 매트릭스는 사용자의 매트릭스와 트랜스포스된 아이템 매트릭스를 곱해 얻음  
        3. Matrix Factorization의 목표는 loss 함수를 최소화하는 것(예측 행렬과 실제 행렬의 rating 차이가 최소화)  

        ![alt text](/assets/images/recommend/image-3.png)

3. Hybrid Recommemder System  

    Content-based와 Collaborative Filtering의 장, 단점을 상호보안
    Collaborative Filtering은 새로운 아이템에 대한 추천 부족, 이에 Content-based 기법이 Cold-start 문제에 도움을 줄 수 있음.

    |  | 장점 | 단점 |
    |---|---|---|
    |Content Based|1. 첫번재 평가자에 대한 딜레마 없음 (Cold-start dilemma X) <br> 2. 다른 사용자의 도움 없이 적절한 추천 받음 (User liberty) <br> 3. 새로운 아이템에 대한 추천을 위해 해당 아이템을 rating할 필요가 없음 <br> 4. Scarcity 영향 없음 <br> 5. 사용자의 프로필 변경 및 업데이트를 모니터링하여 많은 사용자의 관심도나 관심도 변화 문제를 해결하는 데 실용적이다. <br> 6. 더 적은 데이터로 동작 | 1. 제한된 콘텐츠 분석 <br> 2. Overspecialization <br>(시스템은 사용자 프로필에 대해 높은 점수를 받은 항목만 추천할 수 있음. 사용자는 이미 평가된 항목과 유사한 항목으로 추천) <br> 3. 너무 다르거나 비슷한 아이템을 설명할 수 없음. <br> 4. 복잡한 관계를 해석할 수 없음 5. 계산 비용이 많이 듦 <br> 6. 동의어 또는 동음이의어 때문에 위기에 직면 <br>7. 일부 유형의 아이템 콘텐츠는 분석하기 쉽지 않음 <br> 8. 사용자는 자신의 과거 경험과 유사한 항목만 받을 수 있음 (사용자를 놀라게 할 수 없음) |
    | Collaborative Filtering | 1. 콘텐츠 정보가 필요로 하지 않음 <br> 2. 사용자는 이전에 연락한 적이 없지만 관심이 있는 항목을 받을 수 있음(사용자를 놀라게 할 수 있음) <br> 3. 다른 사용자의 점수는 시스템에 변경 사항이 포함되어 있기 때문에, deterministic 결과로 사용하진 않음 (시간이 지남에 따라 향상된 Adaptive Quality) <br> | 1. rating 데이터 필요 <br> 2. Sparse 데이터로 추천할 수 없음 <br> 3. 확장성 문제 <br> 4. Cold-start dilemma (신규 사용자(커뮤니티) 및 신규 아이템 문제) <br> 5. 엄청나게 많은 아이템 세트와 적은 수의 사용자로 인해 성능이 저하됨 <br> 6. 품질은 대량의 데이터 수집에 달려 있음 <br> 7. 취향이 특이한 유저에게 추천하기 어렵다 <br> 8. 선호도가 변하거나 포함된 사용자를 클러스터링하고 분류하는 것은 어려움 |

    ![alt text](/assets/images/recommend/image-4.png)

4. Other Recommemder System  
    - Context-based Recommendation
        - Context-aware Recommendaton System
        - Location-based Recommendaton System
        - Real-time or Time-Sensitive Recommendation System
    - Community-based Recommendation
        - 사용자의 친구 또는 속한 커뮤니티의 선호도를 바탕으로 추천
        - SNS 등의 뉴스피드 또는 SNS 네트워크 데이터 등 활용
    - Knowledge-based Recommendation
        - 특정 도메인 지식을 바탕으로 아이템의 Features를 활용한 추천
        - Case-based Recommendation : 사용자의 니즈(현재 문제 등)와 해결책 중 가장 적합한 것을 골라서 추천
        - Constraint-based Recommendation : 사용자에게 추천할 때, 정해진 규칙을 바탕으로 추천 