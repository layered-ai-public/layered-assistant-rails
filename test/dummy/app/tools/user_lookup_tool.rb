# A tool that reads host application data. It keeps to the conversation's
# owner, so it is withheld from public assistants by default.
class UserLookupTool < Layered::Assistant::Tool
  description "Look up a registered user by email address."

  argument :email, :string, required: true, description: "The email address to look up."

  def call(email:)
    user = User.find_by(email: email)
    return { found: false, email: email } unless user

    { found: true, email: user.email, name: user.name, signed_up_at: user.created_at.iso8601 }
  end
end
