# 로컬 미리보기용 Makefile
#
# Jekyll은 Docker 컨테이너(Ruby 3.4)에서 실행한다.
# - Chirpy 7.x는 Ruby ~> 3.1(3.x)만 지원하는데, Homebrew Ruby는 4.x다.
# - GitHub Actions 배포(.github/workflows/pages-deploy.yml)도 Ruby 3.4를 쓴다.
# gem은 Docker 볼륨에 캐시되므로 설치는 최초 1회만 오래 걸린다.

# Docker 공식 ruby 이미지의 ECR 미러 (Docker Hub 익명 pull 한도를 피하기 위함)
RUBY_IMAGE ?= public.ecr.aws/docker/library/ruby:3.4
PORT       ?= 4000
BUNDLE_VOL ?= jblim-blog-bundle

# 터미널에서 실행할 때만 -it를 붙인다. 파이프·백그라운드 실행에서는 TTY가 없어 -it가 실패한다.
TTY := $(shell [ -t 0 ] && echo -it)

DOCKER_RUN = docker run --rm --init $(TTY) \
	-v "$(CURDIR)":/srv/blog -w /srv/blog \
	-v $(BUNDLE_VOL):/usr/local/bundle

.DEFAULT_GOAL := help
.PHONY: help install serve drafts build test shell clean

help: ## 명령 목록 보기
	@grep -E '^[a-z]+:.*## ' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*## "} {printf "  make %-8s %s\n", $$1, $$2}'

install: ## gem 설치 (이미 설치돼 있으면 건너뜀)
	$(DOCKER_RUN) $(RUBY_IMAGE) sh -c 'bundle check >/dev/null || bundle install'

serve: install ## 로컬 서버 실행 (http://localhost:4000, 저장 시 자동 새로고침)
	$(DOCKER_RUN) -p 127.0.0.1:$(PORT):$(PORT) -p 127.0.0.1:35729:35729 $(RUBY_IMAGE) \
		bundle exec jekyll serve -H 0.0.0.0 -P $(PORT) --livereload $(SERVE_OPTS)

drafts: SERVE_OPTS = --drafts
drafts: serve ## _drafts 글까지 포함해서 로컬 서버 실행

build: install ## 배포와 같은 production 빌드 (_site 생성)
	$(DOCKER_RUN) -e JEKYLL_ENV=production $(RUBY_IMAGE) bundle exec jekyll build

test: install ## production 빌드 + 링크 검사 (배포 CI와 동일)
	$(DOCKER_RUN) $(RUBY_IMAGE) bash tools/test.sh

shell: install ## 컨테이너 셸 접속 (bundle update 등 직접 실행용)
	$(DOCKER_RUN) $(RUBY_IMAGE) bash

clean: ## 빌드 결과물 삭제 (_site, Jekyll 캐시)
	rm -rf _site .jekyll-cache .jekyll-metadata
