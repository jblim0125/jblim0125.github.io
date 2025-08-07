---
layout: post
title: 문서 목차 패턴 가져오기
author: jblim0125
date: 2025-08-09
category: 2025
tags: [LLM, RAG, LangGraph, TOC] 
---

## 목표

PDF를 OCR과 결합하여 문단형태로 텍스트를 추출하는 기능의 프로그램 제작.

문서의 목차(대목차, 중목차, 소목차)와 함께 문서 구조를 파악하여 
문서의 목차 정보와 각 목차 별 컨텐츠를 추출할 수 있는 프로그램의 제작.

추자적으로 ML, LLM, 강화학습을 이용해 보다 정확한 목차의 추출과 컨텐츠 추출이 가능하도록 발전시켜나가보자.

## 구현 방법

### 1. 라이브러리 설치

```bash
pip install pymupdf4llm
pip install pdfplumber
pip install pytesseract
pip install opencv-python
pip install langchain
pip install langchain-openai
pip install langgraph
```

### 2. 기본 구조

```python
import re
import pymupdf4llm
import pdfplumber
from typing import List, Dict, Tuple
from dataclasses import dataclass

@dataclass
class TOCItem:
    level: int
    title: str
    page_number: int
    content: str = ""

class DocumentParser:
    def __init__(self):
        # 목차 패턴 정의 (다양한 형태 고려)
        self.heading_patterns = [
            r'^(\d+\.?\s+.+)$',                    # 1. 제목
            r'^(\d+\.\d+\.?\s+.+)$',               # 1.1. 소제목
            r'^(\d+\.\d+\.\d+\.?\s+.+)$',          # 1.1.1. 세부제목
            r'^(제\s*\d+\s*장.+)$',                # 제1장 형태
            r'^([A-Z][A-Z\s]+)$',                  # 대문자 제목
            r'^(Chapter\s+\d+.+)$',                # Chapter 형태
            r'^([가-힣]\.?\s+.+)$',                # ㄱ. 한글 제목
            r'^([①-⑳]\s+.+)$',                    # ① 원형 숫자
            r'^([가나다라마바사아자차카타파하]\.\s+.+)$',  # 가. 나. 다. 형태
        ]
```

### 3. PDF 텍스트 추출

```python
def extract_text_with_coordinates(self, pdf_path: str) -> List[Dict]:
    """PDF에서 텍스트와 좌표 정보를 추출"""
    text_blocks = []
    
    with pdfplumber.open(pdf_path) as pdf:
        for page_num, page in enumerate(pdf.pages):
            # 텍스트 블록별로 추출
            chars = page.chars
            
            # 라인별로 그룹화
            lines = self._group_chars_to_lines(chars)
            
            for line in lines:
                text_blocks.append({
                    'text': line['text'],
                    'page': page_num + 1,
                    'bbox': line['bbox'],
                    'font_size': line['font_size'],
                    'font_name': line['font_name']
                })
    
    return text_blocks

def _group_chars_to_lines(self, chars: List[Dict]) -> List[Dict]:
    """문자들을 라인별로 그룹화"""
    lines = []
    if not chars:
        return lines
    
    # y 좌표 기준으로 정렬
    chars.sort(key=lambda x: (-x['top'], x['x0']))
    
    current_line = {
        'text': '',
        'bbox': [chars[0]['x0'], chars[0]['top'], chars[0]['x1'], chars[0]['bottom']],
        'font_size': chars[0]['size'],
        'font_name': chars[0]['fontname']
    }
    
    for char in chars:
        # 같은 라인인지 판단 (y 좌표 차이가 5 이하)
        if abs(char['top'] - current_line['bbox'][1]) <= 5:
            current_line['text'] += char['text']
            current_line['bbox'][2] = max(current_line['bbox'][2], char['x1'])
        else:
            if current_line['text'].strip():
                lines.append(current_line)
            
            current_line = {
                'text': char['text'],
                'bbox': [char['x0'], char['top'], char['x1'], char['bottom']],
                'font_size': char['size'],
                'font_name': char['fontname']
            }
    
    if current_line['text'].strip():
        lines.append(current_line)
    
    return lines
```

### 4. 목차 인식 및 구조화

```python
def identify_headings(self, text_blocks: List[Dict]) -> List[TOCItem]:
    """텍스트 블록에서 목차 항목을 식별"""
    toc_items = []
    
    for block in text_blocks:
        text = block['text'].strip()
        if not text:
            continue
            
        # 패턴 매칭으로 목차 레벨 판단
        level = self._get_heading_level(text)
        if level > 0:
            toc_item = TOCItem(
                level=level,
                title=text,
                page_number=block['page']
            )
            toc_items.append(toc_item)
    
    return toc_items

def _get_heading_level(self, text: str) -> int:
    """텍스트에서 목차 레벨을 판단"""
    # 숫자 패턴으로 레벨 판단
    if re.match(r'^\d+\.\d+\.\d+\.?\s+', text):  # 1.1.1. 형태
        return 3
    elif re.match(r'^\d+\.\d+\.?\s+', text):     # 1.1. 형태
        return 2
    elif re.match(r'^\d+\.?\s+', text):          # 1. 형태
        return 1
    elif re.match(r'^제\s*\d+\s*장', text):      # 제1장 형태
        return 1
    elif re.match(r'^Chapter\s+\d+', text):      # Chapter 형태
        return 1
    
    return 0  # 목차가 아님
```

