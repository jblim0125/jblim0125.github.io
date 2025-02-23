---
layout: post
title: Spring Boot Global Exception
author: jblim0125
date: 2025-02-23
category: 2025
---

## 개요

코드 정리 겸 문서 작성
공통 메시지 포맷과 익센셥 처리

```json
{
  "code":{
    "type": "string",
    "desc": "요청 작업 결과 : 성공 - success, 실패 - error code"
  },
  "err_message": {
    "type": "string",
    "desc": "에러에 대한 상세 메시지"
  },
  "data": {
    "type": "object",
    "desc": "응답 데이터"
  }
}
```

## 응답 메시지

```java
package com.mobigen.vdap.server.response;

@Getter
@Setter
@Builder
@AllArgsConstructor
@NoArgsConstructor
@JsonInclude(JsonInclude.Include.NON_NULL)
public class CommonResponseDto {
    @JsonProperty("code")
    private String code;
    @JsonProperty("errorMsg")
    private String errorMsg;
    @JsonProperty("errorData")
    private Map<String, Object> errorData;
    @JsonProperty("data")
    private Object data;
}
```

## annotations

Aspect 를 이용해 이 어노테이션이 설정된 경우 응답 메시지를 위에서 정의한 포맷으로 만들어 클라이언트로 전송한다.

```Java
package com.mobigen.vdap.server.annotations;

@Inherited
@Documented
@Retention(RetentionPolicy.RUNTIME)
@Target({ElementType.METHOD})
@ResponseBody
public @interface CommonResponse {
}
```

## 사용자 정의 Exception

마찬가지로 오류(익셉션)이 발생한 경우에도 Aspect 를 이용해 위에서 정의한 포맷으로 만들어 클라이언트로 전송한다.
사용할 익셉션을 정의

```Java
package com.jblim.test.exceptions;

@Getter
public class CustomException extends RuntimeException {
    private final Object causedObject;

    public CustomException(String message, Object causedObject) {
        super(message);
        this.causedObject = causedObject;
    }
    public CustomException(String message, Throwable e, Object causedObject) {
        super(message, e);
        this.causedObject = causedObject;
    }
}
```

## RestControllerAdvice

RestControllerAdvice 를 이용해 에러를 처리할 수 있도록 핸들러를 만든다.

```Java
package com.jblim.test.handler;

@RestControllerAdvice
public class GlobalExceptionHandler {

    @ResponseBody
    @ExceptionHandler(BindException.class)
    public Object bindExceptionHandler( BindException e ) {
        log.error( "Bind Exception[ {} ]", e.getMessage());
        return e;
    }

    /**
     * 지원하지 않는 HTTP 메서드(예: GET, POST, PUT 등)를 요청할 경우 발생.
     */
    @ResponseBody
    @ExceptionHandler(HttpRequestMethodNotSupportedException.class)
    public Object requestMethodNotSupportedException( HttpRequestMethodNotSupportedException e ) {
        log.error( "Request Method Not Supported Exception [ {} ]", e.getMessage() );
        return e;
    }
    /**
     * 요청 본문을 읽을 수 없는 경우 발생.
     * 예: 잘못된 JSON 데이터를 요청으로 보냈을 때.
     */
    @ResponseBody
    @ExceptionHandler(HttpMessageNotReadableException.class)
    public Object HttpMessageNotReadableException( HttpMessageNotReadableException e ) {
        log.error( "Request Message Not Readable Exception [ {} ]", e.getMessage() );
        return e;
    }

    /**
     * CustomException 클래스로 서비스 로직에서의 예외를 처리한다.
     */
    @ResponseBody
    @ExceptionHandler(CustomException.class)
    public Object CustomExceptionHandler( CustomException e ) {
        log.error( "User(Service)Define Exception[ {} ]", e.getMessage(), e );
        return e;
    }

    /**
     * 핸들링하지 않은 예외를 상위클래스인 Exception 클래스로 핸들링한다.
     */
    @ResponseBody
    @ExceptionHandler(Exception.class)
    public Object unknownExceptionHandler( Exception e ) {
        log.error("Unknown Exception[ {} ]", e.getMessage(), e);
        return new CustomException( "unknown exception", e, null);
    }
}
```

## Aspect

공통 메시지 포맷에 맞게 메시지가 전송될 수 있도록 Annotation과 Exception 에 대한 처리를 구현한다.

```Java
@Aspect
@Component
public class CommonResponseAspect {

    @Around("@annotation(com.jblim.test.annotation.CommonResponse)")
    public CommonResponseDto responseJsonSuccess(ProceedingJoinPoint point) throws Throwable {
        Object results = point.proceed();
        return CommonResponseDto.builder().code("success").data(results).build();
    }

    @Around("execution(* com.jblim.test.handler.GlobalExceptionHandler.*(..))")
    public CommonResponseDto responseJsonFail(ProceedingJoinPoint point) throws Throwable {
        Object results = point.proceed();
        CommonResponseDto response = new CommonResponseDto();
        Map<String, Object> errData = new HashMap<>();
        switch (results) {
            case CustomException customException -> {
                errData.put("error", customException.getClass().getSimpleName());
                errData.put("causedByObject", customException.getCausedObject()); // 예외가 발생한 객체 포함

                // Stacktrace를 String으로 변환하여 포함
                StringWriter sw = new StringWriter();
                customException.printStackTrace(new PrintWriter(sw));
                errData.put("stacktrace", sw.toString());

                response.setCode("Error");
                response.setErrorMsg(customException.getMessage());
                response.setErrorData(errData);
            }
            case BindException exception -> {
                // Stacktrace를 String으로 변환하여 포함
                StringWriter sw = new StringWriter();
                exception.printStackTrace(new PrintWriter(sw));
                errData.put("stacktrace", sw.toString());

                response.setCode("Error");
                response.setErrorMsg(exception.getMessage());
                response.setErrorData(errData);
            }
            case HttpRequestMethodNotSupportedException exception -> {
                // Stacktrace를 String으로 변환하여 포함
                StringWriter sw = new StringWriter();
                exception.printStackTrace(new PrintWriter(sw));
                errData.put("stacktrace", sw.toString());

                response.setCode("Error");
                response.setErrorMsg(exception.getMessage());
                response.setErrorData(errData);
            }
            case null, default -> {
                errData.put("errData", results);
                response.setCode("Error");
                response.setErrorData(errData);
            }
        }
        return response;
    }
}
```

## 사용

이제 컨트롤러에서 만든 annotation 을 추가하면 된다.

```java
package com.jblim.test.resource.service;

@Slf4j
@RestController
@RequestMapping(value = "/v1/services")
public class StorageServiceController {

    @GetMapping
    @CommonResponse
    public Object getAllServices() {
        return "get all services";
    }

    @GetMapping("/{id}")
    @CommonResponse
    public Object getById( @PathVariable UUID id) {
        return "get by id storage service";
    }
}
```

```bash
$ curl -X GET http://localhost:8080/v1/services | jq " "
{
  "code": "success",
  "data": "get all services"
}
```