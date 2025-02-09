---
layout: post
title: spring cloud gatgeway 05
author: jblim0125
date: 2024-08-15
category: 2024
---

## 트레이싱 기능 추가

OpenTelemetry + Jaeger 를 이용해 Gateway와 Service의 로그와 서비스 모니터링을 수행하고자 한다.  

## Jaeger

### 소개

Jaeger는 Uber Technologies 에서 오픈 소스로 출시한 분산 추적 플랫폼입니다.  

Jaeger를 사용하면 다음을 수행할 수 있습니다.

- 분산 워크플로 모니터링 및 문제 해결  
- 성능 병목 현상 식별  
- 문제의 원인 추적  
- 서비스 종속성 분석  

### 포트 정보

|Port|Protocol|Component|Function|
|---|---|---|---|
| 6831 | UDP | agent | accept jaeger.thrift over Thrift-compact protocol (used by most SDKs) |
| 6832 | UDP | agent | accept jaeger.thrift over Thrift-binary protocol (used by Node.js SDK) |
| 5775 | UDP | agent | (deprecated) accept zipkin.thrift over compact Thrift protocol (used by legacy clients only) |
| 5778 | HTTP | agent | serve configs (sampling, etc.) |
| 16686| HTTP | query | serve frontend |
| 4317 | HTTP | collector | accept OpenTelemetry Protocol (OTLP) over gRPC |
| 4318 | HTTP | collector | accept OpenTelemetry Protocol (OTLP) over HTTP |
| 14268| HTTP | collector | accept jaeger.thrift directly from clients |
| 14250| HTTP | collector | accept model.proto |
| 9411 | HTTP | collector | Zipkin compatible endpoint (optional) |

- Collector

|Port|Protocol|Endpoint|Function|
|---|---|---|---|
| 4317 | gRPC | n/a | Accepts traces in OpenTelemetry OTLP format  (Protobuf). |
| 4318 | HTTP | /v1/traces | Accepts traces in OpenTelemetry OTLP format  (Protobuf and JSON). |
| 14268 | HTTP | /api/sampling | Serves sampling policies (see Remote Sampling ). |
| 14268 | HTTP | /api/traces | Accepts spans in jaeger.thrift  format with binary thrift protocol (POST). |
| 14269 | HTTP | / | Admin port: health check (GET). |
| 14269 | HTTP | /metrics | Prometheus-style metrics (GET). |
| 9411 | HTTP | /api/v1/spans and /api/v2/spans | Accepts Zipkin spans in Thrift, JSON and Proto (disabled by default). |
| 14250 | gRPC |n/a | Used by jaeger-agent to send spans in model.proto  Protobuf format. |

### 실행

도커 환경에서 다음 커맨드를 이용해 실행한다.

```shell
docker run -d --name jaeger \
  -e COLLECTOR_OTLP_ENABLED=true \
  -e COLLECTOR_ZIPKIN_HTTP_PORT=9411 \
  -p 6831:6831/udp \
  -p 6832:6832/udp \
  -p 5775:5775/udp \
  -p 5778:5778 \
  -p 16686:16686 \
  -p 14250:14250 \
  -p 14268:14268 \
  -p 14269:14269 \
  -p 4317:4317 \
  -p 4318:4318 \
  -p 9411:9411 \
  jaegertracing/all-in-one:1.60
```

![jaeger-start-page](/assets/images/gateway/05/jaeger-start-page.png)

## Spring Cloud Gateway

### build.gradle

기존 내용에 다음을 추가  

```kotlin
dependencyManagement {
    imports {
        mavenBom("io.opentelemetry.instrumentation:opentelemetry-instrumentation-bom:2.6.0")
    }
}

dependencies {
    // OpenTelemetry
    implementation(platform("io.opentelemetry.instrumentation:opentelemetry-instrumentation-bom:2.6.0"))
    implementation("io.opentelemetry.instrumentation:opentelemetry-spring-boot-starter")
    implementation("io.opentelemetry:opentelemetry-exporter-jaeger:1.34.1")
}
```

### Config

- OpenTelemetryConfig.java  

