"""
OpenAI Vision analysis via the Responses API.
OPENAI_API_KEY and OPENAI_VISION_MODEL must be set in server environment only.
"""

from __future__ import annotations

import base64
import json
import logging
import os
import re
from typing import Any

import httpx

log = logging.getLogger("openai-vision")

OPENAI_RESPONSES_URL = "https://api.openai.com/v1/responses"
DEFAULT_VISION_MODEL = "gpt-4.1-mini"

VALID_IMAGE_TYPES = frozenset(
    {"ecg", "mri", "ct", "blood_test", "xray", "skin", "document", "other"}
)
VALID_RISK_LEVELS = frozenset({"low", "medium", "high", "unknown"})

DEFAULT_DISCLAIMER = (
    "AI analysis is preliminary and does not replace a physician."
)

_SYSTEM_PROMPTS = {
    "ar": (
        "أنت مساعد طبي لتحليل الصور الطبية المرئية فقط. "
        "هذا تفسير بصري أولي وليس تشخيصاً نهائياً. "
        "لا تقدّم تشخيصاً قطعياً. "
        "انصح دائماً بمراجعة الطبيب للتخطيط القلبي ECG، الرنين MRI، الأشعة المقطعية CT، "
        "الأشعة السينية X-ray، أي نتائج مشبوهة، أو الأعراض الشديدة. "
        "إذا كانت الصورة غير واضحة (لقطة شاشة، ضبابية، مقطوعة)، اذكر قيود جودة الصورة. "
        "إذا لم تكن الصورة طبية، اضبط image_type=other وrisk_level=unknown وdoctor_needed=false. "
        "أجب فقط باللغة العربية في جميع حقول JSON النصية."
    ),
    "ru": (
        "Ты медицинский ассистент для предварительного визуального анализа медицинских изображений. "
        "Это предварительная интерпретация, а не окончательный диагноз. "
        "Не ставь окончательный диагноз. "
        "Всегда рекомендуй обратиться к врачу для ЭКГ, МРТ, КТ, рентгена, "
        "подозрительных находок или тяжёлых симптомов. "
        "Если изображение нечёткое (скриншот, размытое, обрезанное), укажи ограничения качества. "
        "Если изображение не медицинское, установи image_type=other, risk_level=unknown, doctor_needed=false. "
        "Отвечай только на русском языке во всех текстовых полях JSON."
    ),
}

_USER_PROMPTS = {
    "ar": (
        "حلّل هذه الصورة الطبية. "
        "أعد JSON فقط بالمفاتيح: summary, image_type, possible_findings, risk_level, "
        "recommendation, doctor_needed, disclaimer. "
        "image_type واحد من: ecg, mri, ct, blood_test, xray, skin, document, other. "
        "risk_level واحد من: low, medium, high, unknown. "
        "possible_findings مصفوفة نصوص. doctor_needed منطقي."
    ),
    "ru": (
        "Проанализируй это медицинское изображение. "
        "Верни только JSON с ключами: summary, image_type, possible_findings, risk_level, "
        "recommendation, doctor_needed, disclaimer. "
        "image_type один из: ecg, mri, ct, blood_test, xray, skin, document, other. "
        "risk_level один из: low, medium, high, unknown. "
        "possible_findings массив строк. doctor_needed логический."
    ),
}


def vision_model_name() -> str:
    return os.environ.get("OPENAI_VISION_MODEL", DEFAULT_VISION_MODEL).strip() or DEFAULT_VISION_MODEL


def openai_api_key() -> str:
    key = os.environ.get("OPENAI_API_KEY", "").strip()
    if not key:
        raise RuntimeError("OPENAI_API_KEY is not set")
    return key


def _extract_json_object(text: str) -> dict[str, Any]:
    text = text.strip()
    if text.startswith("```"):
        text = re.sub(r"^```(?:json)?\s*", "", text)
        text = re.sub(r"\s*```$", "", text)
    start = text.find("{")
    if start == -1:
        raise ValueError("No JSON object in model output")
    depth = 0
    end = None
    for i, ch in enumerate(text[start:], start=start):
        if ch == "{":
            depth += 1
        elif ch == "}":
            depth -= 1
            if depth == 0:
                end = i
                break
    if end is None:
        raise ValueError("Unbalanced JSON in model output")
    return json.loads(text[start : end + 1])


