# SaaS 멀티 테넌트 아키텍처 핵심 정리

## SaaS 에서의 Tenant 란?

인프라를 사용하는 User / 고객

* Single-tenant  
  각 각의 사용자에게 독립적인 인프라를 제공하는 방식  
  장점 : 성능 / 보안(격리된 환경)  
  단점 : 비용  

* Multi-tenant  
  하나의 인프라를 여러 사용자(고객사)가 사용할 수 있도록 제공하는 방식  
  단점 : 설계, 개발(보안), 성능
  성능에 문제 발생 시 -> 사용량 제한과 여러 사

## SaaS Identity

			SaaS Identity
	User Identity		Tenant Identity
		  |					   |
		User				Tenant
		
	User가 Tenant에 소속된?
	
	Tenant 의 속성?
		ID, 정책, 상태, 과금 티어?
		
	로그인 인증 후 토큰 발급 시 Tenant 정보를 추가하여 하위 서비스(micro service)매번 
	사용자 인증 서버와 통신이 발생하지 않도록 한다.
	
## 멀티테넌트의 핵심 - Isolation

격리는 필수
	
Resource 격리 뿐만 아니라, 다양한 격리 수준이 있다.
Account, VPC 등으로 분리될 수 있다.
모든 리소스가 공유되더라도, Policy를 통해 격리할 수 있다.
	
Technical 적으로도 격리 수준을 정할 수 있다.

## Isolation 종류

* Silo Isolation - single tenant  
  * 모두 독립된 환경(인프라)  
    * 장  
      컴플라이언스 요건을 충족하기 용이  
      noisy neighbor 문제 감소  
      테넌트별 비용 추적 용이  
      장애 발생 시 확대 억제 가능  
    * 단
      고객이 늘어나게 되면 스케일링이 힘듬
      중복된 리소스 사용으로 비용 증가
      기능을 추가할 때 반영속도 저하
      리소스 온보딩 자동화가 필요
      관리와 모니터링 중앙화 고려 필요

* Pool Isolation
  * 하나의 환경(인프라)를 소프트웨어 적으로 분리(격리)
    * 장
      새로운 기능 빠르게 추가 가능
      비용 효율적으로 사용 가능
      관리와 운영 단순화
    * 단  
      Noisy Neighbor 문제 발생  
      테넌트 비용 추적이 어려움  
      장애전파되기 쉬움  
      컴프라이언스 요구 사항을 못 맞출수 있음(분리[격리] 어려움)  

* Bridge Isolation  
  공통 사용이 가능한(Proxy Frontend)은 여러 Tenant 가 같이 사용하고  
  분리가 필요한(Database와 같은) 서비스들은 Tenant별로 분리하여 사용  

* 번외  
	Tier Based Isolation
		티어 별로 Isolation을 제공
			Silver Tier 는 Pool Isolation
			Gold Tier는 Silo Isolation 
		
	VPC Silo Isolation
		Tenant Router를 이용해 Tenant별 각 VPC로 연결
		
	Compute Silo Isolation
		Kubernetes 를 이용한 (Namespace)별 격리(Tenant)
	


# SaaS 모델 전환 전략

기술적, 비즈니스적 2가지 관점에서 전환에 대해서 알아보자.

기술적 마이그레이션 - 비즈니스적인 부분에 대한 고려하고, 민첩한 
민첩성 | 	개발, 	배포, 	운영
			세일즈, 마케팅, 고객성공


좋은 SaaS 아키텍처는 테넌트 마다 개별젹인 아티팩트를 갖기보다 신속하게 테넌트를 온보딩하고, 
서비스를 업데이트할 수 있도록 하는 효율성과 민첩함을 우선시 함.

SaaS 에서 제일 어렵? 중요한 부분
메트릭과 분석, 빌링과 미터링
(특히, isolation이 확실하지 않은 환경에서)

SaaS 의 진화
1. 고객 별 서로 다른 버전이 각기 다른 환경에서 동작
2. 하나의 버전을 환경설정을 통해 각기 다른 환경에서 동작
3. 환경 설정과 테넌트를 통해 하나의 환경에서 서비스를 제공
4. 환경 설정과 스케일인/아웃, 테넌트를 통해 하나의 환경에서 서비스를 제공

마이그레이션 전략
1. 모든 부분을 SaaS화 : 완벽
2. 점진적 전환

SaaS 컨트롤플레인
온보딩, 자격증명, 데브옵스와 프로비져닝, 테넌트 관리,
모니터링, 메트릭 및 분석, 빌링 및 미터링


AWS SaaS Boost를 이용한 마이그레이션
	개요
		AWS에서 출시한 무료 오픈 소스로 SaaS 마이그레이션을 돕는다.
	
	장
		AWS의 다양한 서비스들과 연동이 쉽다.
		모범사례를 기반으로 한 SaaS 구성요소를 .... 


	자동으로 꼭 구축되어야 한다( SaaS 인데 당연 )
	온보딩 -> 테넌트 생성 -> 



https://catalog.workshops.aws/saasboost/ko-KR/fast-lab/lab2