```java
import io.opentelemetry.api.OpenTelemetry;
import io.opentelemetry.api.trace.Tracer;
import io.opentelemetry.api.trace.propagation.W3CTraceContextPropagator;
import io.opentelemetry.context.propagation.ContextPropagators;
import io.opentelemetry.exporter.otlp.trace.OtlpGrpcSpanExporter;
import io.opentelemetry.sdk.OpenTelemetrySdk;
import io.opentelemetry.sdk.resources.Resource;
import io.opentelemetry.sdk.trace.SdkTracerProvider;
import io.opentelemetry.sdk.trace.export.BatchSpanProcessor;
import io.opentelemetry.sdk.trace.samplers.Sampler;
import io.opentelemetry.semconv.ServiceAttributes;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class OpenTelemetryConfig {

    @Bean
    public OpenTelemetry openTelemetry() {
        Resource resource =
                Resource.getDefault().toBuilder()
                        .put(ServiceAttributes.SERVICE_NAME, "gateway")
                        .put(ServiceAttributes.SERVICE_VERSION, "1.0.0")
                        .build();

        SdkTracerProvider sdkTracerProvider =
                SdkTracerProvider.builder()
                        .addSpanProcessor(
                                BatchSpanProcessor.builder(OtlpGrpcSpanExporter.builder().build())
                                        .build())
                        .setResource(resource)
                        .setSampler(Sampler.alwaysOn())
                        .setSampler(Sampler.traceIdRatioBased(0.5))
                        .build();

        return OpenTelemetrySdk.builder()
                .setTracerProvider(sdkTracerProvider)
                .setPropagators(ContextPropagators.create(W3CTraceContextPropagator.getInstance()))
                .buildAndRegisterGlobal();
    }

    @Bean
    public Tracer tracer(OpenTelemetry openTelemetry) {
        return openTelemetry.getTracer("gateway");
    }
}
```

- application.yaml  

```yaml
otel:
  exporter:
    otlp:
      protocol: grpc
      endpoint: http://localhost:4317
  traces:
    exporter: otlp

```

### Global Filter

- OpenTelemetryGatewayFilter.java  

```java
import io.opentelemetry.api.GlobalOpenTelemetry;
import io.opentelemetry.api.trace.Span;
import io.opentelemetry.api.trace.SpanKind;
import io.opentelemetry.api.trace.Tracer;
import io.opentelemetry.context.Context;
import io.opentelemetry.context.Scope;
import io.opentelemetry.context.propagation.TextMapGetter;
import io.opentelemetry.context.propagation.TextMapPropagator;
import org.springframework.cloud.gateway.filter.GatewayFilterChain;
import org.springframework.cloud.gateway.filter.GlobalFilter;
import org.springframework.core.Ordered;
import org.springframework.http.HttpHeaders;
import org.springframework.http.server.reactive.ServerHttpRequest;
import org.springframework.stereotype.Component;
import org.springframework.web.server.ServerWebExchange;
import reactor.core.publisher.Mono;

@Component
public class OpenTelemetryGatewayFilter implements GlobalFilter, Ordered {

    private final Tracer tracer;

    public OpenTelemetryGatewayFilter() {
        this.tracer = GlobalOpenTelemetry.getTracer("gateway");
    }

    private enum HttpHeadersTextMapGetter implements TextMapGetter<HttpHeaders> {
        INSTANCE;

        @Override
        public Iterable<String> keys(HttpHeaders headers) {
            return headers.keySet();
        }

        @Override
        public String get(HttpHeaders headers, String key) {
            if (headers.containsKey(key)) {
                return headers.getFirst(key);
            }
            return null;
        }
    }

    @Override
    public Mono<Void> filter(ServerWebExchange exchange, GatewayFilterChain chain) {
        // 현재 Span의 컨텍스트를 가져옵니다.
        TextMapPropagator propagator = GlobalOpenTelemetry.getPropagators().getTextMapPropagator();
        Context extractedContext = propagator.extract(Context.current(), exchange.getRequest().getHeaders(), HttpHeadersTextMapGetter.INSTANCE);

        // 새로운 Span을 시작합니다.
        Span span = tracer.spanBuilder(exchange.getRequest().getURI().getPath())
                .setSpanKind(SpanKind.SERVER)
                .setParent(extractedContext)
                .startSpan();

        try (Scope scope = span.makeCurrent()) {
            // 요청 헤더에 Span 컨텍스트를 주입합니다.
            ServerHttpRequest mutatedRequest = exchange.getRequest().mutate()
                    .headers(httpHeaders -> propagator.inject(Context.current(), httpHeaders, (headers, key, value) -> headers.set(key, value)))
                    .build();

            ServerWebExchange mutatedExchange = exchange.mutate().request(mutatedRequest).build();

            // 체인을 통해 다음 필터로 요청을 전달합니다.
            return chain.filter(mutatedExchange)
                    .doFinally(signalType -> span.end());
        }
    }

    @Override
    public int getOrder() {
        return -1;
    }
}
```

## Service

### Service - build.gradle

```kotlin
dependencyManagement {
    imports {
        mavenBom("io.opentelemetry.instrumentation:opentelemetry-instrumentation-bom:2.6.0")
    }
}

dependencies {
    // OpenTelemetry
    implementation(platform("io.opentelemetry.instrumentation:opentelemetry-instrumentation-bom:2.6.0"))
    implementation("io.opentelemetry.instrumentation:opentelemetry-spring-boot-starter")
    implementation("io.opentelemetry:opentelemetry-exporter-jaeger:1.34.1")
}
```

### Service - Config

- application.yaml

```yaml
otel:
  exporter:
    otlp:
      protocol: grpc
      endpoint: http://localhost:4317
  traces:
    exporter: otlp
```

## 결과

최종적으로 다음과 같은 결과를 얻을 수 있다.  

![jaeger-start-page](/assets/images/gateway/05/jaeger-result.png)
