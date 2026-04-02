# Do not seed in test environment
return if Rails.env.test?

credentials = Rails.application.credentials

# Providers
anthropic_key = credentials.dig(:providers, :anthropic_api_key) || ENV["ANTHROPIC_API_KEY"]
if anthropic_key.present?
  anthropic = Layered::Assistant::Provider.find_or_create_by!(
    protocol: :anthropic,
    name: "Anthropic"
  ) do |provider|
    provider.secret = anthropic_key
  end

  Layered::Assistant::Models::CreateService.new(anthropic).call
end

openai_key = credentials.dig(:providers, :openai_api_key) || ENV["OPENAI_API_KEY"]
if openai_key.present?
  openai = Layered::Assistant::Provider.find_or_create_by!(
    protocol: :openai,
    name: "OpenAI"
  ) do |provider|
    provider.secret = openai_key
  end

  Layered::Assistant::Models::CreateService.new(openai).call
end

gemini_key = credentials.dig(:providers, :gemini_api_key) || ENV["GEMINI_API_KEY"]
if gemini_key.present?
  gemini = Layered::Assistant::Provider.find_or_create_by!(
    protocol: :openai,
    name: "Gemini"
  ) do |provider|
    provider.url = "https://generativelanguage.googleapis.com/v1beta/openai/"
    provider.secret = gemini_key
  end

  Layered::Assistant::Models::CreateService.new(gemini).call
end

ollama_url = credentials.dig(:providers, :ollama_api_url) || ENV["OLLAMA_API_URL"]
if ollama_url.present?
  Layered::Assistant::Provider.find_or_create_by!(
    protocol: :openai,
    name: "Ollama"
  ) do |provider|
    provider.url = ollama_url
    provider.secret = credentials.dig(:providers, :ollama_api_key) || ENV["OLLAMA_API_KEY"] || "not-required"
  end
end

lm_studio_url = credentials.dig(:providers, :lm_studio_api_url) || ENV["LM_STUDIO_API_URL"]
if lm_studio_url.present?
  Layered::Assistant::Provider.find_or_create_by!(
    protocol: :openai,
    name: "LM Studio"
  ) do |provider|
    provider.url = lm_studio_url
    provider.secret = credentials.dig(:providers, :lm_studio_api_key) || ENV["LM_STUDIO_API_KEY"] || "not-required"
  end
end

openrouter_key = credentials.dig(:providers, :openrouter_api_key) || ENV["OPENROUTER_API_KEY"]
if openrouter_key.present?
  openrouter = Layered::Assistant::Provider.find_or_create_by!(
    protocol: :openai,
    name: "OpenRouter"
  ) do |provider|
    provider.url = "https://openrouter.ai/api/v1/"
    provider.secret = openrouter_key
  end

  Layered::Assistant::Models::CreateService.new(openrouter).call
end

groq_key = credentials.dig(:providers, :groq_api_key) || ENV["GROQ_API_KEY"]
if groq_key.present?
  groq = Layered::Assistant::Provider.find_or_create_by!(
    protocol: :openai,
    name: "Groq"
  ) do |provider|
    provider.url = "https://api.groq.com/openai/v1"
    provider.secret = groq_key
  end

  Layered::Assistant::Models::CreateService.new(groq).call
end

mistral_key = credentials.dig(:providers, :mistral_api_key) || ENV["MISTRAL_API_KEY"]
if mistral_key.present?
  mistral = Layered::Assistant::Provider.find_or_create_by!(
    protocol: :openai,
    name: "Mistral"
  ) do |provider|
    provider.url = "https://api.mistral.ai/v1"
    provider.secret = mistral_key
  end

  Layered::Assistant::Models::CreateService.new(mistral).call
end

# Assistants
#
# Create a public assistant for each seeded model so every model is
# immediately usable in the dummy app.
assistant_models = {
  claude_haiku_4_6:               "Claude Haiku 4.6",
  claude_sonnet_4_6:              "Claude Sonnet 4.6",
  claude_opus_4_6:                "Claude 4.6",
  gpt_5_4_fast:                   "OpenAI GPT 5.4 (Fast)",
  gpt_5_4:                        "OpenAI GPT 5.4",
  gemini_2_5_flash_lite:          "Google Gemini 2.5 (Flash Lite)",
  gemini_2_5_flash:               "Google Gemini 2.5 (Flash)",
  gemini_2_5_pro:                 "Google Gemini 2.5 (Pro)",
  gemini_3_1_pro_preview:         "Google Gemini 3.1 (Pro)",
  x_ai_grok_4_fast:               "X.ai Grok 4 (Fast)",
  x_ai_grok_4:                    "X.ai Grok 4",
  meta_llama_llama_4_scout_17b_16e_instruct:      "Meta Llama 4 Scout",
  meta_llama_llama_4_maverick_17b_128e_instruct:  "Meta Llama 4 Maverick",
  qwen_qwen3_32b:                 "Alibaba Qwen 3 32B",
  moonshotai_kimi_k2_instruct_0905: "Moonshot Kimi K2.5",
  mistral_small_2506:             "Mistral Small 2506",
  mistral_medium_2508:            "Mistral Medium 2508",
  mistral_large_2512:             "Mistral Large 2512",
  groq_compound:                  "Groq Compound"
}

assistant_models.each do |identifier, name|
  model = Layered::Assistant::Model.find_by(identifier: identifier)
  next unless model

  assistant = Layered::Assistant::Assistant.find_or_create_by!(name: name) do |a|
    a.description = "Assistant powered by #{name}."
    a.system_prompt = "You are a helpful assistant. Answer questions clearly and concisely."
    a.default_model = model
    a.public = true
  end
  assistant.update!(public: true, default_model: model)
end

# User
user = User.find_or_create_by!(email: "test.user@example.com") do |u|
  u.name = "Test User"
  u.password = "notasecret123"
  u.password_confirmation = "notasecret123"
end
