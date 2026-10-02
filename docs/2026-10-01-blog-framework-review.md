# 블로그 프레임워크 검토: Ruby 4 지원과 Jekyll 테마 비교

- 작성일: 2026-10-01
- 대상: 이 저장소(Jekyll 4.4.1 + Chirpy 7.3.1, GitHub Actions 배포)
- 조사 방법: rubygems API, GitHub API, 각 테마 소스와 이슈를 직접 확인

## 1. 결론

- Jekyll 계열에서 Ruby 4 를 **공식** 지원하는 조합은 아직 없다.
- 로컬 실행은 이미 `Makefile` 로 Docker(Ruby 3.3)에서 돌리므로 호스트 Ruby 버전 문제는 해결된 상태다.
  Ruby 버전만으로 프레임워크를 바꿀 이유는 약하다.
- 추천은 **Chirpy 유지**. 바꾼다면 **Minimal Mistakes**.

## 2. 배경

- 이 Mac 의 Homebrew Ruby 는 4.0.3 하나뿐이고, `bundle install` 이 다음 오류로 실패했다.
  `jekyll-theme-chirpy >= 7.1.0 depends on Ruby ~> 3.1`
- `~> 3.1` 은 `>= 3.1, < 4.0` 이라는 뜻이다.
- 배포 CI(`.github/workflows/pages-deploy.yml`)는 Ruby 3.3 을 쓰므로 배포에는 문제가 없다.

## 3. 최신 Ruby(4.x) 지원 현황

| 대상             | 최신 버전           | Ruby 요구  | Ruby 4.0                         |
| ---------------- | ------------------- | ---------- | -------------------------------- |
| Jekyll           | 4.4.1 (2025-01-29)  | `>= 2.7.0` | 막지는 않지만 공식 테스트 안 함  |
| Chirpy           | 7.6.0 (2026-06-20)  | `~> 3.1`   | 설치 불가 (의도된 제한)          |
| Minimal Mistakes | 4.28.1 (2026-08-11) | 제한 없음  | 설치됨. Jekyll 위라 비공식       |
| Type on Strap    | 2.5.3 (2026-08-07)  | `>= 2.7.2` | 설치됨. Jekyll 위라 비공식       |
| Bridgetown       | 2.2.2 (2026-07-06)  | `>= 3.3.0` | 공식 지원 (CI 에서 4.0.2 테스트) |
| Nanoc            | 4.14.8 (2026-08-30) | `>= 3.2`   | 공식 지원 (CI 에 4.0 포함)       |
| Middleman        | 4.6.3 (2026-02-16)  | -          | 공식 지원 (CI 에 4.0 포함)       |

### 3.1. Jekyll 이 막혀 있는 지점

