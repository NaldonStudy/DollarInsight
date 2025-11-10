"""
하이브리드 검색 모듈
- BM25 키워드 검색
- 벡터 의미 검색
- 단순하고 명확한 검색 함수들
"""

import re
import time
import numpy as np
from rank_bm25 import BM25Okapi
from FlagEmbedding import BGEM3FlagModel

# ============================================================================
# 전역 변수 및 모델
# ============================================================================

_embedding_cache = {}
_bge = BGEM3FlagModel("BAAI/bge-m3")


# ============================================================================
# 유틸리티 함수
# ============================================================================


def _ensure_embed(text):
    """텍스트 임베딩 생성 (캐싱)"""
    if text in _embedding_cache:
        return _embedding_cache[text]
    vec = _bge.encode([text])["dense_vecs"][0]
    _embedding_cache[text] = vec
    return vec


def _extract_keywords(text):
    """텍스트에서 키워드 추출 (한글, 영문 2자 이상)"""
    return list(set(re.findall(r"\b[\w가-힣]{2,}\b", text.lower())))[:5]


# ============================================================================
# 검색 함수들 (단순하고 명확하게)
# ============================================================================


def keyword_search_bm25(collections, query, top_k=2):
    """
    BM25 키워드 검색

    Args:
        collections: ChromaDB 컬렉션 리스트
        query: 검색 쿼리
        top_k: 반환할 문서 수 (기본값: 2)

    Returns:
        (문서 리스트, 메타데이터 리스트) 튜플
    """
    if not collections or not query.strip():
        return [], []

    start_time = time.time()

    # 1. 모든 컬렉션에서 문서 수집
    all_docs = []
    all_metas = []

    for col in collections:
        try:
            # 모든 문서 가져오기 (BM25 계산용)
            result = col.get(include=["documents", "metadatas"])
            if result and "documents" in result:
                all_docs.extend(result["documents"])
                metas = result.get("metadatas", [])
                all_metas.extend(metas if metas else [{}] * len(result["documents"]))
        except Exception as e:
            print(f"[BM25 검색 오류] {col.name}: {e}")
            continue

    if not all_docs:
        return [], []

    # 2. BM25 인덱스 생성 및 검색
    tokenized_corpus = [doc.split() for doc in all_docs]
    bm25 = BM25Okapi(tokenized_corpus)
    tokenized_query = query.split()
    scores = bm25.get_scores(tokenized_query)

    # 3. 상위 top_k 문서 선택
    top_indices = np.argsort(scores)[::-1][:top_k]
    top_docs = [all_docs[i] for i in top_indices]
    top_metas = [all_metas[i] if i < len(all_metas) else {} for i in top_indices]

    return top_docs, top_metas


def semantic_search_vector(collections, query, top_k=2):
    """
    벡터 의미 검색

    Args:
        collections: ChromaDB 컬렉션 리스트
        query: 검색 쿼리
        top_k: 반환할 문서 수 (기본값: 2)

    Returns:
        (문서 리스트, 메타데이터 리스트) 튜플
    """
    if not collections or not query.strip():
        return [], []

    start_time = time.time()

    # 1. 쿼리 임베딩 생성 (캐싱됨)
    vec = _ensure_embed(query)

    # 2. 모든 컬렉션에서 벡터 검색
    all_results = []

    for col in collections:
        try:
            result = col.query(
                query_embeddings=[vec.tolist()],
                n_results=top_k,
                include=["documents", "metadatas", "distances"],
            )

            if result and "documents" in result:
                docs = result["documents"][0]
                dists = result.get("distances", [[]])[0]
                metas = result.get("metadatas", [[]])[0]

                for i, doc in enumerate(docs):
                    score = 1 - dists[i] if i < len(dists) else 0.0
                    meta = metas[i] if i < len(metas) else {}
                    all_results.append((doc, meta, score))

        except Exception as e:
            print(f"[벡터 검색 오류] {col.name}: {e}")
            continue

    if not all_results:
        return [], []

    # 3. 점수 기준 정렬 및 상위 top_k 선택
    all_results.sort(key=lambda x: x[2], reverse=True)
    top_results = all_results[:top_k]

    top_docs = [r[0] for r in top_results]
    top_metas = [r[1] for r in top_results]

    return top_docs, top_metas


# ============================================================================
# 레거시 함수 (하위 호환성 유지)
# ============================================================================


def hybrid_search(
    collections,
    query,
    top_k=3,
    rerank_top_k=10,
    return_metadata=False,
    keyword_query=None,
    use_rerank=False,
):
    """
    [레거시 함수 - 하위 호환성 유지]
    하이브리드 검색: 벡터 검색 + 키워드 매칭

    새 코드에서는 keyword_search_bm25()와 semantic_search_vector() 사용 권장

    Args:
        collections: ChromaDB 컬렉션 리스트
        query: 검색 쿼리 텍스트
        top_k: 최종 반환할 문서 수
        rerank_top_k: Rerank 전 상위 문서 수
        return_metadata: 메타데이터 반환 여부
        keyword_query: 키워드 검색용 별도 쿼리 (None이면 query 사용)
        use_rerank: Rerank 사용 여부 (미사용)

    Returns:
        return_metadata=True: (문서 문자열, 메타데이터 리스트) 튜플
        return_metadata=False: 문서 문자열
    """
    # 새 검색 함수들을 사용하여 간단하게 구현
    keyword_docs, keyword_metas = keyword_search_bm25(collections, query, top_k=top_k)
    vector_docs, vector_metas = semantic_search_vector(collections, query, top_k=top_k)

    # 결과 병합 (중복 제거)
    all_docs = []
    all_metas = []
    seen = set()

    for doc, meta in zip(keyword_docs + vector_docs, keyword_metas + vector_metas):
        if doc not in seen:
            all_docs.append(doc)
            all_metas.append(meta)
            seen.add(doc)

    # top_k 제한
    final_docs = all_docs[:top_k]
    final_metas = all_metas[:top_k]

    joined = "\n\n".join(final_docs)
    return (joined, final_metas) if return_metadata else joined
