---
layout: post
title: "github jekyll 를 이용한 블로그 만들기 02"
author: jblim0125
date: 2024-08-04
category: 2024
---

지난 시간에 이어서 Jekyll을 사용한 블로그에 대해서 설명하고자 합니다.  

### 4.8. Collections

글의 작성자 정보를 확장하여 각 작성자에게 자신의 페이지를 제공하고 그들이 작성한 게시물을 보여줄 수 있습니다.  
이를 위해 컬렉션을 사용할 것입니다. 컬렉션은 게시물과 유사하지만, 날짜별로 그룹화할 필요가 없습니다.

1. 설정  
    컬렉션(Collection)을 설정하려면 `Jekyll`에 알려야 합니다. `Jekyll` 설정은 기본적으로 `_config.yml` 파일에서 이루어집니다.

    루트 디렉토리에 `_config.yml`을 생성하고 다음 내용을 추가합니다.

    ```yaml
    collections:
      authors:
    ```

    설정을 (재)로드하려면 `Jekyll` 서버를 다시 시작해야 합니다.  
    `jekyll serve` 가 실행된 상태라면 `Ctrl+C`를 눌러 서버를 중지한 후 `jekyll serve` 명령어로 다시 시작합니다.

2. 작성자 추가  
    컬렉션의 항목(문서)은 사이트 루트의 `_authors` 폴더에 저장됩니다.  
    작성자에 대한 문서를 생성합니다.  

    * `_authors/jill.md`  

        ```markdown
        ---
        short_name: jill
        name: Jill Smith
        position: Chief Editor
        ---
        Jill is an avid fruit grower based in the south of France.
        ```

    * `_authors/ted.md`  

        ```markdown
        ---
        short_name: ted
        name: Ted Doe
        position: Writer
        ---
        Ted has been eating fruit since he was baby.
        ```

3. Staff page  
    사이트의 모든 작성자를 나열하는 페이지를 추가합시다.  
    `Jekyll`은 컬렉션을 `site.authors`에서 사용할 수 있게 합니다.

    파일 경로 : `staff.html`

    ![staff-page](/assets/images/blog02/staff-page.png)

    내용이 마크다운이므로 `markdownify` 필터를 통해 변환해야 합니다.  
    레이아웃에서 `{{ content }}`을 출력할 때는 자동으로 변환됩니다.  

    **내비게이션에 스태프 페이지 추가**

    스태프 페이지로 이동할 수 있는 링크를 메인 내비게이션에 추가합니다. `_data/navigation.yml` 파일을 열고 다음 내용을 추가합니다:

    파일 경로: `_data/navigation.yml`

    ```yaml
    - name: Home
      link: /
    - name: About
      link: /about.html
    - name: Blog
      link: /blog.html
    - name: Staff
      link: /staff.html
    ```

    결과 확인  

    ![staff-page](/assets/images/blog02/staff-output-01.png)

4. 작성자 페이지 출력  
    기본적으로 컬렉션은 문서에 대한 페이지를 출력하지 않습니다. 이 경우 각 작성자에게 자신의 페이지가 필요하므로 컬렉션 설정을 조정합니다.  

    파일 경로: `_config.yml`  

    ```yaml
    collections:
      authors:
        output: true
    ```

    작성자 정보에서 링크가 추가된 코드  

    ![staff-page-add-link](/assets/images/blog02/staff-page-add-link.png)

    결과 확인  

    ![staff-page-link](/assets/images/blog02/staff-page-link.png)

5. 작성자 레이아웃 생성  
    ![author-layout](/assets/images/blog02/author-layout.png)

6. 레이아웃 설정  
    이제 문서에 레이아웃을 사용하도록 설정해야 합니다. 이전처럼 설정할 수도 있지만 반복적입니다.  
    모든 게시물이 자동으로 post 레이아웃을 가지도록 하고, 작가는 author 레이아웃을 가지며, 나머지는 default를 사용하도록 설정합니다.

    파일 경로: `_config.yml`  

    ```yaml
    collections:
      authors:
        output: true

    defaults:
      - scope:
          path: ""
          type: "authors"
        values:
          layout: "author"
      - scope:
          path: ""
          type: "posts"
        values:
          layout: "post"
      - scope:
          path: ""
        values:
          layout: "default"
    ```

    _config.yml을 업데이트할 때마다 Jekyll을 재시작해야 변경 사항이 적용됩니다.

