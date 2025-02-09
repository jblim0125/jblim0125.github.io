---
layout: post
title: "github jekyll 를 이용한 블로그 만들기 01"
author: jblim0125
date: 2024-07-27
category: 2024
---

## 1. 준비

이 장에서는 로컬에서 jekyll 를 이용해 블로그를 구성하기 위한 환경 구성 방법에 대해서 설명한다.  

* ruby >= 2.4.0  
`ruby -v`  
* gem  
`gem -v`  
* GCC  
`gcc -v`, `g++ -v`  
* Make  
`make -v`

### 1.1. MAC OS

1. Command Line Tools 설치
    터미널을 열어 다음 명령을 실행합니다.  

    ```shell
    xcode-select --install
    ```

2. 루비 설치  
    Jekyll 2.4.0 이상 버전 필요  
    맥OS 카탈리나 10.15 는 루비 2.6.3 이 기본 포함되어 있으므로 아무런 문제가 없습니다.
    이전 버전의 맥OS 시스템을 사용중이라면, 새로운 버전의 루비를 설치해야 합니다.

    1. Homebrew 를 이용한 설치  
        최신 버전의 루비를 Homebrew 로 설치할 수 있습니다.  

        ```shell
        brew install ruby
        
        # ...
        # ...
        # By default, binaries installed by gem will be placed into:
        #   /opt/homebrew/lib/ruby/gems/3.3.0/bin
        # You may want to add this to your PATH.
        # ...
        # ...
        # If you need to have ruby first in your PATH, run:
          echo 'export PATH="/opt/homebrew/opt/ruby/bin:$PATH"' >> ~/.zshrc
        #For compilers to find ruby you may need to set:
          export LDFLAGS="-L/opt/homebrew/opt/ruby/lib"
          export CPPFLAGS="-I/opt/homebrew/opt/ruby/include"
        ```

        설치 마지막의 안내에 따라 PATH 를 설정한다.  

        ```shell
        echo 'export PATH="/opt/homebrew/opt/ruby/bin:$PATH"' >> ~/.zshrc
        ```

        이제 터미널을 재시작하여 추가한 루비 설정을 확인합니다:

        설치 확인  

        ```shell
        ruby -v
        ruby 3.3.0 (2023-12-25 revision 5124f9ac75) [arm64-darwin23
        ```

    2. rbenv 사용  
        rbenv 를 이용할 경우 여러 버전의 루비를 관리할 수 있습니다.  
        프로젝트마다 다른 버전의 루비를 실행해야 할 때 아주 유용합니다.  

        homebrew 를 이용해 우선 rbenv를 설치합니다.

        ```shell
        # rbenv 와 ruby-build 설치
        brew install rbenv
        
        # 쉘 환경에 rbenv 가 연동되도록 설정
        rbenv init

        # 설치상태 검사
        curl -fsSL https://github.com/rbenv/rbenv-installer/raw/master/bin/rbenv-doctor | bash
        ```

        터미널을 재시작하면 변경사항이 적용됩니다.  
        이제 원하는 버전의 루비를 설치할 수 있습니다.

        ```shell
        rbenv install 3.3.0
        rbenv global 3.3.0
        ruby -v
        ruby 3.3.0 (2023-12-25 revision 5124f9ac75) [arm64-darwin23
        ```

3. Jekyll 설치  
    이제 Bundler 와 Jekyll 을 설치를 완료하면 됩니다.  

    1. 로컬 설치  

        ```shell
        gem install --user-install bundler jekyll
        ```

        이제 PATH 설정을 진행합니다. 그 전에 ruby 버전 정보가 필요합니다.  

        ```shell
        ruby -v
        ruby 3.3.0 (2023-12-25 revision 5124f9ac75) [arm64-darwin23
        ```

        이제 아래 내용을 쉘 환경에 추가하는데, X.X 부분에는 설치된 루비 버전의 처음 두 숫자를 넣습니다.

        ```shell
        echo 'export PATH="$HOME/.gem/ruby/X.X.0/bin:$PATH"' >> ~/.zshrc
        ## 이 문서에서는 3.3.0 버전을 설치했으므로 다음과 같이 작성했습니다.
        echo 'export PATH="$HOME/.gem/ruby/3.3.0/bin:$PATH"' >> ~/.zshrc
        ```

        터미널을 재시작합니다.
        젬 경로가 $HOME 디렉토리를 가리키고 있는지 확인합니다.  

        ```shell
        gem env
        ...
        ...
        - GEM PATHS:
          - /Users/jblim/.gem/ruby/3.3.0
          - /Users/jblim/.rubies/ruby-3.3.0/lib/ruby/gems/3.3.0
        ...
        ...
        ```

