# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

macOS용 개인 dotfiles 저장소. 홈 디렉토리의 설정 파일들을 이 저장소에서 관리하고, 심볼릭 링크로 `~`에 배포한다.

## Setup

이 저장소의 파일들은 `~`에 심볼릭 링크하여 사용한다. `bootstrap.sh`로 자동화할 예정 (현재 플레이스홀더).

## Architecture

### Shell Configuration Loading Order

1. `.zshenv` — 환경 변수 (Cargo PATH, GPG_TTY, Python 빌드 옵션)
2. `.zprofile` — Homebrew, 버전 매니저(rbenv, nodenv, pyenv), GPG SSH agent 초기화
3. `.zshrc` — `.zshrc.d/*.zsh` 파일들을 알파벳 순으로 자동 source

### Modular Utilities (`.zshrc.d/`)

모든 셸 함수는 기능별로 개별 `.zsh` 파일에 분리. 각 파일은 파일명과 같은 이름의 함수를 정의한다. 새 유틸리티 추가 시 `.zshrc.d/`에 `기능명.zsh` 파일을 생성하면 자동 로드된다. `.zshrc`를 직접 수정할 필요 없음.

### CPU-Aware Parallelism

`convav`와 `cmpv`는 Apple Silicon의 P-core/E-core 구분을 인식한다:
- `convav`: `hw.perflevel0.logicalcpu` (P-core 수) 기반 6단계 parallelism
- `cmpv`: E-core를 제외한 스레드 수로 VMAF 계산

### Plugin Management

Antidote(Homebrew 설치)로 Zsh 플러그인 관리. 플러그인 목록은 `.zsh_plugins.txt`에 정의.

## Conventions

- 셸 스크립트는 **Zsh 문법** 사용 (POSIX sh 아님)
- 유틸리티 함수는 `.zshrc.d/`에 개별 파일로 분리 — `.zshrc` 직접 수정 금지
