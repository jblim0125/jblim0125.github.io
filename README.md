# jblim0125.github.io

개인 기술 블로그 <https://jblim0125.github.io> 의 소스 저장소다.
[Jekyll](https://jekyllrb.com/) 과 [Chirpy](https://github.com/cotes2020/jekyll-theme-chirpy) 테마(gem 방식, 7.3)로 만들었고,
`gh-pages` 브랜치에 push 하면 GitHub Actions 가 빌드해 GitHub Pages 로 배포한다.

## 1. 로컬 실행

### 1.1. 준비물

- Docker (Docker Desktop 등). 호스트에 Ruby 를 설치할 필요는 없다.

Jekyll 은 `make` 가 띄우는 Docker 컨테이너(Ruby 3.3) 안에서 실행된다.
Chirpy 7.x 는 Ruby 3.x 만 지원하고(Homebrew 기본 Ruby 는 4.x), 배포 CI 도 Ruby 3.3 을 쓰기 때문이다.

### 1.2. 명령

| 명령           | 설명                                                                     |
| -------------- | ------------------------------------------------------------------------ |
| `make`         | 명령 목록 보기                                                           |
| `make serve`   | 로컬 서버 실행. <http://localhost:4000>, 저장하면 브라우저 자동 새로고침 |
| `make drafts`  | `_drafts/` 초안까지 포함해서 로컬 서버 실행                              |
| `make build`   | 배포와 같은 production 빌드 (`_site/` 생성)                              |
| `make test`    | production 빌드 + 링크 검사. 배포 CI 와 같은 검사                        |
| `make clean`   | 빌드 결과물 삭제 (`_site/`, Jekyll 캐시)                                 |
| `make install` | gem 설치. 다른 명령이 자동으로 먼저 실행하므로 직접 부를 일은 드물다     |
| `make shell`   | 컨테이너 셸 접속. `bundle update` 같은 명령을 직접 실행할 때             |

처음 실행할 때는 이미지와 gem 을 받느라 1분 안팎 걸린다.
gem 은 Docker 볼륨 `jblim-blog-bundle` 에 캐시되므로 이후 실행은 바로 시작된다.
서버는 `Ctrl+C` 로 종료한다.

포트를 바꾸려면 `make serve PORT=4001` 처럼 변수로 넘긴다.
서버는 `127.0.0.1` 에만 바인딩되므로 같은 네트워크의 다른 장비에서는 접속할 수 없다.

### 1.3. 문제 해결

**gem 이 꼬였을 때.** 캐시 볼륨을 지우고 다시 설치한다.

```sh
docker volume rm jblim-blog-bundle
make install
```

**이미지 pull 이 실패할 때.** 기본 이미지는 Docker Hub 익명 pull 한도를 피하려고 ECR 미러
(`public.ecr.aws/docker/library/ruby:3.3`)를 쓴다. 다른 이미지를 쓰려면 `make serve RUBY_IMAGE=ruby:3.3` 처럼 넘긴다.

**`make drafts` 가 끝나지 않을 때.** Jekyll 은 `_drafts/` 안의 파일을 확장자와 상관없이 모두 글로 렌더링한다.
1MB 이상의 큰 파일이 있으면 렌더링이 수 분 이상 걸린다. `.ipynb` 는 `_config.yml` 의 `exclude` 로 빌드에서 제외해 두었다.

## 2. 글 작성

### 2.1. 새 글 만들기

`_posts/YYYY/MM/YYYY-MM-DD-<slug>.md` 로 파일을 만든다. 예: `_posts/2026/10/2026-10-01-python-logging.md`

- `<slug>` 는 영문 소문자와 하이픈으로 쓴다.
- URL 은 `/posts/<slug>/` 이다. 폴더와 날짜는 URL 에 들어가지 않으므로 **slug 가 겹치면 안 된다.**
- 하위 폴더는 정리용일 뿐이다. 2024년 글은 `_posts/2024/`, 2025년 글은 `_posts/2025/01-06/` 처럼 이전 방식으로 남아 있다.

파일 맨 위에 front matter 를 둔다.

```yaml
---
layout: post
title: "글 제목"
author: jblim0125
date: 2026-10-01
category: 2026
tags: [Python, Logging]
---
```

| 키         | 설명                                           |
| ---------- | ---------------------------------------------- |
| `layout`   | `post`. `_config.yml` 기본값이라 생략해도 된다 |
| `title`    | 글 제목                                        |
| `date`     | 발행일. 미래 날짜인 글은 빌드에서 빠진다       |
| `category` | 발행 연도. 카테고리 메뉴가 연도별로 묶인다     |
| `tags`     | 태그 목록                                      |

목차는 `_config.yml` 에서 켜져 있어 `##` 헤딩으로 자동 생성된다.
고정 글(`pin`), 수식(`math`), 대표 이미지(`image`) 같은 옵션은
[Chirpy 글 작성 가이드](https://chirpy.cotes.page/posts/write-a-new-post/)를 참고한다.

### 2.2. 이미지

이미지는 `assets/images/<연도>/<slug>/` 에 두고 사이트 루트 기준 절대경로로 참조한다.

```markdown
![구성도](/assets/images/2026/python-logging/arch.png)
```

`_drafts/` 나 `_posts/` 안에 둔 이미지는 사이트에 정적 파일로 복사되지 않는다.

### 2.3. 다른 글 링크

`post_url` 태그를 쓰면 대상 글이 없을 때 빌드가 실패하므로 깨진 링크를 미리 잡을 수 있다.
글이 하위 폴더에 있으면 `_posts/` 기준 경로까지 적는다.

```liquid
[이전 글]({% post_url 2026/10/2026-10-01-ai-era-developer-competitiveness %})
```

경로 없이 파일명만 적으면 지금은 동작하지만 Jekyll 이 deprecation 경고를 낸다.

### 2.4. 초안

- 초안은 `_drafts/` 에 둔다. 배포 빌드에는 포함되지 않고 `make drafts` 로만 확인할 수 있다.
- `_drafts/` 에는 글 초안(`.md`)만 둔다. 이미지는 읽기 오류 로그를, 큰 데이터 파일은 빌드 지연을 일으킨다.
- 배포되지 않을 뿐 git 에 커밋하면 저장소에는 그대로 올라간다. 저장소가 공개라면 민감한 메모는 커밋하지 않는다.

### 2.5. 발행 순서

1. `make serve` (초안이면 `make drafts`) 로 화면을 확인한다.
2. `make test` 로 깨진 링크·이미지가 없는지 확인한다.
3. `gh-pages` 브랜치에 커밋하고 push 한다.
4. GitHub 저장소의 Actions 탭에서 `Build and Deploy` 가 성공했는지 확인한다.

## 3. 폴더 구조

| 경로                       | 설명                                                                         |
| -------------------------- | ---------------------------------------------------------------------------- |
| `_posts/`                  | 발행 글                                                                      |
| `_drafts/`                 | 초안. 배포에서 제외                                                          |
| `_tabs/`                   | 사이드바 메뉴 페이지 (카테고리, 태그, 아카이브, About). `order` 로 순서 지정 |
| `_data/`                   | 사이드바 연락처 아이콘(`contact.yml`), 글 공유 버튼(`share.yml`)             |
| `_plugins/`                | 글의 최종 수정일을 git 이력에서 계산하는 훅                                  |
| `assets/images/`           | 글 이미지                                                                    |
| `tools/`                   | Chirpy 기본 스크립트. `test.sh` 는 `make test` 가 사용                       |
| `.github/workflows/`       | 배포 워크플로 (`pages-deploy.yml`)                                           |
| `.devcontainer/`           | VS Code Dev Container 설정                                                   |
| `_config.yml`              | 사이트 설정 (제목, 언어, 시간대, 댓글, 분석 등)                              |
| `Gemfile`                  | Ruby 의존성 (Chirpy 테마 gem, html-proofer)                                  |
| `Makefile`                 | 로컬 실행 명령                                                               |
| `_site/`, `.jekyll-cache/` | 빌드 결과물. git 에서 제외                                                   |

Chirpy 를 gem 으로 쓰기 때문에 레이아웃, include, 스타일 파일은 저장소가 아니라 gem 안에 있다.
테마 파일을 고치려면 `make shell` 에서 `bundle info --path jekyll-theme-chirpy` 로 위치를 찾고,
같은 상대경로로 저장소에 파일을 만들어 덮어쓴다.

## 4. 배포

`gh-pages` 브랜치에 push 하면 `.github/workflows/pages-deploy.yml` 이 다음을 실행한다.

1. Ruby 3.3 으로 production 빌드
2. html-proofer 로 내부 링크·이미지 검사 (`make test` 와 같은 검사)
3. GitHub Pages 에 배포

`README.md`, `LICENSE`, `.gitignore` 만 바뀐 push 는 배포를 실행하지 않는다.

## 5. 참고

- [Chirpy 위키](https://github.com/cotes2020/jekyll-theme-chirpy/wiki)
- [Chirpy 데모와 글 작성 가이드](https://chirpy.cotes.page/)
- [Jekyll 문서](https://jekyllrb.com/docs/)

[Chirpy Starter](https://github.com/cotes2020/chirpy-starter) 를 기반으로 하며, [MIT](LICENSE) 라이선스를 따른다.
