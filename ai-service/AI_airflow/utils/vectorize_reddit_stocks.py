# -*- coding: utf-8 -*-

"""
reddit_stocks.json 데이터를 kss와 bge-m3를 사용하여 벡터화하여 ChromaDB에 저장
- KSS로 문장 분리 후, 400자 청크로 묶기 (100자 overlap)
- 각 청크에 제목 포함
- 뉴스 데이터와 유사한 구조로 저장하되 별도 컬렉션 사용
"""

import os
import sys
from pathlib import Path
from typing import List, Dict, Optional
from datetime import datetime
import time
import json

# Hugging Face 캐시 디렉토리 설정 (권한 문제 해결)
if not os.getenv("HF_HOME"):
    os.environ["HF_HOME"] = "/opt/airflow/.cache/huggingface"
if not os.getenv("TRANSFORMERS_CACHE"):
    os.environ["TRANSFORMERS_CACHE"] = "/opt/airflow/.cache/huggingface"
if not os.getenv("HF_DATASETS_CACHE"):
    os.environ["HF_DATASETS_CACHE"] = "/opt/airflow/.cache/huggingface"

# 캐시 디렉토리 생성
cache_dir = os.environ.get("HF_HOME", "/opt/airflow/.cache/huggingface")
os.makedirs(cache_dir, exist_ok=True)
try:
    os.chmod(cache_dir, 0o755)
except PermissionError:
    pass

# ChromaDB 직접 연결
from chromadb import HttpClient
from chromadb.config import Settings

from dotenv import load_dotenv
import kss
from FlagEmbedding import FlagModel

load_dotenv()

# ============================================================================
# 환경 변수
# ============================================================================

# ChromaDB 설정
CHROMADB_URL = os.getenv("CHROMADB_URL", "3.34.50.3")
CHROMADB_PORT = int(os.getenv("CHROMADB_PORT", "9000"))
CHROMADB_COLLECTION_NAME = os.getenv("CHROMADB_REDDIT_COLLECTION_NAME", "reddit_stocks_bge_m3")

# BGE-M3 모델 설정
BGE_M3_MODEL_NAME = "BAAI/bge-m3"
BGE_M3_MODEL_PATH = os.getenv("BGE_M3_MODEL_PATH", None)

# Reddit 데이터 파일 경로
REDDIT_STOCKS_JSON = os.getenv("REDDIT_STOCKS_JSON", "/opt/airflow/data/reddit_stocks.json")


# ============================================================================
# ChromaDB 연결
# ============================================================================


def make_chroma_client():
    """ChromaDB 클라이언트 생성"""
    return HttpClient(
        host=CHROMADB_URL,
        port=CHROMADB_PORT,
        settings=Settings(anonymized_telemetry=False),
    )


# ============================================================================
# 데이터 로드 및 전처리
# ============================================================================


def load_reddit_data(json_file: str) -> List[Dict]:
    """
    reddit_stocks.json 파일에서 데이터 로드
    
    Returns:
        Reddit 포스트 리스트
    """
    if not os.path.exists(json_file):
        print(f"⚠️ 파일이 존재하지 않습니다: {json_file}")
        return []
    
    try:
        with open(json_file, "r", encoding="utf-8") as f:
            data = json.load(f)
        
        # 데이터 구조: [{crawled_at, subreddits, posts: [...]}]
        all_posts = []
        for entry in data:
            if isinstance(entry, dict) and "posts" in entry:
                for post in entry["posts"]:
                    # Reddit 포스트를 뉴스와 유사한 구조로 변환
                    reddit_post = {
                        "title": post.get("title", ""),
                        "content": post.get("content", ""),
                        "date": post.get("날짜", ""),
                        "url": post.get("url", ""),
                        "permalink": post.get("permalink", ""),
                        "subreddit": post.get("subreddit", ""),
                        "score": post.get("score", 0),
                        "num_comments": post.get("num_comments", 0),
                        "source": "reddit"  # 출처 구분
                    }
                    all_posts.append(reddit_post)
        
        print(f"✅ Reddit 데이터 로드 완료: {len(all_posts)}개 포스트")
        return all_posts
    
    except Exception as e:
        print(f"❌ Reddit 데이터 로드 실패: {str(e)}")
        import traceback
        traceback.print_exc()
        return []