def _normalize_response(raw: dict[str, Any], language: str) -> dict[str, Any]:
    image_type = str(raw.get("image_type", "other")).lower().strip()
    if image_type not in VALID_IMAGE_TYPES:
        image_type = "other"

    risk_level = str(raw.get("risk_level", "unknown")).lower().strip()
    if risk_level not in VALID_RISK_LEVELS:
        risk_level = "unknown"

    findings_raw = raw.get("possible_findings") or []
    if not isinstance(findings_raw, list):
        findings_raw = [str(findings_raw)]
    possible_findings = [str(f).strip() for f in findings_raw if str(f).strip()]

    doctor_needed = raw.get("doctor_needed")
    if not isinstance(doctor_needed, bool):
        doctor_needed = risk_level in {"medium", "high"} or image_type in {
            "ecg", "mri", "ct", "xray"
        }

    disclaimer = str(raw.get("disclaimer") or "").strip()
    if not disclaimer:
        disclaimer = (
            "هذا تحليل أولي لأغراض توعوية فقط ولا يُعد تشخيصاً طبياً."
            if language == "ar"
            else "Это предварительный информационный анализ, а не медицинский диагноз."
        )

    return {
        "summary": str(raw.get("summary") or "").strip(),
        "image_type": image_type,
        "possible_findings": possible_findings,
        "risk_level": risk_level,
        "recommendation": str(raw.get("recommendation") or "").strip(),
        "doctor_needed": doctor_needed,
        "disclaimer": disclaimer,
    }


def _parse_responses_api_payload(data: dict[str, Any]) -> str:
    """Extract assistant text from OpenAI Responses API body."""
    output = data.get("output")
    if isinstance(output, list):
        chunks: list[str] = []
        for item in output:
            if not isinstance(item, dict):
                continue
            content = item.get("content")
            if isinstance(content, list):
                for part in content:
                    if isinstance(part, dict):
                        if part.get("type") in ("output_text", "text") and part.get("text"):
                            chunks.append(str(part["text"]))
            elif isinstance(content, str):
                chunks.append(content)
        if chunks:
            return "\n".join(chunks)

    # Fallback shapes
    for key in ("output_text", "text"):
        if isinstance(data.get(key), str):
            return data[key]

    choices = data.get("choices")
    if isinstance(choices, list) and choices:
        msg = choices[0].get("message", {}) if isinstance(choices[0], dict) else {}
        if isinstance(msg, dict) and msg.get("content"):
            return str(msg["content"])

    raise ValueError("Could not extract text from OpenAI response")


async def analyze_medical_image(
    image_bytes: bytes,
    *,
    language: str = "ar",
    content_type: str = "image/jpeg",
) -> dict[str, Any]:
    """
    Send image to OpenAI Responses API and return normalized structured JSON.
    """
    lang = language if language in ("ar", "ru") else "ar"
    mime = content_type if content_type.startswith("image/") else "image/jpeg"
    b64 = base64.b64encode(image_bytes).decode("ascii")
    data_url = f"data:{mime};base64,{b64}"

    model = vision_model_name()
    payload = {
        "model": model,
        "input": [
            {
                "role": "system",
                "content": [{"type": "input_text", "text": _SYSTEM_PROMPTS[lang]}],
            },
            {
                "role": "user",
                "content": [
                    {"type": "input_text", "text": _USER_PROMPTS[lang]},
                    {"type": "input_image", "image_url": data_url},
                ],
            },
        ],
        "text": {"format": {"type": "json_object"}},
    }

    log.info(
        "OpenAI vision request: model=%s language=%s bytes=%d",
        model, lang, len(image_bytes),
    )

    async with httpx.AsyncClient(timeout=90.0) as client:
        resp = await client.post(
            OPENAI_RESPONSES_URL,
            headers={
                "Authorization": f"Bearer {openai_api_key()}",
                "Content-Type": "application/json",
            },
            json=payload,
        )

    if resp.status_code != 200:
        body = resp.text[:500]
        log.error("OpenAI vision error: status=%d body=%s", resp.status_code, body)
        raise RuntimeError(f"OpenAI API error ({resp.status_code})")

    data = resp.json()
    reply_text = _parse_responses_api_payload(data)
    raw = _extract_json_object(reply_text)
    return _normalize_response(raw, lang)
