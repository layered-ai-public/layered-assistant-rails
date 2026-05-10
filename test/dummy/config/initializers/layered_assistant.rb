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
Layered::Assistant.authorize do
  redirect_to main_app.new_user_session_path unless user_signed_in?
end

# Restrict to admins:
#
# Layered::Assistant.authorize do
#   head :forbidden unless current_user&.admin?
# end

# Record scoping
#
# Engine records are scoped to the signed-in user via a polymorphic `owner`
# association on Assistant, Conversation, Provider, Persona and Skill. New
# records are stamped with `owner = l_ui_current_user`, and reads are filtered
# through `Model.owned_by(l_ui_current_user)`. Records owned by another user
# (or unowned) return 404.

# Optional settings (uncomment to enable):
Layered::Assistant.log_errors = true                # log API errors to stdout
Layered::Assistant.api_request_timeout = 210        # total API timeout in seconds, including full streaming response (default: 210)
# Layered::Assistant.skip_db_encryption = true      # skip encryption on Provider#secret (dev/test only)
