# -*- coding: utf-8 -*-

"""
MongoDB의 뉴스 데이터를 kss와 bge-m3를 사용하여 벡터화하여 ChromaDB에 저장
- KSS로 문장 분리 후, 400자 청크로 묶기 (100자 overlap)
- 각 청크에 제목 포함
- 페르소나 분석 제외
"""

import os
import sys
from pathlib import Path
from typing import List, Dict, Optional
from datetime import datetime
import time

# Hugging Face 캐시 디렉토리 설정 (권한 문제 해결)
# Docker 컨테이너 내부에서 쓰기 가능한 위치로 설정
if not os.getenv("HF_HOME"):
    os.environ["HF_HOME"] = "/opt/airflow/.cache/huggingface"
if not os.getenv("TRANSFORMERS_CACHE"):
    os.environ["TRANSFORMERS_CACHE"] = "/opt/airflow/.cache/huggingface"
if not os.getenv("HF_DATASETS_CACHE"):
    os.environ["HF_DATASETS_CACHE"] = "/opt/airflow/.cache/huggingface"

# 캐시 디렉토리 생성 (없으면 생성)
cache_dir = os.environ.get("HF_HOME", "/opt/airflow/.cache/huggingface")
os.makedirs(cache_dir, exist_ok=True)
# 권한 변경 시도 (권한이 없으면 무시)
try:
    os.chmod(cache_dir, 0o755)
except PermissionError:
    # 권한이 없어도 계속 진행 (디렉토리는 이미 생성됨)
    pass

# ChromaDB 직접 연결 (FastAPI 의존성 제거)
from chromadb import HttpClient
from chromadb.config import Settings

import pymongo
from pymongo import MongoClient
from dotenv import load_dotenv
from pathlib import Path
import kss
from FlagEmbedding import FlagModel

# .env 파일 경로 명시적으로 지정 (Airflow 컨테이너 내부 경로 사용)
# docker-compose에서 /opt/airflow/.env로 마운트됨
# override=True: 기존 환경 변수를 .env 파일의 값으로 덮어씀
env_path = Path("/opt/airflow/.env")
if env_path.exists():
    load_dotenv(dotenv_path=env_path, override=True)
else:
    # 절대 경로에서도 시도
    env_path_abs = Path("/opt/S13P31B205/ai-service/.env")
    if env_path_abs.exists():
        load_dotenv(dotenv_path=env_path_abs, override=True)
    else:
        # 기본 경로에서도 시도
        load_dotenv(override=True)

# ============================================================================
# 환경 변수
# ============================================================================

# MONGODB_HOST는 docker-compose에서 설정되지만, 기본값이 mongodb일 수 있음
# 실제 컨테이너 이름은 dollar-insight-mongodb이므로 .env 파일에서 읽도록 함
MONGODB_HOST = os.getenv("MONGODB_HOST", "dollar-insight-mongodb")
MONGODB_PORT = int(os.getenv("MONGODB_PORT", "27017"))
MONGODB_DB = os.getenv("MONGODB_DB", "dollar_insight")
# 뉴스 기본 정보 컬렉션 사용 (벡터화는 뉴스 기본 정보에서)
MONGODB_NEWS_COLLECTION = os.getenv("MONGODB_NEWS_COLLECTION", "investing_news")
# MongoDB 인증 정보 (선택사항)
# .env 파일의 MONGODB_USER, MONGODB_PASSWORD 또는 MONGO_USER, MONGO_PASSWORD 사용
# docker-compose-airflow.yml에서 MONGO_USER, MONGO_PASSWORD로 설정되므로 둘 다 확인
# strip()으로 개행 문자 제거
_mongodb_user = os.getenv("MONGODB_USER") or os.getenv("MONGODB_USERNAME") or os.getenv("MONGO_USER")
_mongodb_pass = os.getenv("MONGODB_PASSWORD") or os.getenv("MONGO_PASSWORD")
MONGODB_USERNAME = _mongodb_user.strip() if _mongodb_user and _mongodb_user.strip() else None
MONGODB_PASSWORD = _mongodb_pass.strip() if _mongodb_pass and _mongodb_pass.strip() else None
MONGODB_AUTH_SOURCE = os.getenv("MONGODB_AUTH_SOURCE", "admin").strip()

