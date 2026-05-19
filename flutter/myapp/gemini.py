import google.generativeai as genai

# 🔹 Google Gemini API Key
GOOGLE_API_KEY = 'AIzaSyAjHvlCxWWDKsVR_5ZevlNYGR1gxpR9UPY'

# 🔹 Configure the API
genai.configure(api_key=GOOGLE_API_KEY)

# 🔹 Initialize model
model =  genai.GenerativeModel("gemini-2.5-flash")


def generate_gemini_response(prompt: str) -> str:
    """
    Generates a response from the Gemini model as a language-learning chatbot.
    """
    context = (
        "You are an emergency safety assistant for women. "
        "Always reply politely, clearly and in short sentences. "
        "If the user seems in danger, provide calm and practical safety steps. "
        "Avoid long explanations. Never give harmful advice.\n\n"
        f"User: {prompt}"
    )

    try:
        response = model.generate_content(context)
        return response.text.strip()
    except Exception as e:
        return f"Sorry, I couldn't generate a response. (Error: {str(e)})"


# 🧪 Test block (optional)
if __name__ == "__main__":   # ✅ FIXED
    user_message = "Can you help me improve my English speaking?"
    print(generate_gemini_response(user_message))
