Web Dev Framework

check this web page : frontend developer roadmap

전자정부 프레임워크, SDS, 등등등  

server-side - ( web frameworks ) - client-side ?


backend 			- 			front
business api 		-			visualization		( web 이 1 thread로 동작함 많은 기능을 추가하면 -> 느려짐(freezing) )  
													http2에서는 Multi thread를 지원하지만 데이터 공유 문제로 worker - visual 간 통신 필요

JUnit + Spring RestDocs 


최근 reactive stack, servlet stack 2개로 구분??

reactive stack 의 경우 database의 선택이 달라 진다? 


security : 
	JWT-Token
	stateless, session ( session 기반은 scale in/out 에 어려움 )
	
URI hash, history 기능

global exception 처리와 다국어 처리는 다양한 에러 메시지를 처리할 수 없어
에러 원인을 확인하기 어려운 부분이 있음. -> 보다 상세한 메시지를 원하는데 방법은 확인 필요 


spring restdoc 의 사용성과 관련... 의문 

webpack 이용
js가 무겁고, 코드 개발에서 신경써야 하는 부분이 많음
	js 모듈 분리(페이지 분리) 를 통해 페이지 리로딩으로 분리처리 

component 단위 -> 조합으로 페이지를 만듬
moduel (view) |
	container component | ( 데이터? )
		presentation component ( 입력, 버튼 ? )
		presentation component
		presentation component

