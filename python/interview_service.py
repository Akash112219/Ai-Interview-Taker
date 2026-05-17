import json
import os
import re
import sys
import warnings

# Suppress the deprecation warning for google-generativeai
warnings.filterwarnings("ignore", category=FutureWarning)

from dotenv import load_dotenv
from openai import OpenAI

class InterviewService:
    def __init__(self, model_provider="openai", model_name="gpt-4"):
        load_dotenv()
        self.provider = model_provider.lower()
        self.model_name = model_name
        
        # OpenAI Setup
        self.openai_client = None
        if self.provider == "openai":
            api_key = os.getenv("OPENAI_API_KEY")
            if api_key:
                self.openai_client = OpenAI(api_key=api_key)
        
        # Gemini Setup
        self.gemini_model = None
        self.genai = None
        if self.provider == "gemini":
            api_key = os.getenv("GEMINI_API_KEY")
            if api_key:
                if sys.version_info >= (3, 14):
                    warnings.warn(
                        "Gemini provider may be incompatible with Python 3.14+. "
                        "Use Python 3.11 or 3.12 for stable google-generativeai support.",
                        UserWarning,
                    )
                try:
                    import google.generativeai as genai
                    genai.configure(api_key=api_key)
                    self.genai = genai
                    self.gemini_model = genai.GenerativeModel(model_name or "gemini-pro")
                except Exception as exc:
                    print(f"Gemini provider init error: {exc}")

    def process_response(self, data):
        data = data if isinstance(data, dict) else {}
        stage = data.get("stage", "name") # Default to name stage
        user_response = data.get("response", "")
        role = data.get("role", "candidate")
        history = data.get("history", [])
        if not isinstance(history, list):
            history = []

        system_prompt = (
            "You are a highly professional, human-like technical interviewer designed to conduct realistic and adaptive interviews.\n"
            "Behavior requirements:\n"
            "- Vary topics and question types deliberately: start with simple definitions or basic concepts, move to comparisons or differences, then practical use-cases, and finally more complex, logic-based or design questions.\n"
            "- Do NOT stay focused on a single topic for too long. After each answer, briefly acknowledge or correct if needed, then smoothly shift to a new or related topic to maintain diversity.\n"
            "- Mix question difficulty dynamically: alternate between easy, medium, and hard levels to keep the session balanced and engaging, like a real interviewer.\n"
            "- If the candidate's answer is unclear or incomplete, ask one short clarification or follow-up question, then proceed.\n"
            "- Keep your tone natural, professional, polite, and conversational - respond as an attentive interviewer who adapts based on the candidate's performance.\n"
            "- Avoid repetition of similar question types or topics in succession.\n"
            "Staged flow (use these stage names): GREET -> name -> intro -> education -> questions -> end.\n"
            "Return format: Return ONLY a valid JSON object and nothing else. Required keys:\n"
            "{\n"
            "  \"question\": <string, the next interviewer prompt to display to the candidate>,\n"
            "  \"next_stage\": <string, next stage name>,\n"
            "  \"success\": true\n"
            "}\n"
            "Optional fields:\n"
            "- \"feedback\": a short, one-sentence comment on the candidate's last answer.\n"
            "- \"followup\": a short clarification or probing question (if needed before the next main question).\n"
            "Important:\n"
            "- During the QUESTIONS stage, alternate topics and difficulty levels (simple, medium, hard, logic-based) instead of staying in one domain.\n"
            "- Adapt your next question using the candidate's prior answers and the role context.\n"
            "- If the user says 'end' or 'stop', set next_stage='end' and return a closing 'question' string that provides a polite and friendly goodbye message.\n"
        )

        hist_items = history[-10:] if history else []
        history_text = "\n".join([f"{item.get('type', '')}: {item.get('text', '')}" for item in hist_items])

        user_msg = (
            f"Role: {role}\nStage: {stage}\nLast user response: {user_response}\nHistory:\n{history_text}\n\n"
            "Based on the stage and history, generate the next interviewer question and indicate the next_stage in JSON as described."
        )

        try:
            if self.provider == "openai" and self.openai_client:
                resp = self.openai_client.chat.completions.create(
                    model=self.model_name,
                    messages=[
                        {"role": "system", "content": system_prompt},
                        {"role": "user", "content": user_msg},
                    ],
                    max_tokens=300,
                    temperature=0.2,
                )
                text = resp.choices[0].message.content.strip()
            elif self.provider == "gemini" and self.gemini_model:
                combined_prompt = f"{system_prompt}\n\nUSER DATA:\n{user_msg}"
                resp = self.gemini_model.generate_content(combined_prompt)
                text = resp.text.strip()
            else:
                return {"success": False, "error": f"Provider {self.provider} not configured"}, 200

            m = re.search(r"\{.*\}", text, re.DOTALL)
            if not m:
                return {"success": False, "error": "Model did not return JSON"}, 200

            result = json.loads(m.group())
            if not isinstance(result, dict) or "question" not in result or "next_stage" not in result:
                return {"success": False, "error": "Model returned invalid JSON"}, 200

            out = {
                "success": True,
                "nextQuestion": result.get("question"),
                "stage": result.get("next_stage"),
            }
            for key, value in result.items():
                if key not in ("question", "next_stage"):
                    out[key] = value
            return out, 200

        except Exception as exc:
            print(f"Model error in process_response: {exc}")
            return {"success": False, "error": "Model not working"}, 200

    def evaluate_interview(self, data):
        data = data if isinstance(data, dict) else {}
        history = data.get("history", [])
        if not isinstance(history, list):
            history = []
        role = data.get("role", "candidate")

        qa_pairs = []
        skip_markers = [
            "(Question skipped",
            "(No response",
            "(Question skipped - no start)",
            "(Question skipped - silence)",
            "(Question skipped - not prepared)",
            "(No response - Timeout)",
        ]

        for i in range(len(history)):
            if history[i].get("type") != "bot":
                continue

            question = history[i].get("text", "")
            if "Too many skipped" in question:
                continue

            answer = ""
            if i + 1 < len(history) and history[i + 1].get("type") == "user":
                answer = history[i + 1].get("text", "")

            if not answer or any(marker in answer for marker in skip_markers):
                continue

            qa_pairs.append({"question": question, "answer": answer})

        transcript = "\n\n".join([f"Q: {qa['question']}\nA: {qa['answer']}" for qa in qa_pairs])

        prompt_prefix = (
            f"You are a strict, fair interviewer evaluator. Evaluate the candidate's performance for role {role} using ONLY the transcript below.\n\n"
            "TRANSCRIPT:\n"
        )

        prompt_example = (
            "You are an evaluation system that scores a technical interview objectively and proportionally to the candidate's overall performance.\n"
            "Return ONLY a single JSON object (no surrounding text). The JSON MUST have these keys and types:\n"
            "- score: integer 0-100 (the total score). This MUST equal the sum of the breakdown fields.\n"
            "- breakdown: object with integer fields: technical, problem_solving, communication, experience, critical_thinking. These numeric fields must sum exactly to 'score'.\n"
            "- maxBreakdown: object with the fixed maxima: technical:35, problem_solving:25, communication:20, experience:15, critical_thinking:5.\n"
            "- strengths: list of 3-6 short strings highlighting what the candidate did well.\n"
            "- weaknesses: list of 3-6 short strings showing areas to improve.\n"
            "- suggestions: list of 3-6 short actionable suggestions for improvement.\n"
            "- overall: short summary string (1-2 sentences) giving a concise evaluation.\n\n"
            "Evaluation rules:\n"
            "- Be realistic and proportional: short or incomplete interviews, vague or minimal answers should result in a low total score (e.g., under 30/100).\n"
            "- Give partial credit only if the answer shows partial understanding.\n"
            "- If the candidate only introduced themselves or answered 1-2 basic questions, technical and problem-solving should be near zero.\n"
            "- Only increase scores significantly if the candidate demonstrates technical reasoning, clear logic, or multiple correct answers.\n"
            "- Communication and experience can receive modest points even from short interviews, but technical and problem-solving must be strict.\n"
            "- Critical thinking (max 5) should be awarded only when logical reasoning or unique insight is shown.\n"
            "- Always ensure all numeric fields are integers and that their sum equals 'score'.\n\n"
            "Example output structure:\n"
            "{\n"
            "  \"score\": 22,\n"
            "  \"breakdown\": {\"technical\": 5, \"problem_solving\": 3, \"communication\": 8, \"experience\": 4, \"critical_thinking\": 2},\n"
            "  \"maxBreakdown\": {\"technical\":35, \"problem_solving\":25, \"communication\":20, \"experience\":15, \"critical_thinking\":5},\n"
            "  \"strengths\": [\"Polite introduction\", \"Basic communication skills\"],\n"
            "  \"weaknesses\": [\"No technical content\", \"Limited explanation depth\"],\n"
            "  \"suggestions\": [\"Provide more detailed technical answers\", \"Demonstrate reasoning and examples\"],\n"
            "  \"overall\": \"The candidate gave a basic introduction but did not demonstrate technical or problem-solving skills.\"\n"
            "}\n"
        )

        prompt = prompt_prefix + transcript + "\n\n" + prompt_example

        try:
            if self.provider == "openai" and self.openai_client:
                resp = self.openai_client.chat.completions.create(
                    model=self.model_name,
                    messages=[
                        {"role": "system", "content": "You are a strict, fair interviewer evaluator."},
                        {"role": "user", "content": prompt},
                    ],
                    max_tokens=800,
                    temperature=0.1,
                )
                text = resp.choices[0].message.content.strip()
            elif self.provider == "gemini" and self.gemini_model:
                resp = self.gemini_model.generate_content(prompt)
                text = resp.text.strip()
            else:
                return {"success": False, "error": f"Provider {self.provider} not configured"}, 200

            m = re.search(r"\{.*\}", text, re.DOTALL)
            if not m:
                return self._fallback_evaluation(
                    qa_pairs,
                    "Model did not return a valid evaluation. Showing interview transcript only.",
                    "did not return JSON",
                ), 200

            evaluation = json.loads(m.group())
            required_keys = ("score", "breakdown", "maxBreakdown", "strengths", "weaknesses", "suggestions", "overall")
            if not all(key in evaluation for key in required_keys):
                return self._fallback_evaluation(
                    qa_pairs,
                    "Model returned incomplete evaluation. Showing interview transcript only.",
                    "incomplete_keys",
                ), 200

            evaluation["success"] = True
            evaluation["qaList"] = qa_pairs
            return evaluation, 200
        except Exception as exc:
            print(f"Model error in evaluate_interview: {exc}")
            return {"success": False, "error": "Model not working"}, 200

    def _fallback_evaluation(self, qa_pairs, overall_text, model_error):
        return {
            "success": True,
            "score": 0,
            "breakdown": {
                "technical": 0,
                "problem_solving": 0,
                "communication": 0,
                "experience": 0,
                "critical_thinking": 0,
            },
            "maxBreakdown": {
                "technical": 35,
                "problem_solving": 25,
                "communication": 20,
                "experience": 15,
                "critical_thinking": 5,
            },
            "strengths": [],
            "weaknesses": [],
            "suggestions": [],
            "overall": overall_text,
            "qaList": qa_pairs,
            "model_error": model_error,
        }
