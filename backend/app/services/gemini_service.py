"""
Gemini AI Service for intelligent question analysis
"""
import os
import json
import httpx
from typing import Optional, List, Dict, Any

# Gemini API configuration
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY", "")
GEMINI_API_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent"


async def analyze_question(
    question_text: str,
    course_name: str,
    existing_topics: List[Dict[str, Any]],
    existing_subtopics: List[Dict[str, Any]],
    existing_knowledge_types: List[Dict[str, Any]],
) -> Dict[str, Any]:
    """
    Analyze a question using Gemini AI and suggest categorization.

    Returns:
        {
            "success": True/False,
            "topic": {"id": int or None, "name": str, "displayName": str, "isNew": bool},
            "subtopic": {"id": int or None, "name": str, "displayName": str, "isNew": bool},
            "knowledgeType": {"id": int, "name": str, "displayName": str},
            "questionType": "multiple_choice" | "true_false" | "fill_in_blank",
            "correctAnswer": str,
            "options": [...] or None,
            "explanation": str or None,
            "error": str or None
        }
    """
    if not GEMINI_API_KEY:
        return {"success": False, "error": "Gemini API key not configured"}

    # Build context for the AI
    topics_list = "\n".join([f"- ID:{t['id']} | {t['name']} | {t['displayName']}" for t in existing_topics])
    subtopics_list = "\n".join([f"- ID:{s['id']} | TopicID:{s['topicId']} | {s['name']} | {s['displayName']}" for s in existing_subtopics])
    knowledge_types_list = "\n".join([f"- ID:{k['id']} | {k['name']} | {k['displayName']}" for k in existing_knowledge_types])

    prompt = f"""Sen bir eğitim içeriği sınıflandırma asistanısın. Verilen soruyu analiz et ve kategorize et.

DERS: {course_name}

MEVCUT KONULAR:
{topics_list if topics_list else "(Henüz konu yok)"}

MEVCUT ALT KONULAR:
{subtopics_list if subtopics_list else "(Henüz alt konu yok)"}

MEVCUT BİLGİ TÜRLERİ:
{knowledge_types_list}

SORU:
{question_text}

GÖREV:
1. Bu soruyu analiz et
2. Uygun konu, alt konu ve bilgi türünü belirle
3. Eğer mevcut kategoriler uygun değilse, yeni konu/alt konu öner
4. Soru tipini belirle (multiple_choice, true_false, fill_in_blank)
5. Doğru cevabı belirle
6. Varsa şıkları çıkar
7. Kısa bir açıklama yaz

YANIT FORMAT (JSON):
{{
    "topic": {{
        "id": <mevcut ise ID, yoksa null>,
        "name": "<sistem_adi_snake_case>",
        "displayName": "<Görünen Ad>"
    }},
    "subtopic": {{
        "id": <mevcut ise ID, yoksa null>,
        "name": "<sistem_adi_snake_case>",
        "displayName": "<Görünen Ad>"
    }},
    "knowledgeTypeId": <bilgi türü ID - mutlaka mevcut listeden seç>,
    "questionType": "<multiple_choice|true_false|fill_in_blank>",
    "correctAnswer": "<doğru cevap>",
    "options": ["A şıkkı", "B şıkkı", "C şıkkı", "D şıkkı"] veya null,
    "explanation": "<kısa açıklama>"
}}

SADECE JSON DÖNDÜR, başka bir şey yazma."""

    try:
        async with httpx.AsyncClient(timeout=30.0) as client:
            response = await client.post(
                f"{GEMINI_API_URL}?key={GEMINI_API_KEY}",
                json={
                    "contents": [{"parts": [{"text": prompt}]}],
                    "generationConfig": {
                        "temperature": 0.2,
                        "topK": 40,
                        "topP": 0.95,
                        "maxOutputTokens": 1024,
                    }
                },
                headers={"Content-Type": "application/json"}
            )

            if response.status_code != 200:
                return {"success": False, "error": f"Gemini API error: {response.status_code} - {response.text}"}

            result = response.json()

            # Extract the generated text
            generated_text = result.get("candidates", [{}])[0].get("content", {}).get("parts", [{}])[0].get("text", "")

            # Clean and parse JSON
            generated_text = generated_text.strip()
            if generated_text.startswith("```json"):
                generated_text = generated_text[7:]
            if generated_text.startswith("```"):
                generated_text = generated_text[3:]
            if generated_text.endswith("```"):
                generated_text = generated_text[:-3]
            generated_text = generated_text.strip()

            analysis = json.loads(generated_text)

            # Determine if topic/subtopic are new
            topic_is_new = analysis["topic"]["id"] is None
            subtopic_is_new = analysis["subtopic"]["id"] is None

            # Find knowledge type info
            kt_id = analysis.get("knowledgeTypeId", 9)  # Default to "general"
            kt_info = next((k for k in existing_knowledge_types if k["id"] == kt_id), existing_knowledge_types[0] if existing_knowledge_types else {"id": 9, "name": "general", "displayName": "Genel"})

            return {
                "success": True,
                "topic": {
                    "id": analysis["topic"]["id"],
                    "name": analysis["topic"]["name"],
                    "displayName": analysis["topic"]["displayName"],
                    "isNew": topic_is_new
                },
                "subtopic": {
                    "id": analysis["subtopic"]["id"],
                    "name": analysis["subtopic"]["name"],
                    "displayName": analysis["subtopic"]["displayName"],
                    "isNew": subtopic_is_new
                },
                "knowledgeType": {
                    "id": kt_info["id"],
                    "name": kt_info["name"],
                    "displayName": kt_info["displayName"]
                },
                "questionType": analysis.get("questionType", "multiple_choice"),
                "correctAnswer": analysis.get("correctAnswer", ""),
                "options": analysis.get("options"),
                "explanation": analysis.get("explanation")
            }

    except json.JSONDecodeError as e:
        return {"success": False, "error": f"JSON parse error: {str(e)}"}
    except httpx.TimeoutException:
        return {"success": False, "error": "Gemini API timeout"}
    except Exception as e:
        return {"success": False, "error": f"Unexpected error: {str(e)}"}