- Jekyll 은 4.4.1 이후 새 버전이 없다.
- Ruby 4.0 을 테스트에 넣는 PR(jekyll#10005)은 아직 머지되지 않았다.
- Chirpy 메인테이너는 2026-03-24 에 "Jekyll 이 Ruby 4.0 을 공식 지원하면 그때 바꾸겠다"고 답했다(chirpy#2685).
  제한을 푸는 PR(chirpy#2680)도 머지되지 않고 닫혔다.
- 따라서 어떤 Jekyll 테마든 Ruby 4 에서 돌리면 비공식이다.
- 알려진 문제는 `logger` 누락(jekyll#9915)이다. Ruby 4.0 에서 `logger` 가 기본 gem 에서 빠졌기 때문이다.
  Gemfile 에 `gem "logger"` 를 추가해 피해 간다.

### 3.2. Chirpy 의 제한은 정책이다

Chirpy gem 에는 Ruby 코드가 하나도 없고 레이아웃, 스타일, 데이터 파일만 들어 있다.
그러니 `~> 3.1` 은 기술적 한계가 아니라 "Jekyll 이 공식 지원하는 범위만 허용한다"는 정책이다.
다른 테마의 "Ruby 4 허용"도 gemspec 이 막지 않는다는 뜻일 뿐, 그 아래 Jekyll 은 여전히 비공식이다.

### 3.3. Ruby 4 를 공식 지원하는 대안

Bridgetown, Nanoc, Middleman 은 Jekyll 테마를 쓸 수 없다.
Chirpy 만큼 기능을 갖춘 블로그 테마도 없어서 레이아웃을 거의 직접 만들어야 한다. 개인 블로그용으로는 비용이 크다.

GitHub Pages 기본 빌드용 `github-pages` gem 은 Jekyll 3.10.0 에 고정돼 있고 2024-11 이후 업데이트가 없다. 선택지가 아니다.

## 4. Jekyll 테마 비교

| 순위 | 테마             | 최신 릴리스      | Stars | 한 줄 평                                         |
| ---- | ---------------- | ---------------- | ----- | ------------------------------------------------ |
| 1    | Chirpy           | 7.6.0 (2026-06)  | 10.3k | 기술 블로그 기능이 다 있고 옮길 필요가 없음      |
| 2    | Minimal Mistakes | 4.28.1 (2026-08) | 13.6k | 가장 안정적, Ruby 제약 없음                      |
| 3    | Type on Strap    | 2.5.3 (2026-08)  | 855   | Chirpy 와 기능이 가장 비슷하지만 커뮤니티가 작음 |

### 4.1. Chirpy

- 다크 모드, 검색, 목차, 코드 복사, mermaid, 댓글(giscus, utterances, disqus), 한국어 UI 를 기본 제공한다.
- 지금 Gemfile 조건(`~> 7.3, >= 7.3.1`) 그대로 7.6.0 까지 올릴 수 있다.
- 자체 CI 는 Ruby 3.3, 3.4 를 테스트한다. 공식 starter 의 배포 워크플로는 Ruby 3.4 를 쓴다.

### 4.2. Minimal Mistakes

- 후보 중 유지보수가 가장 꾸준하다. gem 과 `remote_theme` 둘 다 지원한다.
- 4.28.0 부터 `> [!TIP]` 형식의 강조 블록(GFM admonition)을 지원한다.
- 약점: 라이트/다크 자동 전환이 없다(skin 하나를 고정해서 쓴다). mermaid 와 수식은 직접 붙여야 한다.
- 기본 주소 규칙이 `/:categories/:title/` 이다. 기존 링크를 살리려면 `permalink: /posts/:title/` 을 꼭 지정한다.

### 4.3. Type on Strap

- 다크 모드(`color_theme: auto`), KaTeX 수식, mermaid, giscus/utterances, 검색, 태그, 카테고리 페이지를 기본 제공한다.
- 약점: 커뮤니티가 작다. 목차 기능을 찾지 못했다. 한국어 UI 는 `_data/language.yml` 을 직접 번역해야 한다.

### 4.4. 제외한 테마

| 테마             | 제외 이유                                                     |
| ---------------- | ------------------------------------------------------------- |
| al-folio         | 학술 포트폴리오용. 배포 CI 에 Ruby, Python, Node 가 모두 필요 |
| Just the Docs    | 문서 사이트용. 글 목록과 댓글이 없음                          |
| Beautiful Jekyll | 다크 모드와 목차 없음. 2023-06 이후 릴리스 없음               |
| TeXt             | 2020-02 이후 릴리스 없음                                      |
| Hydejack         | 2024-09 이후 push 없음                                        |
| So Simple, YAT   | 사실상 유지보수 중단                                          |

2025~2026 년에 새로 나온 블로그 테마 중 주목할 만한 것은 없었다.

## 5. 테마를 바꿀 경우의 비용

글 내용은 거의 그대로 쓸 수 있다.

- 발행 글 95개 중 Chirpy 전용 문법(`{: .prompt-* }`, `media_subpath`, `pin`, `embed`)을 쓰는 글은 0개다.
- 이미지 참조는 모두 `/assets/images/...` 절대경로라 테마와 무관하다.
- `category`(단수)는 Jekyll 표준 키라 그대로 동작한다.

손볼 곳은 다음 정도다.

- `_config.yml` 재작성. 기존 URL 유지를 위해 `permalink: /posts/:title/` 지정
- `_tabs/` 4개 페이지, `_data/contact.yml`, `_data/share.yml`
- mermaid 가 들어간 글 2개, `$$` 수식이 들어간 글 2개
- `_plugins/posts-lastmod-hook.rb` 동작 확인

## 6. Chirpy 를 유지할 때 할 일

- [ ] **UI 한국어화.** `_config.yml` 의 `lang: ko` 를 `lang: ko-KR` 로 바꾼다.
- [ ] **mermaid 렌더링.** 아래 두 글의 front matter 에 `mermaid: true` 를 추가한다.
- [ ] **Chirpy 버전 맞추기.** `Gemfile.lock` 을 커밋할지, 로컬만 업데이트할지 정한다.
- [ ] **Ruby 3.4 로 올리기.** CI(`pages-deploy.yml`)와 `Makefile` 의 `RUBY_IMAGE` 를 3.4 로 바꾼다.

**UI 한국어화 상세.** Chirpy 에는 `ko-KR.yml` 로케일만 있다. `ko` 를 찾지 못하면 영어로 대체된다.
빌드 결과에서 "Recently Updated", "Trending Tags" 가 영어로 나오는 것을 확인했다.

**mermaid 렌더링 상세.** `_posts/2025/07-12/2025-08-16-doc-embedding.md`, `_posts/2025/07-12/2025-08-07-doc-init.md`
두 글에 `mermaid: true` 가 없다. 빌드된 페이지에 mermaid 스크립트가 없어서 다이어그램이 아니라 코드 블록으로 보인다.

**Chirpy 버전 상세.** `Gemfile.lock` 이 `.gitignore` 대상이라 CI 는 배포할 때마다 조건 안의 최신 버전(현재 7.6.0)을 받는다.
로컬 lock 은 7.3.1 에 고정돼 있어서 로컬 미리보기와 배포 결과가 다를 수 있다.

- 방법 A: `Gemfile.lock` 을 커밋해서 로컬과 CI 버전을 고정한다. 업데이트는 `make shell` 에서 `bundle update` 로 한다.
- 방법 B: lock 은 커밋하지 않고, 로컬에서 주기적으로 `bundle update` 를 실행한다.

**Ruby 3.4 상세.** Ruby 3.3 은 보안 유지보수 단계이고 지원 종료가 2027-03-31 이다. Chirpy 공식 starter 는 이미 3.4 를 쓴다.

## 7. 확인 필요

- 마지막 배포(2026-05-28)에 실제로 쓰인 Chirpy 버전. Actions 로그 보관 기간이 지나서 확인하지 못했다.
- Ruby 4.0.3 에서 Jekyll 4.4.1 을 끝까지 빌드해 보지는 않았다. gemspec 과 이슈만 확인했다.
- Type on Strap 의 `remote_theme` 지원 여부.
- Hydejack, TeXt 의 세부 기능.

## 8. 출처

- Chirpy 버전: <https://rubygems.org/gems/jekyll-theme-chirpy>
- Chirpy Ruby 4 이슈: <https://github.com/cotes2020/jekyll-theme-chirpy/issues/2685>
- Chirpy Ruby 4 PR (미머지): <https://github.com/cotes2020/jekyll-theme-chirpy/pull/2680>
- Jekyll Ruby 4.0 CI PR: <https://github.com/jekyll/jekyll/pull/10005>
- Jekyll `logger` 이슈: <https://github.com/jekyll/jekyll/issues/9915>
- Ruby 4.0 릴리스 노트: <https://www.ruby-lang.org/en/news/2025/12/25/ruby-4-0-0-released/>
- Ruby 버전별 지원 상태: <https://www.ruby-lang.org/en/downloads/branches/>
- Bridgetown 배포 문서: <https://www.bridgetownrb.com/docs/deployment>
- GitHub Pages 의존성 버전: <https://pages.github.com/versions.json>
- Minimal Mistakes: <https://github.com/mmistakes/minimal-mistakes>
- Type on Strap: <https://github.com/sylhare/Type-on-Strap>
- al-folio: <https://github.com/alshedivat/al-folio>