def chunk_text(text: str, chunk_size: int = 400, overlap: int = 100) -> List[str]:
    """
    텍스트를 청크로 분할 (뉴스와 동일한 방식)
    - KSS로 문장 분리 후, chunk_size 길이로 묶기
    - overlap만큼 겹치게 설정
    """
    if not text or not text.strip():
        return []
    
    # KSS로 문장 분리
    try:
        sentences = kss.split_sentences(text)
    except Exception as e:
        print(f"⚠️ 문장 분리 실패: {e}, 전체 텍스트를 하나의 청크로 처리")
        sentences = [text]
    
    chunks = []
    current_chunk = ""
    
    for sentence in sentences:
        sentence = sentence.strip()
        if not sentence:
            continue
        
        # 현재 청크에 문장 추가 시 길이 확인
        test_chunk = current_chunk + (" " if current_chunk else "") + sentence
        
        if len(test_chunk) <= chunk_size:
            current_chunk = test_chunk
        else:
            # 현재 청크 저장
            if current_chunk:
                chunks.append(current_chunk)
            
            # overlap 고려하여 새 청크 시작
            if overlap > 0 and current_chunk:
                # 마지막 overlap 길이만큼 가져오기
                overlap_text = current_chunk[-overlap:] if len(current_chunk) >= overlap else current_chunk
                current_chunk = overlap_text + " " + sentence
            else:
                current_chunk = sentence
    
    # 마지막 청크 추가
    if current_chunk:
        chunks.append(current_chunk)
    
    return chunks


def prepare_chunks_for_reddit(posts: List[Dict]) -> List[Dict]:
    """
    Reddit 포스트를 벡터화할 수 있는 청크로 변환
    - 제목 + 본문을 합쳐서 청크 생성
    - 각 청크에 메타데이터 포함
    """
    all_chunks = []
    
    for post_idx, post in enumerate(posts):
        title = post.get("title", "").strip()
        content = post.get("content", "").strip()
        
        # 제목과 본문 결합
        if content:
            full_text = f"{title}\n\n{content}"
        else:
            full_text = title
        
        if not full_text.strip():
            continue
        
        # 텍스트 청크 분할
        text_chunks = chunk_text(full_text, chunk_size=400, overlap=100)
        
        # 각 청크에 메타데이터 추가
        for chunk_idx, chunk in enumerate(text_chunks):
            chunk_data = {
                "text": chunk,
                "title": title[:200],  # ChromaDB 메타데이터 길이 제한
                "date": post.get("date", ""),
                "url": post.get("url", ""),
                "permalink": post.get("permalink", ""),
                "subreddit": post.get("subreddit", ""),
                "score": post.get("score", 0),
                "num_comments": post.get("num_comments", 0),
                "source": "reddit",
                "chunk_index": chunk_idx,
                "total_chunks": len(text_chunks),
                "post_index": post_idx
            }
            all_chunks.append(chunk_data)
    
    return all_chunks


# ============================================================================
# ChromaDB 저장
# ============================================================================


def get_or_create_chromadb_collection(client, collection_name: str):
    """ChromaDB 컬렉션 가져오기 또는 생성"""
    try:
        collection = client.get_collection(collection_name)
        print(f"✅ 기존 컬렉션 사용: {collection_name}")
        return collection
    except Exception:
        # 컬렉션이 없으면 생성
        collection = client.create_collection(
            name=collection_name,
            metadata={"description": "Reddit stocks posts vectorized with bge-m3"}
        )
        print(f"✅ 새 컬렉션 생성: {collection_name}")
        return collection


