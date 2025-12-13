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

    # Clear prompt with explicit requirements
    prompt = f"""Verilen soruyu analiz edip JSON formatinda kategorize et.

DERS: {course_name}

MEVCUT KONULAR:
{topics_list if topics_list else "(henuz yok - yeni olustur)"}

MEVCUT ALT KONULAR:
{subtopics_list if subtopics_list else "(henuz yok - yeni olustur)"}

BILGI TURLERI (birini sec):
{knowledge_types_list}

ANALIZ EDILECEK SORU:
{question_text}

ONEMLI: Asagidaki JSON formatinda cevap ver. TUM alanlari MUTLAKA doldur, hicbirini null birakma (sadece id null olabilir).

SORU TIPI ORNEKLERI:

1. COKTAN SECMELI (multiple_choice):
{{"topic":{{"id":5,"name":"hucre_biyolojisi","displayName":"Hücre Biyolojisi"}},"subtopic":{{"id":null,"name":"madde_tasimasi","displayName":"Madde Taşıması"}},"knowledgeTypeId":1,"questionType":"multiple_choice","questionText":"Hangisi dogrudur?","correctAnswer":"Dogru sikin tam icerigi","options":["Sik A icerigi","Sik B icerigi","Sik C icerigi","Sik D icerigi"],"explanation":"Aciklama"}}

2. DOGRU/YANLIS (true_false):
{{"topic":{{"id":null,"name":"genetik","displayName":"Genetik"}},"subtopic":{{"id":null,"name":"dna_yapisi","displayName":"DNA Yapısı"}},"knowledgeTypeId":1,"questionType":"true_false","questionText":"DNA cift sarmallidir.","correctAnswer":"true","options":null,"explanation":"DNA Watson-Crick modeline gore cift sarmal yapidir"}}

3. BOSLUK DOLDURMA (fill_in_blank):
{{"topic":{{"id":null,"name":"fizik","displayName":"Fizik"}},"subtopic":{{"id":null,"name":"hareket","displayName":"Hareket"}},"knowledgeTypeId":1,"questionType":"fill_in_blank","questionText":"Isik hizi ___ km/s dir.","correctAnswer":"300000","options":null,"explanation":"Isik hizi yaklasik 300.000 km/s"}}

KURALLAR:
1. topic.id ve subtopic.id: Mevcut listede varsa ID yaz, yoksa null (ama name ve displayName MUTLAKA doldur!)
2. name: snake_case formatinda (ornek: madde_tasimasi, hucre_bolunmesi)
3. displayName: Turkce gorunen ad (ornek: Madde Taşıması, Hücre Bölünmesi)
4. questionText: SADECE soru cumlesi (siklar olmadan, bosluk doldurma icin ___ kullan)
5. correctAnswer: Coktan secmelide sikin ICERIGI, dogru/yanlista "true"/"false", bosluk doldurmada cevap metni
6. options: Coktan secmelide 4 sik icerigi (harfsiz), diger tiplerde null

JSON cevap:"""

    try:
        async with httpx.AsyncClient(timeout=60.0) as client:
            response = await client.post(
                f"{GEMINI_API_URL}?key={GEMINI_API_KEY}",
                json={
                    "contents": [{"parts": [{"text": prompt}]}],
                    "generationConfig": {
                        "temperature": 0.1,
                        "maxOutputTokens": 4096
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
                    "name": topic_data.get("name") or "unknown",
                    "displayName": topic_data.get("displayName") or "Bilinmeyen Konu",
                    "isNew": topic_is_new
                },
                "subtopic": {
                    "id": subtopic_id,
                    "name": subtopic_data.get("name") or "unknown",
                    "displayName": subtopic_data.get("displayName") or "Bilinmeyen Alt Konu",
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