7. 작성자 별 작성글 리스트  
    작성자 페이지에 그들이 게시한 글을 나열합시다.  
    이를 위해 게시물의 작성자와 작가의 `short_name`을 매칭하여 게시물을 필터링합니다.

    ![author-list](/assets/images/blog02/staff-layout-list.png)

    ![author-blog-list](/assets/images/blog02/staff-blog-list.png)

8. 게시물 레이아웃 변경  
    게시물에 작성자에 대한 참조가 있으므로 이를 작성자 페이지로 링크합니다.  
    `_layouts/post.html`에서 유사한 필터링 기술을 사용하여 수행할 수 있습니다.  

    파일 경로: `_layouts/post.html`  

    ![post-layout](/assets/images/blog02/post-layout.png)

    ![post-to-author](/assets/images/blog02/post-to-author.png)

9. 활용  
    Collection 기능을 활용해 '태그' 혹은 '카테고리', '작성년도' 등으로 활용해 보자.  

### 4.9. Deployment

튜토리얼 마지막단계입니다.

1. Gemfile  
    사이트에 `Gemfile`을 사용하는 것은 좋은 관행입니다.  
    이는 `Jekyll` 및 다른 `gem` 들의
    버전을 서로 다른 환경에서도 일관되게 유지하도록 보장합니다.  

    루트 디렉토리에 Gemfile을 열어 다음과 같이 편집하세요.  
    아마도 변경할 내용은 없을 것입니다.  

    ```ruby
    source 'https://rubygems.org'

    gem 'jekyll'
    ```

    그런 다음 터미널에서 `bundle install`을 실행하세요.  
    이 명령은 `gem`들을 설치하고, `Gemfile.lock`을 생성하여 현재 `gem` 버전을 잠급니다.  
    나중에 `gem` 버전을 업데이트하고 싶다면 `bundle update`를 실행할 수 있습니다.  

    `Gemfile`을 사용할 때는 `jekyll serve`와 같은 명령을 실행할 때 `bundle exec`을 앞에 붙여서 실행합니다.  
    전체 명령은 다음과 같습니다.  

    ```shell
    bundle exec jekyll serve
    ```

    이렇게 하면 Ruby 환경을 Gemfile에 설정된 `gem`들만 사용하도록 제한합니다.  

