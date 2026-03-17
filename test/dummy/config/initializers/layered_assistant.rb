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

# Configure record scoping for layered-assistant-rails.
# By default, all records are visible to any authorised user. Use the scope
# block to restrict which records are returned from the engine's controllers.
#
# The block receives the model class and runs in controller context, so you
# have access to current_user and other helpers. Return an ActiveRecord
# relation (e.g. model_class.where(...) or model_class.all).
#
# Models passed through the scope block:
#   - Layered::Assistant::Conversation (has polymorphic owner)
#   - Layered::Assistant::Assistant    (has polymorphic owner)
#   - Layered::Assistant::Provider     (has polymorphic owner)
#
# Scope all owned resources to the current user:
#
# Layered::Assistant.scope do |model_class|
#   model_class.where(owner: current_user)
# end
#
# Scope conversations only, leave others unscoped:
#
# Layered::Assistant.scope do |model_class|
#   if model_class == Layered::Assistant::Conversation
#     model_class.where(owner: current_user)
#   else
#     model_class.all
#   end
# end

# Optional settings (uncomment to enable):
Layered::Assistant.log_errors = true         # log API errors to stdout
# Layered::Assistant.skip_db_encryption = true # skip encryption on Provider#secret (dev/test only)