def save_to_chromadb(chunks: List[Dict], collection, embedder):
    """
    가공된 Reddit 포스트 청크를 ChromaDB에 벡터화하여 저장
    
    Args:
        chunks: 청크 데이터 리스트
        collection: ChromaDB 컬렉션
        embedder: BGE-M3 임베딩 모델
    """
    if not chunks:
        print("⚠️ 저장할 청크가 없습니다.")
        return {"saved_chunks": 0, "skipped": 0}
    
    stats = {"saved_chunks": 0, "skipped": 0}
    
    # 기존 문서 ID 확인 (중복 방지)
    existing_ids = set()
    try:
        existing_docs = collection.get()
        if existing_docs and existing_docs.get("ids"):
            existing_ids = set(existing_docs["ids"])
            print(f"   기존 문서 수: {len(existing_ids)}개")
    except Exception:
        pass
    
    import urllib.parse
    
    # 중복 제거: 벡터화 전에 중복 체크하여 필터링
    new_chunks = []
    
    for chunk_idx, chunk in enumerate(chunks):
        # 고유 ID 생성
        permalink = chunk.get('permalink', '')
        chunk_index = chunk.get('chunk_index', 0)
        doc_id = f"reddit_{permalink}_{chunk_index}"
        doc_id = urllib.parse.quote(doc_id, safe='')
        
        # 중복 체크 (벡터화 전에 수행)
        if doc_id in existing_ids:
            stats["skipped"] += 1
            continue
        
        new_chunks.append(chunk)
        new_chunk_indices.append(chunk_idx)
    
    if stats["skipped"] > 0:
        print(f"   ⚠️ 중복 건너뜀: {stats['skipped']}개 청크 (벡터화 전 필터링)")
    
    if not new_chunks:
        print("   ⚠️ 저장할 새로운 청크가 없습니다.")
        return stats
    
    # 벡터화할 텍스트 추출 (중복 제거된 청크만)
    all_texts = [chunk["text"] for chunk in new_chunks]
    
    # 벡터화 (중복 제거된 청크만)
    vectorize_batch_size = 64
    print(f"   벡터화 중... (총 {len(all_texts)}개 청크, 배치 크기: {vectorize_batch_size})")
    vectorize_start = time.time()
    try:
        embeddings = embedder.encode(all_texts, batch_size=vectorize_batch_size)
        vectorize_elapsed = time.time() - vectorize_start
        print(f"   ✅ 벡터화 완료 (소요 시간: {vectorize_elapsed:.1f}초)")
    except Exception as e:
        print(f"   ❌ 벡터화 실패: {str(e)}")
        return stats
    
    # ChromaDB에 저장 (배치 단위)
    batch_size = 100
    total_batches = (len(new_chunks) + batch_size - 1) // batch_size
    
    save_start = time.time()
    
    # 모든 청크에 대해 ID, 메타데이터, 문서 준비
    all_ids = []
    all_metadatas = []
    all_documents = []
    all_embeddings_list = []
    
    for chunk_idx, chunk in enumerate(new_chunks):
        # 고유 ID 생성
        permalink = chunk.get('permalink', '')
        chunk_index = chunk.get('chunk_index', 0)
        doc_id = f"reddit_{permalink}_{chunk_index}"
        doc_id = urllib.parse.quote(doc_id, safe='')
        
        all_ids.append(doc_id)
        all_documents.append(chunk["text"])
        all_embeddings_list.append(embeddings[chunk_idx])
        
        # 메타데이터 (ChromaDB 제한: 문자열 값만 가능)
        metadata = {
            "title": str(chunk.get("title", ""))[:200],
            "date": str(chunk.get("date", ""))[:100],
            "url": str(chunk.get("url", ""))[:500],
            "permalink": str(permalink)[:500],
            "subreddit": str(chunk.get("subreddit", ""))[:100],
            "score": str(chunk.get("score", 0)),
            "num_comments": str(chunk.get("num_comments", 0)),
            "source": "reddit",
            "chunk_index": str(chunk_index),
            "total_chunks": str(chunk.get("total_chunks", 1))
        }
        all_metadatas.append(metadata)
    
    # 배치 단위로 저장
    for batch_idx in range(0, len(all_ids), batch_size):
        batch_num = (batch_idx // batch_size) + 1
        end_idx = min(batch_idx + batch_size, len(all_ids))
        
        batch_ids = all_ids[batch_idx:end_idx]
        batch_documents = all_documents[batch_idx:end_idx]
        batch_metadatas = all_metadatas[batch_idx:end_idx]
        batch_embeddings = all_embeddings_list[batch_idx:end_idx]
        
        # numpy 배열을 리스트로 변환
        if hasattr(batch_embeddings[0], 'tolist'):
            batch_embeddings = [emb.tolist() for emb in batch_embeddings]
        elif hasattr(batch_embeddings, 'tolist'):
            batch_embeddings = batch_embeddings.tolist()
        
        try:
            collection.add(
                ids=batch_ids,
                embeddings=batch_embeddings,
                documents=batch_documents,
                metadatas=batch_metadatas
            )
            stats["saved_chunks"] += len(batch_ids)
            print(f"   배치 {batch_num}/{total_batches} 저장 완료: {len(batch_ids)}개 청크")
        except Exception as e:
            print(f"   ⚠️ 배치 {batch_num} 저장 실패: {str(e)}")
            import traceback
            traceback.print_exc()
            continue
    
    save_elapsed = time.time() - save_start
    print(f"   ✅ ChromaDB 저장 완료: 총 {stats['saved_chunks']}개 청크 저장 (소요 시간: {save_elapsed:.1f}초)")
    if stats["skipped"] > 0:
        print(f"   ⚠️ 중복 건너뜀: {stats['skipped']}개 청크")
    
    return stats


# ============================================================================
# 메인 함수
# ============================================================================


def vectorize_reddit_stocks(
    json_file: str = None,
    collection_name: str = None
):
    """
    reddit_stocks.json 데이터를 벡터화하여 ChromaDB에 저장
    
    Args:
        json_file: Reddit JSON 파일 경로 (None이면 환경 변수에서 가져옴)
        collection_name: ChromaDB 컬렉션 이름 (None이면 환경 변수에서 가져옴)
    """
    json_file = json_file or REDDIT_STOCKS_JSON
    collection_name = collection_name or CHROMADB_COLLECTION_NAME
    
    print("=" * 70)
    print("🔄 Reddit Stocks 데이터 벡터화 시작")
    print("=" * 70)
    
    # 1. Reddit 데이터 로드
    print(f"\n1️⃣ Reddit 데이터 로드 중: {json_file}")
    posts = load_reddit_data(json_file)
    
    if not posts:
        print("⚠️ Reddit 데이터가 없습니다. 프로세스를 종료합니다.")
        return {"status": "no_data", "saved_chunks": 0}
    
    print(f"   로드된 포스트: {len(posts)}개")
    
    # 2. BGE-M3 모델 로드
    print(f"\n2️⃣ BGE-M3 모델 로드 중: {BGE_M3_MODEL_NAME}")
    model_start = time.time()
    try:
        if BGE_M3_MODEL_PATH and os.path.exists(BGE_M3_MODEL_PATH):
            embedder = FlagModel(BGE_M3_MODEL_PATH, use_fp16=True)
            print(f"   로컬 모델 사용: {BGE_M3_MODEL_PATH}")
        else:
            embedder = FlagModel(BGE_M3_MODEL_NAME, use_fp16=True)
            print(f"   Hugging Face 모델 사용: {BGE_M3_MODEL_NAME}")
        model_elapsed = time.time() - model_start
        print(f"   ✅ 모델 로드 완료 (소요 시간: {model_elapsed:.1f}초)")
    except Exception as e:
        print(f"   ❌ 모델 로드 실패: {str(e)}")
        import traceback
        traceback.print_exc()
        return {"status": "model_load_failed", "saved_chunks": 0}
    
    # 3. 텍스트 청크 생성
    print(f"\n3️⃣ 텍스트 청크 생성 중...")
    chunks = prepare_chunks_for_reddit(posts)
    print(f"   생성된 청크: {len(chunks)}개")
    
    # 4. ChromaDB 연결
    print(f"\n4️⃣ ChromaDB 연결 중: {CHROMADB_URL}:{CHROMADB_PORT}/{collection_name}")
    chroma_client = make_chroma_client()
    chroma_collection = get_or_create_chromadb_collection(chroma_client, collection_name)
    
    # 5. ChromaDB 저장
    print(f"\n5️⃣ ChromaDB 저장 중...")
    stats = save_to_chromadb(chunks, chroma_collection, embedder)
    
    print("\n" + "=" * 70)
    print("✅ Reddit Stocks 벡터화 완료!")
    print("=" * 70)
    print(f"저장된 청크: {stats['saved_chunks']}개")
    if stats.get("skipped", 0) > 0:
        print(f"중복 건너뜀: {stats['skipped']}개")
    
    return {"status": "success", **stats}


if __name__ == "__main__":
    stats = vectorize_reddit_stocks()
    print(f"\n최종 결과: {json.dumps(stats, indent=2, ensure_ascii=False)}")