2. Plugin  
    `Jekyll` 플러그인을 사용하면 사이트에 맞는 맞춤형 생성 콘텐츠를 만들 수 있습니다.  
    사용할 수 있는 플러그인이 많으며, 직접 작성할 수도 있습니다.  

    거의 모든 `Jekyll` 사이트에 유용한 세 가지 공식 플러그인이 있습니다:

    * jekyll-sitemap  
      검색 엔진이 콘텐츠를 인덱싱할 수 있도록 사이트맵 파일을 생성합니다.  
    * jekyll-feed  
      게시물에 대한 RSS 피드를 생성합니다.  
    * jekyll-seo-tag  
      SEO를 돕기 위해 메타 태그를 추가합니다.  

    먼저 Gemfile에 이들을 추가해야 합니다. `jekyll_plugins` 그룹에 넣으면 자동으로 `Jekyll`에 포함됩니다.  

    ```ruby
    source 'https://rubygems.org'

    gem 'jekyll'

    group :jekyll_plugins do
      gem 'jekyll-sitemap'
      gem 'jekyll-feed'
      gem 'jekyll-seo-tag'
    end
    ```

    그런 다음 `_config.yml` 파일에 다음 줄을 추가합니다.  

    ```yaml
    plugins:
      - jekyll-feed
      - jekyll-sitemap
      - jekyll-seo-tag
    ```

    이제 bundle update를 실행하여 설치합니다.  

    ```shell
    bundle update

    Fetching gem metadata from https://rubygems.org/............
    Resolving dependencies...
    Using public_suffix 6.0.1 (was 5.0.4)
    Using rouge 4.3.0 (was 4.2.0)
    Using rexml 3.3.2 (was 3.2.6)
    Using concurrent-ruby 1.3.3 (was 1.2.3)
    Using google-protobuf 4.27.2 (arm64-darwin) (was 3.25.1)
    Using addressable 2.8.7 (was 2.8.6)
    Using sass-embedded 1.77.8 (arm64-darwin) (was 1.69.6)
    Using i18n 1.14.5 (was 1.14.1)
    Using ffi 1.17.0 (arm64-darwin) (was 1.16.3)
    Using rb-inotify 0.11.1 (was 0.10.1)
    Using listen 3.9.0 (was 3.8.0)
    Bundle updated!
    ```

    jekyll-sitemap은 별도의 설정이 필요 없으며, 빌드 시 사이트맵을 생성합니다.

    jekyll-feed와 jekyll-seo-tag의 경우 _layouts/default.html에 태그를 추가해야 합니다.  

    ![feed-layout](/assets/images/blog02/feed-layout.png)

    서버 재시작하여 페이지를 개발자 모드로 열어보면 head에서 데이터들을 확인할 수 있습니다.

    ![layout-head](/assets/images/blog02/layout-head.png)

3. 환경변수  
    때로는 개발 환경에서는 출력하지 않고 프로덕션 환경에서만 출력하고 싶은 내용이 있을 수 있습니다.  
    가장 흔한 예로는 분석 스크립트가 있습니다.

    이럴 때는 환경 변수를 사용할 수 있습니다. 명령을 실행할 때 `JEKYLL_ENV` 환경 변수를 설정하여 환경을 지정할 수 있습니다.  

    예를 들어:

    ```sh
    JEKYLL_ENV=production bundle exec jekyll build
    ```

    기본적으로 `JEKYLL_ENV`는 development로 설정됩니다. `JEKYLL_ENV`는 Liquid에서 `jekyll.environment`를 통해 사용할 수 있습니다.  
    따라서 프로덕션에서만 분석 스크립트를 출력하려면 다음과 같이 하면 됩니다:

    ![alt text](/assets/images/blog02/env.png)

4. 배포  
    우리는 직접 배포를 하지 않을 것이므로 이 단계는 생략하겠습니다.  

## 5. GitHub Pages

이제 `Jekyll`을 이용해 만든 블로그를 github에 올려 `xxx.github.io` 에 접속하여
블로그를 볼 수 있도록 설정해 보겠습니다.  

### 5.1. 준비

1. Github 계정  
`github.com` 에 접속하여 계정을 생성하세요.  
2. git  
`git -v` 를 이용해 로컬 설치 상태를 확인하세요.  
3. git 사용 방법  

### 5.2. 저장소 생성

`https://github.com/{github-username}`(github-username 변경) 접속
저장소 `repositories` 탭으로 들어가 `NEW` 를 클릭합니다.  

![new-repo](/assets/images/blog02/new-repo.png)

저장소 이름을 `username.github.io` 으로 `username` 은 자신의 계정으로 변경합니다.  

![new-repo-edit](/assets/images/blog02/new-repo-edit.png)

그리고 `public` 임을 확인하고 `Add a README`도 선택한 다음 `Create repository`를 클릭합니다.  

### 5.3. 접속 테스트

브라우저에서 `username.github.io` 접속 `README.md` 의 내용이 화면상에 출력됩니다.  

### 5.4. Jekyll과 저장소 연결  

튜토리얼 단계에서 만들었던 작업 디렉토리와 `username.github.io` 저장소를 연결하고 코드를 업로드 합니다.  
VSCode 를 사용해 저장소에 코드를 업로드 해보겠습니다.  

1. VSCode를 이용해 블로그 작업 디렉토리 열기  
    '폴더 열기'를 이용해 튜토리얼 작업 디레토리 열기  
    ![open-blog-path](/assets/images/blog02/open-blog-path.png)