## 2. jekyll editor 추천

* Visual Studio Code  
다양한 Jekyll 관련 플러그인과 환경설정 파일의 자동완성 기능이 있습니다.
* vim-jekyll  
vim 을 종료하지 않고 새 포스트를 생성하고 jekyll build 를 실행할 수 있게 해주는 Vim 플러그인  

## 3. 시작

테마를 다운로드 받아 시작할 수 있겠지만 차근차근 진행해보고자 한다.  

1. 작업디렉토리 생성 및 프로젝트 초기화  

    ```shell
    mkdir -p myblog && cd myblog
    bundle init
    Writing new Gemfile to .../myblog/Gemfile
    ```

2. jekyll 의존성 추가  
    Gemfile 을 열어 다음을 추가  

    ```yaml
    gem "jekyll
    ```

3. index.html 파일 생성  
    심플한 index.html 파일 생성.

    ```html
    <!doctype html>
    <html>
      <head>
        <meta charset="utf-8">
        <title>Home</title>
      </head>
      <body>
        <h1>Hello World!</h1>
      </body>
    </html>
    ```

4. 빌드  
    Jekyll 은 정적 사이트 생성기로 사이트를 보려면 먼저 Jekyll 로 사이트를 빌드해야 합니다.  
    사이트 빌드에 사용하는 명령어는 두 가지로 사이트의 루트에서 실행할 수 있습니다

    * jekyll build  
      사이트를 빌드하고 _site 라는 디렉토리에 정적 사이트를 생성합니다.  
    * jekyll serve  
      위와 동일한 작업을 하지만 추가로 내용이 변경되면 사이트를 다시 빌드하고  
      `http://localhost:4000` 주소에 로컬 웹 서버를 구동합니다.  

    사이트 개발 중에는 jekyll serve 를 사용해 사이트를 수정할 때마다 갱신이 되도록 합니다.  

    > 'jekyll build', 'jekyll serve' 명령이 실행되지 않을 수 있습니다.  
    > 그렇다면, 'bundle exec jekyll build', 'bundle exec jekyll serve'  
    > 'jekyll' 명령 앞에 '**bundle exec**' 를 추가해서 입력해주세요.  

    jekyll serve 를 실행하고 브라우저로 `http://localhost:4000` 에 접속합니다.  
    “Hello World!” 가 보일 것입니다.  

    ![hello_world](/assets/images/blog/hello_world.png)

## 4. 단계별 튜토리얼

### 4.1. Liquid

Liquid는 템플릿 언어로 세 가지 부분으로 나눌 수 있습니다

* 오브젝트  
* 태그  
* 필터  

> Jekyll 를 사용한 블로그에서 Liquid 문법 사용 시 에러가 발생하여 코드들이 사진으로 첨부됩니다.

1. 오브젝트
    오브젝트는 컨텐츠를 어디에 출력할 지 Liquid에 알려줍니다.  
    두 개의 중괄호로 표시합니다:  

    예시:

    ![liquid-object](/assets/images/blog/liquid-object.png)

    페이지에 page.title 변수의 값을 출력합니다.

2. 태그  
    태그는 템플릿의 논리 연산과 흐름을 제어합니다.  
    중괄호와 퍼센트 문자로 표시합니다:  

    예시:

    ![liquid-tag](/assets/images/blog/liquid-tag.png)

    변수 `page.show_sidebar` 가 참인 경우에 사이드바를 출력합니다.  

3. 필터  
    필터는 Liquid 오브젝트의 출력을 변화시킵니다. `|` 로 구분해서 오브젝트 안에 사용합니다.  

    예시:

    ![liquid-filter](/assets/images/blog/liquid-filter.png)

    소문자로 구성된 'hi'가 'Hi'로 출력됩니다.  

