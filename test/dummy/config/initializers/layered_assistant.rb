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

Layered::Assistant.authorize do
  redirect_to main_app.new_user_session_path unless user_signed_in?
end

# Restrict to admins:
#
# Layered::Assistant.authorize do
#   head :forbidden unless current_user&.admin?
# end
