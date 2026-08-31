# Configure authorization for layered-assistant-rails.
# All non-public engine routes return 403 Forbidden until this block is configured.
# Uncomment one of the examples below, or write your own.
#
# The block runs in controller context, so you have access to request,
# current_user, redirect_to, head, main_app, and all other controller methods.
#
# Once configured, visit /layered/assistant (or your mount path) to get started.

# Allow all requests (no authorization):
#
# Layered::Assistant.authorize do
#   # No-op: all requests permitted
# end

# Require sign-in (Devise):
#
# Layered::Assistant.authorize do
#   redirect_to main_app.new_user_session_path unless user_signed_in?
# end

# Restrict to admins:
#
# Layered::Assistant.authorize do
#   head :forbidden unless current_user&.admin?
# end

# Record scoping
#
# Engine records are scoped to the signed-in user via a polymorphic `owner`
# association on Assistant, Conversation, Provider, Persona and Skill. New
# records are stamped with the controller's `current_owner` (defaulting to
# `l_ui_current_user`), and reads are filtered through
# `Model.owned_by(current_owner)`. Records owned by another owner (or unowned)
# return 404. When `current_owner` is nil (no signed-in user), reads return no
# records and create actions raise Layered::Assistant::MissingOwnerError rather
# than persisting an invisible unowned record - your authorize block above
# should still ensure engine routes are only reachable by authenticated users.
#
# To scope records to something other than the signed-in user (e.g. their
# organisation), configure an owner block. Like the authorize block, it runs
# in controller context; it must return the record ownership is stamped with
# on create and filtered by on reads.
#
# Layered::Assistant.owner do
#   current_user&.organisation
# end
#
# The block must return a record for every request your authorize block admits,
# not just for signed-in users. The example above returns nil for a user who has
# not created an organisation yet, and that user will hit MissingOwnerError on
# their first create. Either give the block a fallback, or have your authorize
# block send those users somewhere to set one up first.

# Tools
#
# An assistant can call into your application before it answers. Define tools
# as classes in app/tools and list them here. The block is called per request
# rather than read once at boot, so tool classes reload in development.
#
# class WeatherTool < Layered::Assistant::Tool
#   description "Get the current weather for a city."
#
#   argument :city, :string, required: true, description: "The city to look up."
#
#   def call(city:)
#     { city: city, temperature_c: Weather.for(city).temperature }
#   end
# end
#
# Layered::Assistant.tools do
#   [ WeatherTool ]
# end
#
# Inside #call, `message`, `conversation` and `owner` give the calling context.
# Scope a tool's reads and writes to `owner` to keep it inside the caller's
# boundary. A conversation with a public assistant has no owner, so tools are
# withheld from those conversations unless the tool declares
# `requires_owner false`.

# Optional settings (uncomment to enable):
# Layered::Assistant.log_errors = true              # log API errors to stdout
# Layered::Assistant.api_request_timeout = 210      # total API timeout in seconds, including full streaming response (default: 210)
# Layered::Assistant.skip_db_encryption = true      # skip encryption on Provider#secret (dev/test only)
# Layered::Assistant.max_tool_cycles = 10           # rounds of tool calls one prompt may trigger (default: 10)
