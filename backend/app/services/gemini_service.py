"""
Gemini AI Service for intelligent question analysis
"""
import os
import json
import re
import httpx
from typing import Optional, List, Dict, Any

# Gemini API configuration
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY", "")
GEMINI_API_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent"


def extract_json_from_text(text: str) -> Optional[Dict]:
    """
    Try to extract JSON from text, handling various formats and incomplete JSON.
    """
    text = text.strip()

    # Remove markdown code blocks
    if text.startswith("```json"):
        text = text[7:]
    if text.startswith("```"):
        text = text[3:]
    if text.endswith("```"):
        text = text[:-3]
    text = text.strip()

    # Try direct parse first
    try:
        return json.loads(text)
    except json.JSONDecodeError:
        pass

    # Try to find JSON object in text
    json_match = re.search(r'\{.*', text, re.DOTALL)
    if json_match:
        json_str = json_match.group()

        # Try parsing as-is
        try:
            return json.loads(json_str)
        except json.JSONDecodeError:
            pass

        # Try to fix incomplete JSON by counting braces
        open_braces = json_str.count('{')
        close_braces = json_str.count('}')

        if open_braces > close_braces:
            # Add missing closing braces
            json_str = json_str.rstrip()
            # Remove trailing incomplete parts (after last complete value)
            # Find last complete key-value
            last_quote = json_str.rfind('"')
            if last_quote > 0:
                # Check if we're in middle of a string
                before_quote = json_str[:last_quote]
                if before_quote.rstrip().endswith(':'):
                    # We have "key": "incomplete... - remove this incomplete part
                    # Find the start of this key
                    key_match = re.search(r',?\s*"[^"]+"\s*:\s*"[^"]*$', json_str)
                    if key_match:
                        json_str = json_str[:key_match.start()]

            # Add missing braces
            json_str = json_str.rstrip().rstrip(',')
            json_str += '}' * (open_braces - close_braces)

            try:
                return json.loads(json_str)
            except json.JSONDecodeError:
                pass

    return None


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
    # Include description for better knowledge type selection
    knowledge_types_list = "\n".join([f"- ID:{k['id']} | {k['name']} | {k['displayName']} | {k.get('description', '')}" for k in existing_knowledge_types])

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
5. SADECE soru metnini çıkar (şıklar, cevap harfi olmadan, soru işaretiyle biten kısım)
6. Şıkları ayrı ayrı çıkar (A, B, C, D harfleri olmadan sadece içerik)
7. Doğru cevabın İÇERİĞİNİ belirle (harf değil, cevabın kendisi)
8. Kısa bir açıklama yaz

ÖRNEK:
Girdi: "Türkiye'nin başkenti neresidir? A) İstanbul B) Ankara C) İzmir D) Bursa Cevap: B"
Çıktı:
- questionText: "Türkiye'nin başkenti neresidir?"
- options: ["İstanbul", "Ankara", "İzmir", "Bursa"]
- correctAnswer: "Ankara"

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
    "questionText": "<SADECE soru metni, şıklar ve cevap harfi olmadan>",
    "correctAnswer": "<doğru cevabın içeriği, harf değil>",
    "options": ["şık1 içeriği", "şık2 içeriği", "şık3 içeriği", "şık4 içeriği"] veya null,
    "explanation": "<kısa açıklama>"
}}

JSON formatinda yanit ver. Sadece JSON, baska bir sey yazma."""

    try:
        async with httpx.AsyncClient(timeout=60.0) as client:
            response = await client.post(
                f"{GEMINI_API_URL}?key={GEMINI_API_KEY}",
                json={
                    "contents": [{"parts": [{"text": prompt}]}],
                    "generationConfig": {
                        "temperature": 0.1,
                        "maxOutputTokens": 2048
                        # NOT using responseMimeType - it can cause truncation
                    }
                },
                headers={"Content-Type": "application/json"}
            )

            if response.status_code != 200:
                return {"success": False, "error": f"Gemini API error: {response.status_code} - {response.text}"}

            result = response.json()

            # Extract the generated text
            generated_text = result.get("candidates", [{}])[0].get("content", {}).get("parts", [{}])[0].get("text", "")

            if not generated_text:
                return {"success": False, "error": f"Empty response from Gemini. Full response: {json.dumps(result)[:500]}"}

            # Use smart JSON extraction that handles incomplete responses
            analysis = extract_json_from_text(generated_text)

            if not analysis:
                return {"success": False, "error": f"Could not parse JSON from response. Raw: {generated_text[:500]}"}

            # Debug log
            print(f"🔍 Gemini raw response: {generated_text[:500]}")
            print(f"🔍 Parsed analysis keys: {list(analysis.keys())}")

            # Safely extract topic info
            topic_data = analysis.get("topic", {})
            if not isinstance(topic_data, dict):
                topic_data = {}

            subtopic_data = analysis.get("subtopic", {})
            if not isinstance(subtopic_data, dict):
                subtopic_data = {}

            # Determine if topic/subtopic are new
            topic_id = topic_data.get("id")
            subtopic_id = subtopic_data.get("id")
            topic_is_new = topic_id is None
            subtopic_is_new = subtopic_id is None

            # Find knowledge type info
            kt_id = analysis.get("knowledgeTypeId", 9)  # Default to "general"
            kt_info = next((k for k in existing_knowledge_types if k["id"] == kt_id), existing_knowledge_types[0] if existing_knowledge_types else {"id": 9, "name": "general", "displayName": "Genel"})

            return {
                "success": True,
                "topic": {
                    "id": topic_id,
                    "name": topic_data.get("name", "unknown"),
                    "displayName": topic_data.get("displayName", "Bilinmeyen Konu"),
                    "isNew": topic_is_new
                },
                "subtopic": {
                    "id": subtopic_id,
                    "name": subtopic_data.get("name", "unknown"),
                    "displayName": subtopic_data.get("displayName", "Bilinmeyen Alt Konu"),
                    "isNew": subtopic_is_new
                },
                "knowledgeType": {
                    "id": kt_info["id"],
                    "name": kt_info["name"],
                    "displayName": kt_info["displayName"]
                },
                "questionType": analysis.get("questionType", "multiple_choice"),
                "questionText": analysis.get("questionText", ""),
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