# ChromaDB 설정
CHROMADB_URL = os.getenv("CHROMADB_URL", "3.34.50.3")
CHROMADB_PORT = int(os.getenv("CHROMADB_PORT", "9000"))
CHROMADB_COLLECTION_NAME = os.getenv("CHROMADB_COLLECTION_NAME", "news_bge_m3")

# BGE-M3 모델 설정
BGE_M3_MODEL_NAME = "BAAI/bge-m3"
BGE_M3_MODEL_PATH = os.getenv("BGE_M3_MODEL_PATH", None)  # 로컬 모델 경로 (선택사항)


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
# MongoDB 연결
# ============================================================================


def get_mongodb_client() -> MongoClient:
    """MongoDB 클라이언트 생성 (인증 지원)"""
    if MONGODB_USERNAME and MONGODB_PASSWORD:
        # 인증 정보가 있으면 인증 포함 (URL 인코딩 적용)
        from urllib.parse import quote_plus
        username = quote_plus(str(MONGODB_USERNAME))
        password = quote_plus(str(MONGODB_PASSWORD))
        connection_string = f"mongodb://{username}:{password}@{MONGODB_HOST}:{MONGODB_PORT}/{MONGODB_DB}?authSource={MONGODB_AUTH_SOURCE}"
        return MongoClient(connection_string)
    else:
        # 인증 정보가 없으면 기본 연결
        return MongoClient(MONGODB_HOST, MONGODB_PORT)


def get_mongodb_news_collection(client: MongoClient = None):
    """뉴스 기본 정보 컬렉션 가져오기 (벡터화용)"""
    if client is None:
        client = get_mongodb_client()
    db = client[MONGODB_DB]
    return db[MONGODB_NEWS_COLLECTION]


# ============================================================================
# 텍스트 전처리 (KSS + 청크 단위 분할)
# ============================================================================


def split_text_into_sentences(text: str, use_kss: bool = True) -> List[str]:
    """
    텍스트를 문장 단위로 분리
    - 기본적으로 KSS + Mecab 백엔드 사용 (빠르고 정확함)
    - use_kss=False일 때 정규식 기반 분리 사용 (더 빠르지만 정확도 낮음)
    
    Args:
        text: 분할할 텍스트
        use_kss: KSS 사용 여부 (기본값: True - Mecab 백엔드 사용)
    
    Returns:
        문장 리스트
    """
    if not text or not text.strip():
        return []
    
    if use_kss:
        # KSS + Mecab 백엔드 사용 (빠르고 정확함)
        sentences = kss.split_sentences(text)
    else:
        # 빠른 정규식 기반 문장 분리 (한국어 문장 종결 부호 기준)
        import re
        # 문장 종결 부호: . ! ? (한국어/영문 모두)
        # 줄바꿈도 문장 구분자로 사용
        pattern = r'([.!?。！？]\s*|\n+)'
        parts = re.split(pattern, text)
        
        sentences = []
        current_sentence = ""
        for i, part in enumerate(parts):
            if re.match(pattern, part):
                # 종결 부호나 줄바꿈 발견
                if current_sentence.strip():
                    sentences.append(current_sentence.strip())
                current_sentence = ""
            else:
                current_sentence += part
        
        # 마지막 문장 추가
        if current_sentence.strip():
            sentences.append(current_sentence.strip())
    
    # 빈 문장 제거 및 공백 제거
    result = []
    for sentence in sentences:
        sentence = sentence.strip()
        if sentence and len(sentence) > 5:  # 너무 짧은 문장 제거
            result.append(sentence)
    
    return result


