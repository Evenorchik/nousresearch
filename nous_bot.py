import time
import requests
import logging

# Nous API configuration
NOUS_API_URL = "https://inference-api.nousresearch.com/v1/chat/completions"
NOUS_API_KEY = "$API_KEY"  # Replace with your API key
MODEL = "Hermes-3-Llama-3.1-70B"  # Change to the desired model if needed
MAX_TOKENS = 60
TEMPERATURE = 0.8
TOP_P = 0.9
DELAY_BETWEEN_QUESTIONS = 30  # Delay between questions in seconds

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def get_response(question: str) -> str:
    """Send a prompt to the Nous API and return the response text."""
    headers = {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {NOUS_API_KEY}"
    }
    data = {
        "messages": [{"role": "user", "content": question}],
        "model": MODEL,
        "max_tokens": MAX_TOKENS,
        "temperature": TEMPERATURE,
        "top_p": TOP_P
    }
    response = requests.post(NOUS_API_URL, headers=headers, json=data, timeout=30)
    response.raise_for_status()
    json_response = response.json()
    # Assuming the response follows the same structure as the OpenAI API:
    return json_response.get("choices", [{}])[0].get("message", {}).get("content", "No answer")

def main():
    # Read questions from the "questions.txt" file
    try:
        with open("questions.txt", "r", encoding="utf-8") as f:
            questions = [line.strip() for line in f if line.strip()]
    except Exception as e:
        logger.error(f"Error reading questions.txt: {e}")
        return

    if not questions:
        logger.error("No questions found in questions.txt.")
        return

    index = 0
    while True:
        question = questions[index]
        logger.info(f"Question #{index + 1}: {question}")
        try:
            answer = get_response(question)
            logger.info(f"Answer: {answer}")
        except Exception as e:
            logger.error(f"Error getting a response for question: {question}\n{e}")
        index = (index + 1) % len(questions)
        time.sleep(DELAY_BETWEEN_QUESTIONS)

if __name__ == "__main__":
    main()
