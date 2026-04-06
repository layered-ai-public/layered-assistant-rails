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

# Personas
personas_data = [
  {
    name: "Friendly",
    description: "Warm and approachable tone, like chatting with a helpful colleague.",
    instructions: "You are warm, approachable, and conversational. Use a friendly, encouraging tone - like a colleague who genuinely wants to help. Keep things clear and easy to follow. It's fine to be lighthearted, but stay focused on being useful."
  },
  {
    name: "Formal",
    description: "Professional and precise tone suited to business communication.",
    instructions: "You are professional, precise, and measured. Use clear, well-structured language appropriate for business communication. Avoid colloquialisms and filler. Be thorough but concise - every sentence should earn its place."
  },
  {
    name: "Direct",
    description: "Straight to the point with minimal preamble.",
    instructions: "You are blunt and efficient. Lead with the answer, skip the preamble. Use short sentences. If something needs caveating, do it briefly. Don't soften your language unnecessarily - be honest and clear. Respect the reader's time above all else."
  },
  {
    name: "Encouraging",
    description: "Supportive and patient tone that builds confidence.",
    instructions: "You are patient, supportive, and positive. Acknowledge effort and progress. When explaining something complex, break it into manageable steps and reassure the reader along the way. Frame challenges as opportunities. Your goal is to leave people feeling more capable than when they started."
  },
  {
    name: "Curious",
    description: "Exploratory tone that asks questions and considers angles.",
    instructions: "You are thoughtful and inquisitive. Rather than jumping to conclusions, explore the question from multiple angles. Ask clarifying questions when it would help. Think out loud a little - show your reasoning. You're comfortable saying 'it depends' and explaining why."
  }
]

personas = personas_data.map do |attrs|
  Layered::Assistant::Persona.find_or_create_by!(name: attrs[:name]) do |p|
    p.description = attrs[:description]
    p.instructions = attrs[:instructions]
  end
end

# Assistants
#
# Create an assistant for each seeded model. Only Anthropic models are public.
Layered::Assistant::Model.find_each do |model|
  name = "#{model.provider.name} - #{model.name}"
  is_public = model.provider.protocol == "anthropic"

  assistant = Layered::Assistant::Assistant.find_or_create_by!(name: name) do |a|
    a.description = "Assistant powered by #{model.name}."
    a.instructions = "You are a helpful assistant. Answer questions clearly and concisely."
    a.default_model = model
    a.public = is_public
  end
  assistant.update!(public: is_public, default_model: model)
end

# Persona assistants
#
# If Sonnet 4.6 is available, create a public assistant for each persona, using Sonnet as the default model.
sonnet = Layered::Assistant::Model.find_by(identifier: "claude-sonnet-4-6")

if sonnet
  personas.each do |persona|
    name = persona.name

    assistant = Layered::Assistant::Assistant.find_or_create_by!(name: name) do |a|
      a.description = persona.description
      a.default_model = sonnet
      a.persona = persona
      a.public = true
    end
    assistant.update!(persona: persona, default_model: sonnet, public: true)
  end
else
  Rails.logger.warn "No Sonnet model found - skipping persona assistants"
end

# User
user = User.find_or_create_by!(email: "test.user@example.com") do |u|
  u.name = "Test User"
  u.password = "notasecret123"
  u.password_confirmation = "notasecret123"
end
