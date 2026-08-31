# A tool that reads host application data. Registering a tool does not scope
# it - that is this class's job. Ownership in this app is the signed-in user,
# so the only record inside the caller's boundary is their own; under an owner
# block scoping to an organisation this would read `owner.users.find_by(...)`.
class UserLookupTool < Layered::Assistant::Tool
  description "Look up a registered user by email address."

  argument :email, :string, required: true, description: "The email address to look up."

  def call(email:)
    # `owner` is a record, not an id, so the boundary is spelled out: this
    # app's owner is the caller themselves, which means the only user a
    # lookup may return is their own. A nil owner narrows to nothing.
    match = User.where(id: owner&.id).find_by(email: email)
    return { found: false, email: email } unless match

    { found: true, email: match.email, name: match.name, signed_up_at: match.created_at.iso8601 }
  end
end