### 4.2. 머리말  

머리말은 파일의 맨 처음에 세 개의 대시문자('---')로 감싼 YAML 코드입니다.  
머리말은 해당 페이지에 대한 변수를 설정하는데에 사용됩니다.  

예시:

![header01](/assets/images/blog/header-01.png)

머리말 변수는 Liquid에서 page 변수로 사용할 수 있습니다.  
예를 들어 위 변수를 출력하기 위해서는 다음과 같이 합니다.  

![header02](/assets/images/blog/header-02.png)

머리말을 사용해서 사이트의 `<title>` 을 바꿔봅시다:

![header03](/assets/images/blog/header-03.png)

결과  
![liquid_result](/assets/images/blog/liquid_result.png)

Jekyll 이 당신의 페이지 Liquid 태그를 처리하도록 하려면, 반드시 머리말이 있어야 한다는 사실을 잊지마세요.  
가장 단순한 형태의 머리말은 다음과 같습니다:

```html
---
---
```

여전히 왜 순수 HTML 보다 더 많은 코드가 필요한 이런 방식을 사용해야 하는지 궁금할 것입니다.  
다음 단계에서, 왜 이런 것들을 하고 있었는지 그 이유를 알 수 있습니다.  

### 4.3. 레이아웃

웹사이트는 보통 하나 이상의 페이지를 가지고 있으며 이 웹사이트 또한 마찬가지입니다.  

Jekyll은 HTML 뿐만 아니라 마크다운도 지원합니다. 마크다운은 순수 HTML 보다 간략하여,
컨텐츠 구조가 단순한 페이지에 (예시, 문단, 제목, 이미지만 있는 문서) 탁월한 선택입니다.  

1. 레이아웃 생성하기  
    레이아웃은 당신의 컨텐츠를 포장하는 템플릿입니다.  
    `_layouts` 라는 디렉토리에 보관합니다.

    다음과 같은 내용으로 `_layouts/default.html` 에 첫 번째 레이아웃을 생성합니다.

    ![layout-01](/assets/images/blog/layout-01.png)

    내용이 index.html 과 거의 똑같다는 것을 눈치챌 수 있겠지만, 머리말이 없고
    페이지의 컨텐츠 부분에 변수 content 가 사용되었다는 차이점이 있습니다.
    `content` 라는 이 특별한 변수는 자신이 호출된 페이지의 컨텐츠를 렌더링 한 내용을 담고 있습니다.  

    `index.html` 에 이 레이아웃을 사용하기 위해, 다음과 같이 변경합니다.  

    ![layout-02](/assets/images/blog/layout-02.png)

    이렇게 하면, 출력 결과는 이전과 완벽하게 동일할 것입니다. 기억할 것은 레이아웃으로부터 페이지(page)의 머리말에 접근한다는 것입니다. 위 예시에서, `title` 은 인덱스 페이지의 머리말에 설정되었지만 레이아웃에서 출력되었습니다.

2. 레이아웃을 이용한 페이지 추가  
    about 페이지를 생성한다면 이제는 레이아웃을 사용할 수 있습니다.

    다음 내용을 about.md 에 추가합니다:

    ![alt text](/assets/images/blog/layout-03.png)

    브라우저에서 `http://localhost:4000/about.html` 를 열어 새 페이지를 확인합니다.

    ![about_page](/assets/images/blog/about_page.png)

    축하합니다.  

    이제 두 페이지짜리 웹사이트가 생겼네요! 그런데 페이지간의 이동은 어떻게 하죠? 계속해서 알아봅시다.

### 4.4. 조각 파일

사이트가 점점 그럴싸해지고 있습니다.  
페이지 사이의 네비게이션이 없네요. 고쳐봅시다.

네비게이션은 모든 페이지에 있어야 하므로 레이아웃에 추가하는 것이 올바른 방법입니다.  
레이아웃에 직접 추가하는 대신, 이 기회를 이용해 조각파일에 대하여 배워보도록 합니다.