2. .gitignore 파일 생성  
    `.gitignore` 파일을 생성하고 다음 내용을 입력한다.

    ```text
    _site/
    .jekyll-cache/
    ```

3. 리포지토리 초기화  
    소스 제어창으로 이동하여 리포지토리 초기화를 클릭한다.  
    ![repo-init](/assets/images/blog02/repo-init.png)

4. Remote Add
    REMOTES 패널의 '+' 버튼을 클릭한다.  
    ![remote-add](/assets/images/blog02/remote-add.png)

    입력창에 주소 정보를 입력하고, `Add Remote and Fetch` 를 선택한다.  
    `https://github.com/username/username.github.io`  
    ![write-repo-url](/assets/images/blog02/write-repo-url.png)

5. 모든 변경내용을 스테이징
    변경 내용의 파일들을 '+' 를 클릭하여 스테이징된 변경사항
    ![all-staging](/assets/images/blog02/all-staging.png)

6. 커밋 & 푸시  
    메시지를 작성하고 커밋을 클릭한다.
    ![commit](/assets/images/blog02/msg-and-commit.png)

    8단계의 push 진행 -> 에러가 발생한다면 7단계 수행.  

7. rebase  
    파일 충돌 혹은 히스토리 연결에 문제가 있어 Push하지 못하고 있다면
    다음 명령(rebase)을 수행해야 한다.  

    ```sh
    git rebase origin/main
    
    Auto-merging index.html
    CONFLICT (add/add): Merge conflict in index.html
    error: could not apply 23f3bae... test
    hint: Resolve all conflicts manually, mark them as resolved with
    hint: "git add/rm <conflicted_files>", then run "git rebase --continue".
    hint: You can instead skip this commit: run "git rebase --skip".
    hint: To abort and get back to the state before "git rebase", run "git rebase --abort".
    Could not apply 23f3bae... test
    ```

    충돌이 발새한 파일을 수정하고 `git rebase --continue` 실행한다.  

    ```sh
    git rebase --continue
    ```

    소스 머지가 완료되었다면 커밋 메시지를 작성하고 저장한다.  

8. push  
    충돌을 해결했다면 이제 업로드하여 확인하는 일만 남았다.  

    ![source-push](/assets/images/blog02/source-push.png)

    ![output](/assets/images/blog02/web-output.png)

## 6. 테마적용

이 문서에서는 테마를 적용하기 위한 방법 중 테마 자체를 다운로드 받아 적용하는 방법으로 진행할 예정이다.  

### 6.1. 테마 사이트

다음 사이트들에서 원하는 테마를 찾는다.  
[jamstackthemes.dev](https://jamstackthemes.dev/ssg/jekyll/)  
[jekyllthemes.org](https://jekyllthemes.org/)  
[jekyllthemes.io](https://jekyllthemes.io/)  

### 6.2. 적용

1. 테마선택  
    위 사이트들에서 원하는 테마를 선택하고 다운로드 받는다.  
    `https://github.com/tomjoht/documentation-theme-jekyll`  

2. Gemfile 수정  
    위 테마의 경우 도커를 이용하고 있습니다. 그래서 저는 `webrick`을 추가하여 로컬에서 `bundle exec jekyll serve` 명령이 실행될 수 있도록 하였습니다.  

    ```ruby
    source "https://rubygems.org"

    gem 'github-pages', group: :jekyll_plugins
    # add
    gem 'webrick'
    ```

3. build, run  

    ```sh
    bundle install
    bundle update
    bundle exec jekyll build
    bundle exec jekyll serve
    ```

4. 확인  
    ![theme-run](/assets/images/blog02/theme-run.png)

## 7. 더 많은 기능 알아보기  

* [Jekyll 사이트](https://jekyllrb-ko.github.io)  
* [댓글 기능](https://staticman.net/)  
* [검색 기능](https://www.algolia.com/blog/engineering/instant-search-blog-documentation-jekyll-plugin/)  
