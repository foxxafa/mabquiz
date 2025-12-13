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
    if not json_match:
        return None

    json_str = json_match.group()

    # Try parsing as-is
    try:
        return json.loads(json_str)
    except json.JSONDecodeError:
        pass

    # Aggressive fix for truncated JSON
    # Step 1: Find and remove any incomplete string at the end
    # Pattern: we're looking for unclosed strings

    # Remove everything after the last complete value
    # Find last occurrence of: "value" or number or true/false/null followed by comma or brace

    # First, try to find the last complete key-value pair
    # Look for patterns like: "key": "value", or "key": number, or "key": null,

    fixed = json_str

    # Check if we have an unclosed string at the end
    # Count quotes - if odd, we have an unclosed string
    quote_count = fixed.count('"')
    if quote_count % 2 == 1:
        # Find the last quote and remove from there
        last_quote = fixed.rfind('"')
        # Go back to find the start of this incomplete key or value
        # Look for the comma or brace before this
        search_area = fixed[:last_quote]

        # Find last complete structure (ends with ", or }, or ])
        last_complete = -1
        for pattern in ['},', '},\n', '",', '",\n', '],', '],\n', 'null,', 'true,', 'false,']:
            idx = search_area.rfind(pattern)
            if idx > last_complete:
                last_complete = idx + len(pattern) - 1  # Keep the comma

        if last_complete > 0:
            fixed = fixed[:last_complete]

    # Remove trailing comma if any
    fixed = fixed.rstrip().rstrip(',').rstrip()

    # Count braces and add missing ones
    open_braces = fixed.count('{')
    close_braces = fixed.count('}')
    open_brackets = fixed.count('[')
    close_brackets = fixed.count(']')

    # Add missing brackets first, then braces
    fixed += ']' * (open_brackets - close_brackets)
    fixed += '}' * (open_braces - close_braces)

    try:
        return json.loads(fixed)
    except json.JSONDecodeError:
        pass

    # Last resort: try to extract just the critical fields with regex
    result = {}

    # Extract topic
    topic_match = re.search(r'"topic"\s*:\s*\{[^}]*"id"\s*:\s*(\d+|null)[^}]*"name"\s*:\s*"([^"]*)"[^}]*"displayName"\s*:\s*"([^"]*)"', json_str)
    if topic_match:
        result["topic"] = {
            "id": int(topic_match.group(1)) if topic_match.group(1) != "null" else None,
            "name": topic_match.group(2),
            "displayName": topic_match.group(3)
        }

    # Extract subtopic - might be incomplete
    subtopic_match = re.search(r'"subtopic"\s*:\s*\{[^}]*"id"\s*:\s*(\d+|null)', json_str)
    subtopic_name = re.search(r'"subtopic"\s*:\s*\{[^}]*"name"\s*:\s*"([^"]*)"', json_str)
    subtopic_display = re.search(r'"subtopic"\s*:\s*\{[^}]*"displayName"\s*:\s*"([^"]*)"', json_str)

    if subtopic_match:
        result["subtopic"] = {
            "id": int(subtopic_match.group(1)) if subtopic_match.group(1) != "null" else None,
            "name": subtopic_name.group(1) if subtopic_name else "unknown",
            "displayName": subtopic_display.group(1) if subtopic_display else "Bilinmeyen"
        }

    # Extract other fields
    kt_match = re.search(r'"knowledgeTypeId"\s*:\s*(\d+)', json_str)
    if kt_match:
        result["knowledgeTypeId"] = int(kt_match.group(1))

    qt_match = re.search(r'"questionType"\s*:\s*"([^"]*)"', json_str)
    if qt_match:
        result["questionType"] = qt_match.group(1)

    qtext_match = re.search(r'"questionText"\s*:\s*"([^"]*)"', json_str)
    if qtext_match:
        result["questionText"] = qtext_match.group(1)

    answer_match = re.search(r'"correctAnswer"\s*:\s*"([^"]*)"', json_str)
    if answer_match:
        result["correctAnswer"] = answer_match.group(1)

    # Extract options array
    options_match = re.search(r'"options"\s*:\s*\[(.*?)\]', json_str, re.DOTALL)
    if options_match:
        options_str = options_match.group(1)
        options = re.findall(r'"([^"]*)"', options_str)
        result["options"] = options

    explanation_match = re.search(r'"explanation"\s*:\s*"([^"]*)"', json_str)
    if explanation_match:
        result["explanation"] = explanation_match.group(1)

    # If we extracted at least topic, return the result
    if "topic" in result:
        return result

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
                return {
                    "success": False,
                    "error": "AI yanıtı işlenemedi. Lütfen tekrar deneyin.",
                    "rawResponse": generated_text[:800]  # Frontend'de F12 ile görebilirsin
                }

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