### 5. 컨텐츠 추출

```python
def extract_content_by_toc(self, text_blocks: List[Dict], toc_items: List[TOCItem]) -> List[TOCItem]:
    """목차별로 컨텐츠를 추출"""
    # 텍스트 블록을 페이지별로 정렬
    text_blocks.sort(key=lambda x: (x['page'], x['bbox'][1], x['bbox'][0]))
    
    for i, toc_item in enumerate(toc_items):
        # 현재 목차부터 다음 목차까지의 컨텐츠 추출
        start_found = False
        content_lines = []
        
        next_toc_page = toc_items[i + 1].page_number if i + 1 < len(toc_items) else float('inf')
        
        for block in text_blocks:
            # 현재 목차를 찾았는지 확인
            if not start_found and block['text'].strip() == toc_item.title:
                start_found = True
                continue
            
            # 다음 목차에 도달하면 중단
            if start_found and block['page'] >= next_toc_page:
                break
                
            # 컨텐츠 수집
            if start_found:
                # 다른 목차인지 확인
                if self._get_heading_level(block['text'].strip()) > 0:
                    # 같은 레벨이거나 상위 레벨이면 중단
                    block_level = self._get_heading_level(block['text'].strip())
                    if block_level <= toc_item.level:
                        break
                
                content_lines.append(block['text'].strip())
        
        toc_item.content = '\n'.join(content_lines)
    
    return toc_items
```

### 6. LLM을 이용한 목차 정제

```python
from langchain.llms import OpenAI
from langchain.prompts import PromptTemplate

class LLMTOCRefiner:
    def __init__(self, api_key: str):
        self.llm = OpenAI(api_key=api_key)
        
    def refine_toc_structure(self, toc_items: List[TOCItem]) -> List[TOCItem]:
        """LLM을 이용하여 목차 구조를 정제"""
        
        # 목차 텍스트 준비
        toc_text = "\n".join([f"{'  ' * (item.level-1)}{item.title}" for item in toc_items])
        
        prompt = PromptTemplate(
            input_variables=["toc_text"],
            template="""
            다음 목차 구조를 분석하고 올바른 계층 구조로 정제해주세요.
            
            원본 목차:
            {toc_text}
            
            다음 규칙을 따라 정제해주세요:
            1. 논리적인 계층 구조 유지
            2. 잘못된 레벨 수정
            3. 누락된 목차 보완 제안
            4. 중복된 목차 제거
            
            정제된 목차를 같은 형식으로 반환해주세요.
            """
        )
        
        response = self.llm(prompt.format(toc_text=toc_text))
        return self._parse_refined_toc(response, toc_items)
```

### 7. 메인 실행 함수

```python
def main():
    # 문서 파서 초기화
    parser = DocumentParser()
    
    # PDF 파일 경로
    pdf_path = "sample_document.pdf"
    
    try:
        # 1. 텍스트 추출
        print("텍스트 추출 중...")
        text_blocks = parser.extract_text_with_coordinates(pdf_path)
        
        # 2. 목차 식별
        print("목차 식별 중...")
        toc_items = parser.identify_headings(text_blocks)
        
        # 3. 컨텐츠 추출
        print("컨텐츠 추출 중...")
        toc_with_content = parser.extract_content_by_toc(text_blocks, toc_items)
        
        # 4. 결과 출력
        print("\n=== 추출된 목차 및 컨텐츠 ===")
        for item in toc_with_content:
            indent = "  " * (item.level - 1)
            print(f"{indent}{item.title} (페이지: {item.page_number})")
            if item.content:
                print(f"{indent}  내용: {item.content[:100]}...")
            print()
            
    except Exception as e:
        print(f"오류 발생: {e}")

if __name__ == "__main__":
    main()
```

## 개선 방향

### 1. 머신러닝 기반 목차 인식
- 텍스트 분류 모델을 학습하여 목차/본문 구분
- CNN을 이용한 문서 레이아웃 분석
- BERT 기반 텍스트 임베딩으로 목차 패턴 학습

### 2. 강화학습 적용
- 목차 추출 정확도를 보상으로 하는 강화학습 에이전트
- 다양한 문서 형태에 대한 적응적 학습

### 3. LangGraph 활용
- 목차 추출 → 내용 분석 → 구조 정제의 워크플로우 구성
- 각 단계별 검증 및 피드백 루프

## 결론

이 구현을 통해 다양한 형태의 PDF 문서에서 목차를 자동으로 추출하고, 
각 목차별 컨텐츠를 구조화할 수 있습니다. 

향후 머신러닝과 LLM을 결합하여 더욱 정확하고 지능적인 
문서 분석 시스템으로 발전시킬 수 있을 것입니다.