1. Include 태그  
    include 태그를 사용하면 `_includes` 폴더에 저장된 조각파일의 내용을 포함시킬 수 있습니다.
    조각파일은 사이트 여러곳에 반복되는 코드를 한 곳에서 관리하거나 사이트 소스코드의 가독성을
    향상시키는데에 유용합니다.

    네비게이션을 구현하는 소스코드는 복잡한 경우가 많아 조각파일로 보관하는 것이 좋습니다.

2. 조각파일 사용법  
    네비게이션을 위해 `_includes/navigation.html` 파일을 다음과 같이 작성하여 저장합니다.  

    ![include-01](/assets/images/blog/include-01.png)

    include 태그를 사용해서 `_layouts/default.html` 에 네비게이션을 추가합니다:

    ![layouts-default](/assets/images/blog/layouts_default.png)

    브라우저에서 `http://localhost:4000` 를 열어 페이지 사이를 이동해봅니다.

    ![navi](/assets/images/blog/navi.png)

3. 현재 페이지 표시하기  
    좀 더 깊게 파고들어서 네비게이션에 현재 페이지를 표시하는 방법을 알아봅시다.  

    스타일을 추가하려면 `_includes/navigation.html` 은 자신이 삽입된 페이지의
    `URL` 을 알 필요가 있습니다.  
    Jekyll 에서 사용할 수 있는 유용한 변수들 중 `page.url` 이라는 변수가 있습니다.  

    `page.url` 을 사용해서 각 링크가 현재 페이지인지 확인하고 만약 그렇다면 빨간색으로 표시합니다:

    ![current-page](/assets/images/blog/current-page.png)

    브라우저에서 `http://localhost:4000` 을 열어 현재 페이지 링크가 빨간색인지 확인합니다.  

    ![navi-color](/assets/images/blog/navi-color.png)

    네비게이션에 새 페이지를 추가하거나 색을 변경하고자 하는 경우 여전히 중복된 코드가 많이 발생합니다.  
    다음 단계에서 이에 대해 다뤄보겠습니다.  

### 4.5. 데이터

Jekyll 은 `_data` 디렉토리에 있는 YAML, JSON, CSV 파일로부터 데이터를 읽는 기능을 제공합니다.  
데이터 파일은 소스 코드로부터 컨텐츠를 분리하는 아주 좋은 방법으로서 사이트 유지/관리를 쉽게 만들어줍니다.  

이 단계에서는 데이터 파일에 네비게이션의 컨텐츠를 저장한 뒤 반복문을 통해 네비게이션 조각파일에서 사용해보겠습니다.

#### 4.5.1. 데이터 파일 사용법

YAML 은 루비 생태계에서 흔히 사용되는 형식입니다. 네비게이션의 이름과 링크들의 배열을
이 형식으로 저장해볼 것입니다.

네비게이션을 위한 데이터 파일 `_data/navigation.yml` 을 생성하고 다음 내용을 입력합니다.  

```yaml
- name: Home
  link: /
- name: About
  link: /about.html
```

Jekyll 은 `site.data.navigation` 으로 이 데이터 파일을 사용할 수 있게 만듭니다.
`_includes/navigation.html` 에 링크들을 일일히 출력하는 대신, 데이터 파일을 통해 나열할 수 있습니다.

![data-navi](/assets/images/blog/data-navi.png)

완벽하게 동일한 결과를 얻을 수 있습니다.  

![navi-by-data](/assets/images/blog/navi-by-data.png)

바뀐 것은 새 네비게이션 항목을 추가하고 HTML 구조를 변경하는 일이 쉬워졌다는 것입니다.  

이제 사이트에 CSS 나 JS 이런 에셋들을 Jekyll 에서 다루는 방법을 알아봅시다.

### 4.6. 에셋(Assets)

Jekyll 에서 CSS, JS, 그림과 그 밖의 다른 에셋들을 사용하는 것은 아주 직관적입니다.  
사이트 소스에 있는 에셋들은 빌드된 사이트로 복사될 것입니다.  

Jekyll 사이트는 에셋들을 정돈하는데에 이런 구조를 자주 사용합니다.  

```shell
.
├── assets
│   ├── css
│   ├── images
│   └── js
...
```

#### 4.6.1. Sass

