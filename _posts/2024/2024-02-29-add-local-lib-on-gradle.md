---
layout: post
title: Gradle 로컬 JAR 파일 추가
author: jblim0125
date: 2024-02-29
category: 2024
---

1. 개요  
    Gradle 종속성에 로컬 JAR 파일을 추가하는 방법을 설명한다.  

2. 로컬 JAR  
    Gradle에 로컬 JAR 파일을 추가하는 과정을 설명하기 전에, 공용 저장소에서 사용할 수 있는 종속성을 수동으로 추가하는 것은 권장되지 않는다. Gradle과 같은 빌드 시스템이 존재하는 가장 중요한 이유 중 하나는 이런 종류의 일을 자동으로 하는 것이다.  
    하지만 여전히 로컬 JAR 파일의 사용은 특별한 목적을 위해 Gradle에서 지원된다.  

3. 플랫 디렉토리  
    플랫 파일 시스템 디렉토리를 저장소로 사용하려면 build.gradle 파일에 다음을 추가해야 합니다.  

    ```kotlin
    repositories {
        mavenCentral()      // Maven Repository 
        
        flatDir {           // Local Jar Repository 
            dirs('lib1', 'lib2')
        }
    }
    ```  

    위 코드는 Gradle이 종속성을 위해 lib1과 lib2을 검색하도록 만든다. 이제 설정한 플랫 디렉토리에 JAR 파일을 복사하고 사용할 수 있습니다.  

    ```kotlin
    dependencies { 
        implementation('sample-jar-0.8.7')
    }
    ```

4. 파일 직접 설정  
    플랫 디렉토리 사용 방법 외 종속성 설정에서 파일을 직접 언급하는 것이다

    ```kotlin
    implementation(files('libs/a.jar', 'libs/b.jar'))
    ```

5. 디렉토리 설정  
    종속성 설정 시 직접 파일 이름을 작성하는 것 외에 디렉토리에 있는 모든 JAR 파일을 찾으라고 말할 수 있다. 이것은 우리가 특정 파일을 저장소에 배치할 수 없거나 원하지 않는 경우 유용할 수 있다. 하지만 우리는 이것을 조심해야 합니다. 왜냐하면 원치 않는 의존성을 추가할 수도 있기 때문입니다.

    ```kotlin
    implementation(fileTree(dir: 'libs', include: '*.jar'))
    ```
