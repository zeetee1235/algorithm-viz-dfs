# Heap Sort Visualizer (힙 정렬 시각화)

완전 이진 트리(Complete Binary Tree)와 1차원 배열 메모리 매핑을 실시간으로 관찰할 수 있는 인터랙티브 힙 정렬 시각화 도구입니다.

## 바로 보기

- **상시 백업 URL (GitHub Pages):** https://zeetee1235.github.io/algorithm-viz-dfs/
- **AWS App Runner URL:** https://kspzzebuzp.ap-northeast-1.awsapprunner.com
- **(보관) 이전 DFS 시각화:** [public/dfs.html](public/dfs.html) 또는 https://zeetee1235.github.io/algorithm-viz-dfs/dfs.html

> App Runner를 비용 절감을 위해 일시중지하면 AWS URL은 열리지 않습니다. 이때는 GitHub Pages URL을 사용하세요.

## 로컬 실행 (Docker)

```bash
docker build -t heap-sort-viz .
docker run --rm -p 8080:8080 heap-sort-viz
```

웹 브라우저에서 `http://localhost:8080` 접속

## 주요 기능

1. **이진 트리 & 1차원 배열 듀얼 시각화:** 트리 노드와 배열 인덱스(parent, left, right) 실시간 1:1 매핑
2. **2단계 페이즈 분리:** Phase 1 (최대 힙 구축) ➔ Phase 2 (루트 최댓값 추출 및 정렬)
3. **실시간 의사코드(Pseudocode) 트래커:** 현재 실행 중인 코드 라인 동적 하이라이트
4. **인터랙션 제어:** 재생/일시정지, 1단계(Step), 셔플, 속도 조절, 노드 개수(7/15/23/31개) 선택
5. **사운드 효과:** Web Audio API 기반 비프음 (음소거 토글 지원)