def create_chunks_from_sentences(sentences: List[str], chunk_size: int = 400, overlap_size: int = 100) -> List[str]:
    """
    문장 리스트를 지정된 크기의 청크로 묶기 (overlap 적용)
    
    Args:
        sentences: 문장 리스트 (KSS로 분리된 것)
        chunk_size: 청크 크기 (문자 수)
        overlap_size: 청크 간 겹치는 문자 수 (overlap을 위해 포함할 문자 수)
    
    Returns:
        청크 리스트
    """
    if not sentences:
        return []
    
    chunks = []
    current_chunk = []
    current_length = 0
    overlap_sentences = []  # overlap을 위한 문장 저장
    
    for sentence in sentences:
        sentence_length = len(sentence)
        
        # 현재 청크에 문장 추가 시 예상 길이
        if current_chunk:
            # 공백 포함
            expected_length = current_length + sentence_length + 1
        else:
            expected_length = current_length + sentence_length
        
        # 청크 크기를 초과하면 현재 청크 저장
        if expected_length > chunk_size and current_chunk:
            # 현재 청크 저장
            chunk_text = " ".join(current_chunk)
            chunks.append(chunk_text)
            
            # Overlap을 위해 마지막 몇 개 문장을 다음 청크 시작점으로 사용
            overlap_sentences = []
            overlap_length = 0
            
            # 뒤에서부터 overlap_size만큼 문장 수집
            for i in range(len(current_chunk) - 1, -1, -1):
                sent = current_chunk[i]
                if overlap_length + len(sent) <= overlap_size:
                    overlap_sentences.insert(0, sent)
                    overlap_length += len(sent) + 1  # 공백 포함
                else:
                    break
            
            # 다음 청크 시작 (overlap 문장 포함)
            current_chunk = overlap_sentences.copy()
            current_length = overlap_length - 1 if overlap_sentences else 0  # 마지막 공백 제거
            
            # 현재 문장 추가
            if current_chunk:
                current_chunk.append(sentence)
                current_length = current_length + sentence_length + 1
            else:
                current_chunk = [sentence]
                current_length = sentence_length
        else:
            # 현재 청크에 문장 추가
            current_chunk.append(sentence)
            current_length = expected_length
    
    # 마지막 청크 저장
    if current_chunk:
        chunk_text = " ".join(current_chunk)
        chunks.append(chunk_text)
    
    return chunks


def prepare_text_for_embedding(article: Dict) -> List[str]:
    """
    뉴스 기사를 벡터화할 텍스트 청크로 변환
    - KSS로 문장 분리 후, 400자 청크로 묶기 (100자 overlap)
    - 각 청크에 제목 붙이기
    - 페르소나 분석 제외
    
    Args:
        article: 뉴스 기본 정보 (title, content, summary 포함)
    
    Returns:
        청크 리스트 (각 청크에 title이 포함됨)
    """
    title = article.get("title", "")
    content = article.get("content", "")
    
    if not content or not content.strip():
        return []
    
    # 1. KSS로 문장 분리
    sentences = split_text_into_sentences(content)
    
    if not sentences:
        return []
    
    # 2. 문장들을 400자 청크로 묶기 (100자 overlap)
    content_chunks = create_chunks_from_sentences(sentences, chunk_size=400, overlap_size=100)
    
    # 3. 각 청크에 title 붙이기
    chunks = []
    for chunk in content_chunks:
        if title:
            # title + 청크 조합
            combined = f"{title} {chunk}"
        else:
            combined = chunk
        
        chunks.append(combined)
    
    return chunks


# ============================================================================
# 벡터화 (BGE-M3 사용)
# ============================================================================