`_includes/navigation.html` 에 사용했었던 인라인 스타일은 좋은 방법이 아닙니다.  
클래스를 사용해서 이 페이지에 스타일을 입혀봅시다.

![sass-navi](/assets/images/blog/sass-navi.png)

표준 CSS 파일을 사용해서 스타일을 정의할 수도 있겠지만, 여기서는 한 걸음 더 나아가 `Sass` 를 사용해보겠습니다. Sass 는 Jekyll 에 녹아들어있는 환상적인 CSS 확장기능입니다.

먼저 `assets/css/styles.scss` 에 Sass 파일을 생성하고 다음 내용을 입력합니다.

```css
---
---
@import "main";
```

맨 처음에 비어있는 머리말은 이 파일을 처리하라고 Jekyll에 알려줍니다. `@import "main"` 은
sass 디렉토리(사이트 루트에 있어야 함. 기본값: _sass/) 에 있는 main.scss 파일을 참고하도록
Sass 에게 지시합니다.

현 시점에서는 메인 CSS 파일 하나밖에 없습니다. 더 큰 프로젝트에서는,
이 방법이 CSS 를 정리하는 가장 좋은 방법입니다.  

Sass 파일을 `_sass/main.scss` 에 생성하고 다음 내용을 입력합니다.  

```css
.current {
  color: green;
}
```

레이아웃에서 이 스타일시트를 참조해야 합니다.

`_layouts/default.html` 을 열고 `<head>` 에 이 스타일시트를 추가합니다:

![sass-default](/assets/images/blog/sass-default.png)

여기에 있는 `styles.css` 는 앞서 `assets/css/` 에 만든 `styles.scss` 로부터
Jekyll 이 생성한 파일입니다.

브라우저로 `http://localhost:4000` 를 열고 네비게이션에서 현재 링크가 초록색인 것을 확인합니다.

![navi-color-by-sass](/assets/images/blog/navi-color-by-sass.png)

### 4.7. 블로깅

Jekyll 스타일로 블로그를 설정할 때 데이터베이스 없이 텍스트 파일만으로 블로그를 운영할 수 있습니다.  

1. 글 작성하기
    블로그 글은 `_posts` 폴더에 저장됩니다. 글의 파일명은 `게시 날짜-제목.md` 형식을 따릅니다.  
    예를 들어, 다음과 같은 글을 작성해보세요:

    파일 경로: `_posts/2024-07-27-banana.md`

    ```markdown
    ---
    layout: post
    author: jill
    ---
    바나나는 맛있다.  
    ```

2. 레이아웃 설정하기
    post 레이아웃이 없기 때문에 `_layouts/post.html` 파일을 생성하고 다음 내용을 추가합니다.

    파일 경로: `_layouts/post.html`

    ![blog-post-layout](/assets/images/blog/blog-post-layout.png)

3. 글 목록 페이지 만들기
    블로그 글로 이동할 수 있는 방법이 필요합니다. 보통 블로그는 모든 글을 나열한 페이지가 있습니다.  
    다음은 그 예시입니다.  

    파일 경로: `blog.html`

    ![blog-html](/assets/images/blog/blog-html.png)

4. 내비게이션 설정하기
    블로그 페이지로 이동할 수 있는 링크를 메인 내비게이션에 추가합니다.  
    `_data/navigation.yml` 파일을 열고 다음 내용을 추가합니다:

    파일 경로: `_data/navigation.yml`

    ```yaml
    - name: Home
      link: /
    - name: About
      link: /about.html
    - name: Blog
      link: /blog.html
    ```

5. 추가 글 작성하기

    블로그가 흥미로우려면 여러 개의 글이 필요합니다. 몇 개의 글을 더 추가합니다:

    파일 경로: `_posts/2018-08-21-apple.md`  

    ```markdown
    ---
    layout: post
    author: jill
    ---
    사과는 맛있다.
    ```

    파일 경로: `_posts/2024-07-27-kiwi.md`  

    ```markdown
    ---
    layout: post
    author: ted
    ---
    키위는 맛있다.
    ```

6. 확인  

    ![blog-01](/assets/images/blog/blog-01.png)

다음 시간에...
