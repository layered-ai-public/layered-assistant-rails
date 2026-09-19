# A tool that changes something rather than reading it, so each call is put
# to the person talking before it runs. They see the arguments, approve or
# decline, and the response carries on from there.
class RenameUserTool < Layered::Assistant::Tool
  description "Change the name on the signed-in user's account."
  consent :always

  argument :name, :string, required: true, description: "The new name for the account."

  def call(name:)
    # `owner` is this app's boundary, the caller themselves, so the only
    # account this can rename is their own.
    owner.update!(name: name)

    { renamed: true, name: owner.name }
  end
end