class BGE_M3_Embedder:
    """BGE-M3 모델을 사용한 임베딩 클래스"""
    
    def __init__(self, model_path: Optional[str] = None):
        """
        BGE-M3 모델 초기화
        
        Args:
            model_path: 로컬 모델 경로 (None이면 HuggingFace에서 자동 다운로드)
        """
        print(f"🔄 BGE-M3 모델 로딩 중...")
        try:
            if model_path and os.path.exists(model_path):
                self.model = FlagModel(model_path, use_fp16=True)
                print(f"✅ 로컬 모델 로드 완료: {model_path}")
            else:
                self.model = FlagModel(BGE_M3_MODEL_NAME, use_fp16=True)
                print(f"✅ HuggingFace 모델 로드 완료: {BGE_M3_MODEL_NAME}")
        except Exception as e:
            print(f"❌ 모델 로드 실패: {str(e)}")
            raise
    
    def encode(self, texts: List[str], batch_size: int = 32) -> List[List[float]]:
        """
        텍스트 리스트를 벡터로 변환
        
        Args:
            texts: 텍스트 리스트
            batch_size: 배치 크기 (메모리 효율을 위해 작은 배치 사용)
        
        Returns:
            벡터 리스트 (각 텍스트에 대한 임베딩 벡터)
        """
        if not texts:
            return []
        
        # 메모리 효율을 위해 적절한 배치 크기로 처리
        # 전체를 한 번에 처리하면 메모리 부족으로 프로세스가 종료될 수 있음
        all_embeddings = []
        total_batches = (len(texts) + batch_size - 1) // batch_size
        
        print(f"   배치 처리 모드 (배치 크기: {batch_size}, 총 {total_batches}개 배치)")
        
        for i in range(0, len(texts), batch_size):
            batch_num = (i // batch_size) + 1
            batch = texts[i:i + batch_size]
            try:
                # 진행률 출력 (10배치마다 또는 마지막 배치)
                if batch_num % 10 == 0 or batch_num == total_batches:
                    print(f"      벡터화 진행 중: {batch_num}/{total_batches} 배치 ({i+1}~{min(i+len(batch), len(texts))}/{len(texts)}개 청크)")
                
                # BGE-M3 encode: dense 벡터 반환
                embeddings = self.model.encode(batch)
                
                # numpy array를 list로 변환
                if hasattr(embeddings, 'tolist'):
                    embeddings = embeddings.tolist()
                
                all_embeddings.extend(embeddings)
                
                # 메모리 정리 (가비지 컬렉션)
                if batch_num % 20 == 0:
                    import gc
                    gc.collect()
                    
            except Exception as e:
                print(f"⚠️ 배치 임베딩 실패 (인덱스 {i}): {str(e)}")
                import traceback
                traceback.print_exc()
                # 실패한 배치는 빈 벡터로 채움
                all_embeddings.extend([[0.0] * 1024] * len(batch))  # BGE-M3는 1024차원
        
        print(f"   ✅ 벡터화 완료: 총 {len(all_embeddings)}개 벡터 생성")
        return all_embeddings


# ============================================================================
# ChromaDB 저장
# ============================================================================


def get_or_create_chromadb_collection(client, collection_name: str):
    """ChromaDB 컬렉션 가져오기 또는 생성"""
    try:
        collection = client.get_collection(collection_name)
        print(f"✅ 기존 컬렉션 로드: {collection_name}")
    except Exception:
        # 컬렉션이 없으면 생성
        collection = client.create_collection(
            name=collection_name,
            metadata={"description": "Investing.com 뉴스 벡터 데이터베이스 (BGE-M3)"}
        )
        print(f"✅ 새 컬렉션 생성: {collection_name}")
    
    return collection


def save_to_chromadb(
    articles: List[Dict],
    collection,
    embedder,  # FlagModel 직접 사용 (BGE_M3_Embedder 대신)
    batch_size: int = 50  # 10 -> 50으로 증가하여 저장 속도 향상
) -> Dict[str, int]:
    """
    가공된 뉴스 기사를 ChromaDB에 벡터화하여 저장
    
    Args:
        articles: MongoDB에서 가져온 뉴스 기사 리스트
        collection: ChromaDB 컬렉션
        embedder: BGE-M3 임베더
        batch_size: 배치 크기
    
    Returns:
        통계 정보
    """
    stats = {
        "total_articles": len(articles),
        "total_chunks": 0,
        "saved_chunks": 0,
        "errors": 0
    }
    
    # 기존 문서 ID 확인 (중복 방지)
    existing_ids = set()
    try:
        existing = collection.get()
        existing_ids = set(existing.get("ids", []))
    except Exception:
        pass
    
    print(f"   기존 벡터 데이터: {len(existing_ids)}개")
    
    # 각 기사 처리
    all_texts = []
    all_metadatas = []
    all_ids = []
    
    print(f"   기사 전처리 중... (총 {len(articles)}개 기사)")
    preprocess_start = time.time()
    for idx, article in enumerate(articles, 1):
        if idx % 10 == 0 or idx == len(articles):
            elapsed = time.time() - preprocess_start
            print(f"      전처리 진행 중: {idx}/{len(articles)}개 기사 처리 완료 (소요 시간: {elapsed:.1f}초)")
        article_id = str(article.get("_id", ""))
        url = article.get("url", "")
        
        # 텍스트 청크 준비
        chunks = prepare_text_for_embedding(article)
        
        if not chunks:
            continue
        
        stats["total_chunks"] += len(chunks)
        
        # 각 청크에 대한 메타데이터 준비
        for chunk_idx, chunk in enumerate(chunks):
            chunk_id = f"{article_id}_chunk_{chunk_idx}"
            
            # 중복 체크
            if chunk_id in existing_ids:
                continue
            
            all_texts.append(chunk)
            all_metadatas.append({
                "article_id": article_id,
                "url": url,
                "title": article.get("title", "")[:200],  # ChromaDB 메타데이터 길이 제한
                "date": article.get("date", ""),
                "chunk_index": chunk_idx,
                "total_chunks": len(chunks),
            })
            all_ids.append(chunk_id)
    
    if not all_texts:
        print("   신규 벡터화할 청크가 없습니다.")
        return stats
    
    print(f"   벡터화할 청크: {len(all_texts)}개")
    
    # 벡터화 - Reddit처럼 FlagModel을 직접 사용하여 효율적으로 처리
    vectorize_batch_size = 64  # Reddit과 동일한 배치 크기
    print(f"   벡터화 중... (총 {len(all_texts)}개 청크, 배치 크기: {vectorize_batch_size})")
    vectorize_start = time.time()
    try:
        # FlagModel의 encode를 직접 호출 (내부 최적화 활용, Reddit과 동일한 방식)
        embeddings = embedder.encode(all_texts, batch_size=vectorize_batch_size)
        
        # numpy array를 list로 변환 (필요한 경우)
        if hasattr(embeddings, 'tolist'):
            embeddings = embeddings.tolist()
        vectorize_elapsed = time.time() - vectorize_start
        print(f"   ✅ 벡터화 완료 (소요 시간: {vectorize_elapsed:.1f}초, 평균: {vectorize_elapsed/len(all_texts)*1000:.1f}ms/청크)")
        
        if len(embeddings) != len(all_texts):
            print(f"⚠️ 임베딩 개수 불일치: {len(embeddings)} != {len(all_texts)}")
            stats["errors"] += len(all_texts) - len(embeddings)
        
        # ChromaDB에 저장 (배치 단위)
        total_save_batches = (len(all_texts) + batch_size - 1) // batch_size
        print(f"   ChromaDB 저장 중... (총 {total_save_batches}개 배치)")
        save_start = time.time()
        for i in range(0, len(all_texts), batch_size):
            batch_num = (i // batch_size) + 1
            batch_texts = all_texts[i:i + batch_size]
            batch_embeddings = embeddings[i:i + batch_size]
            batch_metadatas = all_metadatas[i:i + batch_size]
            batch_ids = all_ids[i:i + batch_size]
            
            try:
                print(f"      저장 진행 중: {batch_num}/{total_save_batches} 배치 ({i+1}~{min(i+len(batch_ids), len(all_texts))}/{len(all_texts)}개 청크)")
                collection.add(
                    embeddings=batch_embeddings,
                    documents=batch_texts,
                    metadatas=batch_metadatas,
                    ids=batch_ids
                )
                stats["saved_chunks"] += len(batch_ids)
            except Exception as e:
                print(f"⚠️ 배치 저장 실패 (인덱스 {i}): {str(e)}")
                stats["errors"] += len(batch_ids)
        
        save_elapsed = time.time() - save_start
        print(f"   ✅ ChromaDB 저장 완료: 총 {stats['saved_chunks']}개 청크 저장 (소요 시간: {save_elapsed:.1f}초)")
        
    except Exception as e:
        print(f"❌ 벡터화 실패: {str(e)}")
        stats["errors"] += len(all_texts)
    
    return stats


# ============================================================================
# 메인 함수
# ============================================================================


def vectorize_news(
    limit: Optional[int] = None,
    skip: int = 0,
    collection_name: Optional[str] = None
) -> Dict[str, int]:
    """
    MongoDB의 뉴스 데이터를 벡터화하여 ChromaDB에 저장
    
    Args:
        limit: 처리할 기사 수 (None이면 모두)
        skip: 건너뛸 기사 수
        collection_name: ChromaDB 컬렉션 이름 (None이면 환경 변수에서 가져옴)
    
    Returns:
        통계 정보
    """
    # collection_name이 None이면 환경 변수에서 가져오기
    if collection_name is None:
        collection_name = CHROMADB_COLLECTION_NAME
    
    print("=" * 70)
    print("🔢 Investing.com 뉴스 벡터화 프로세스 시작")
    print("=" * 70)
    
    # 1. MongoDB 연결
    print(f"\n1️⃣ MongoDB 연결 중: {MONGODB_HOST}:{MONGODB_PORT}/{MONGODB_DB}/{MONGODB_NEWS_COLLECTION}")
    mongo_client = get_mongodb_client()
    mongo_collection = get_mongodb_news_collection(mongo_client)
    
    # 2. MongoDB에서 기사 가져오기
    query = {}  # 모든 기사
    if limit:
        articles = list(mongo_collection.find(query).skip(skip).limit(limit))
    else:
        articles = list(mongo_collection.find(query).skip(skip))
    print(f"   총 {len(articles)}개 기사 발견")
    
    if not articles:
        print("   처리할 기사가 없습니다.")
        mongo_client.close()
        return {
            "total_articles": 0,
            "total_chunks": 0,
            "saved_chunks": 0,
            "errors": 0
        }
    
    # 3. BGE-M3 모델 초기화 (Reddit처럼 FlagModel 직접 사용)
    print(f"\n2️⃣ BGE-M3 모델 초기화 중...")
    try:
        if BGE_M3_MODEL_PATH and os.path.exists(BGE_M3_MODEL_PATH):
            embedder = FlagModel(BGE_M3_MODEL_PATH, use_fp16=True)
            print(f"   로컬 모델 사용: {BGE_M3_MODEL_PATH}")
        else:
            embedder = FlagModel(BGE_M3_MODEL_NAME, use_fp16=True)
            print(f"   Hugging Face 모델 사용: {BGE_M3_MODEL_NAME}")
    except Exception as e:
        print(f"❌ 모델 초기화 실패: {str(e)}")
        mongo_client.close()
        return {
            "total_articles": len(articles),
            "total_chunks": 0,
            "saved_chunks": 0,
            "errors": 0
        }
    
    # 4. ChromaDB 연결
    print(f"\n3️⃣ ChromaDB 연결 중: {CHROMADB_URL}:{CHROMADB_PORT}/{collection_name}")
    chroma_client = make_chroma_client()
    chroma_collection = get_or_create_chromadb_collection(chroma_client, collection_name)
    
    # 5. 벡터화 및 저장
    print(f"\n4️⃣ 벡터화 및 저장 중 ({len(articles)}개 기사)...")
    stats = save_to_chromadb(articles, chroma_collection, embedder)
    
    # 6. 결과 출력
    print("\n" + "=" * 70)
    print("📊 처리 결과")
    print("=" * 70)
    print(f"처리한 기사: {stats['total_articles']}개")
    print(f"생성된 청크: {stats['total_chunks']}개")
    print(f"저장된 청크: {stats['saved_chunks']}개")
    print(f"오류 발생: {stats['errors']}개")
    print("=" * 70)
    
    # 연결 종료
    mongo_client.close()
    
    return stats


def main():
    """메인 실행 함수"""
    # 전체 기사 벡터화
    stats = vectorize_news()
    
    print("\n✅ 벡터화 프로세스 완료!")
    import json
    print(json.dumps(stats, indent=2, ensure_ascii=False))


if __name__ == "__main__":
    main()

