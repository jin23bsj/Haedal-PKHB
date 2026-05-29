"""Gemini API 통합 모듈.

- chat_with_gemini: 사용자의 최근 감정/목표를 컨텍스트로 친구처럼 대화
- analyze_emotional_state: 최근 기록을 분석해 통찰/제안 반환
"""

import json
from typing import Dict, List, Optional

import google.generativeai as genai

from ..config import settings

_configured = False


def _ensure_configured():
    global _configured
    if not _configured and settings.GEMINI_API_KEY:
        genai.configure(api_key=settings.GEMINI_API_KEY)
        _configured = True


CHAT_SYSTEM_PROMPT = """너는 'Dream Achiever' 앱의 따뜻한 친구이자 마음 상담사야.
사용자가 미래 목표를 향해 나아가는 길에서 감정을 함께 나누고 위로가 되는 존재야.

규칙:
1. 항상 따뜻하고 공감하는 말투. 친구처럼 편안하게.
2. 사용자의 최근 감정 기록과 목표를 참고해서 맥락에 맞게 답해.
3. 판단·훈계 금지. 들어주고 함께 느끼는 데 집중.
4. 필요하면 작은 행동 제안 가능. 단, 절대 강요하지 않기.
5. 자해·자살 등 심각한 신호가 보이면 부드럽게 전문가 도움을 권유.
6. 답변은 2~4문장 정도, 길지 않게."""


ANALYSIS_SYSTEM_PROMPT = """너는 따뜻한 심리 분석가야. 사용자의 감정/행동 데이터를 보고
부드럽고 통찰력 있는 분석을 JSON으로만 답해. 마크다운 금지, 코드블록 금지."""


def _build_context(recent_records: List[Dict], active_goals: List[Dict]) -> str:
    if not recent_records and not active_goals:
        return ""

    parts = ["[사용자 컨텍스트]"]

    if active_goals:
        parts.append("진행 중인 목표:")
        for g in active_goals[:5]:
            line = f"- {g['title']}"
            if g.get("category"):
                line += f" (카테고리: {g['category']})"
            parts.append(line)

    if recent_records:
        parts.append("\n최근 감정/행동 기록:")
        for r in recent_records[:7]:
            tags = ", ".join((r.get("emotion_tags") or [])[:3])
            line = f"- {r['record_date']}: 기분 {r['mood_score']}/10"
            if tags:
                line += f" ({tags})"
            parts.append(line)

    return "\n".join(parts)


async def chat_with_gemini(
    user_message: str,
    recent_records: Optional[List[Dict]] = None,
    active_goals: Optional[List[Dict]] = None,
) -> str:
    if not settings.GEMINI_API_KEY:
        return "Gemini API 키가 아직 설정되지 않았어요. 잠시 후에 다시 시도해주세요."

    _ensure_configured()

    model = genai.GenerativeModel(
        model_name="gemini-3.5-flash",
        system_instruction=CHAT_SYSTEM_PROMPT,
    )

    context = _build_context(recent_records or [], active_goals or [])
    prompt = f"{context}\n\n[사용자 메시지]\n{user_message}" if context else user_message

    try:
        response = await model.generate_content_async(prompt)
        return (response.text or "").strip() or "음... 잠시 생각이 잘 안 나네요. 다시 말해줄래요?"
    except Exception as e:
        return f"잠깐 연결이 불안정한 것 같아요. ({type(e).__name__})"


async def analyze_emotional_state(records: List[Dict]) -> Dict:
    """최근 기록을 바탕으로 감정 상태 분석."""
    if not records:
        return {
            "summary": "아직 기록이 부족해요. 며칠만 꾸준히 기록해보면 더 잘 분석해줄 수 있어요!",
            "insights": [],
            "suggestions": [],
        }

    if not settings.GEMINI_API_KEY:
        return {"summary": "Gemini API 키 미설정", "insights": [], "suggestions": []}

    _ensure_configured()

    model = genai.GenerativeModel(
        model_name="gemini-3.5-flash",
        system_instruction=ANALYSIS_SYSTEM_PROMPT,
    )

    records_text = "\n".join(
        f"- {r['record_date']}: 기분 {r['mood_score']}/10, "
        f"감정: {r.get('emotion_tags', [])}, 행동: {r.get('behaviors', [])}, "
        f"메모: {r.get('note') or '없음'}"
        for r in records
    )

    prompt = f"""다음은 사용자의 최근 감정/행동 기록이야:

{records_text}

아래 JSON 형식으로만 답해 (마크다운 금지):
{{
  "summary": "전반적인 감정 상태 요약 2~3문장",
  "insights": ["통찰 1", "통찰 2", "통찰 3"],
  "suggestions": ["부드러운 제안 1", "부드러운 제안 2"]
}}"""

    try:
        response = await model.generate_content_async(prompt)
        text = (response.text or "").strip()
        # 혹시 마크다운 코드블록으로 감싸져 오면 벗기기
        if text.startswith("```"):
            text = text.strip("`")
            if text.startswith("json"):
                text = text[4:]
            text = text.strip()
        return json.loads(text)
    except json.JSONDecodeError:
        return {"summary": text[:500] if text else "분석에 실패했어요", "insights": [], "suggestions": []}
    except Exception as e:
        return {"summary": f"분석 중 오류가 발생했어요 ({type(e).__name__})", "insights": [], "suggestions": []}
