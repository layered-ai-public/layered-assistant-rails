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

# Skills
skills_data = [
  {
    name: "Company context",
    description: "Internal knowledge about Acme Corp - products, teams, and processes.",
    instructions: "You work for Acme Corp, a B2B SaaS company founded in 2019 and based in Bristol, UK. The product is a project management platform called Acme Flow. Key facts:\n\n- Pricing tiers: Starter (free, up to 5 users), Team (£12/user/month), Enterprise (custom).\n- The engineering team uses two-week sprints. Deployments happen on Tuesdays and Thursdays.\n- Support SLA: Starter - 48h, Team - 24h, Enterprise - 4h.\n- The Q3 roadmap focuses on API v2, SSO for Team tier, and a mobile app beta.\n\nRefer to these facts naturally when relevant. Do not fabricate details beyond what is provided here."
  },
  {
    name: "House style",
    description: "Writing guidelines for consistent, on-brand communication.",
    instructions: "Follow these writing guidelines:\n\n- Use British English spelling (e.g. organisation, colour, licence as a noun).\n- Prefer active voice. Keep sentences under 25 words where possible.\n- Avoid jargon unless the audience is technical. Define acronyms on first use.\n- Headings: capitalise first word only (sentence case).\n- Lists: use bullet points for unordered items, numbered lists only for sequential steps.\n- Never use 'please do not hesitate to contact us' or similar clichés.\n- Oxford comma: yes.\n- Dates: 6 April 2026 (no ordinal suffix, no comma)."
  },
  {
    name: "Product catalogue",
    description: "Current product and pricing details for Acme Flow.",
    instructions: "Acme Flow product catalogue (current as of April 2026):\n\n**Starter** - Free\n- Up to 5 users, 3 projects, 1 GB storage\n- Kanban boards, basic reporting\n\n**Team** - £12/user/month (billed annually) or £15/user/month (monthly)\n- Unlimited users and projects, 50 GB storage\n- Gantt charts, time tracking, custom fields, integrations (Slack, GitHub, Jira)\n- Priority email support\n\n**Enterprise** - Custom pricing\n- Everything in Team, plus: SSO/SAML, audit logs, dedicated account manager\n- 99.9% uptime SLA, on-premise deployment option\n- Custom integrations and onboarding\n\n**Add-ons:**\n- Extra storage: £3/50 GB/month\n- AI assistant (beta): £5/user/month\n\nWhen discussing pricing or features, use only the details above. Do not guess at features not listed."
  },
  {
    name: "Compliance guidance",
    description: "Data handling and regulatory requirements for customer-facing responses.",
    instructions: "When responding to questions involving data, privacy, or compliance:\n\n- Acme Corp is registered with the ICO (registration ZA987654).\n- Data is stored in AWS eu-west-2 (London). No customer data leaves the UK unless the customer opts into the US region.\n- Acme Flow is SOC 2 Type II certified and Cyber Essentials Plus accredited.\n- GDPR: Acme Corp acts as a data processor. A DPA is available on request for Team and Enterprise tiers.\n- Data retention: deleted accounts are purged after 90 days. Backups are retained for 30 days.\n- Subprocessors: AWS, Stripe, SendGrid, Sentry. The full list is published at acmeflow.example.com/subprocessors.\n\nDo not provide legal advice. For specific compliance questions, direct users to compliance@acmeflow.example.com."
  }
]

skills = skills_data.each_with_object({}) do |attrs, hash|
  hash[attrs[:name]] = Layered::Assistant::Skill.find_or_create_by!(name: attrs[:name]) do |s|
    s.description = attrs[:description]
    s.instructions = attrs[:instructions]
  end
end

# Skilled assistants
#
# If Sonnet 4.6 is available, create assistants that demonstrate skill usage.
if sonnet
  skilled_assistants = [
    {
      name: "Sales assistant",
      description: "Handles pre-sales queries using product and pricing knowledge.",
      instructions: "You help prospective customers understand Acme Flow. Answer questions about features, pricing, and how the product compares to alternatives. Be honest about limitations. If a question falls outside your knowledge, suggest booking a demo.",
      skills: [ "Product catalogue", "House style" ],
      public: true
    },
    {
      name: "Compliance assistant",
      description: "Answers data protection and security questions for prospects and customers.",
      instructions: "You help answer compliance, security, and data protection questions about Acme Flow. Be precise and factual. Never speculate beyond the information you have been given.",
      skills: [ "Compliance guidance", "Company context" ],
      public: true
    },
    {
      name: "Customer support",
      description: "All-round support assistant with full company context.",
      instructions: "You are a front-line support assistant for Acme Flow. Help customers with account queries, feature questions, and general troubleshooting. Escalate billing disputes and technical bugs to the appropriate team.",
      skills: [ "Company context", "Product catalogue", "Compliance guidance", "House style" ],
      public: true
    }
  ]

  skilled_assistants.each do |attrs|
    assistant = Layered::Assistant::Assistant.find_or_create_by!(name: attrs[:name]) do |a|
      a.description = attrs[:description]
      a.instructions = attrs[:instructions]
      a.default_model = sonnet
      a.public = attrs[:public]
    end
    assistant.update!(default_model: sonnet, public: attrs[:public])
    assistant.skills = attrs[:skills].map { |name| skills[name] }
  end
else
  Rails.logger.warn "No Sonnet model found - skipping skilled assistants"
end

# User
user = User.find_or_create_by!(email: "test.user@example.com") do |u|
  u.name = "Test User"
  u.password = "notasecret123"
  u.password_confirmation = "notasecret123"
end
