# A tool that answers from the calling context rather than from arguments.
# `user` is the person doing the talking; `owner` is the record the
# conversation is scoped to, which is the same user here but would be their
# organisation under an owner block.
class WhoamiTool < Layered::Assistant::Tool
  description "Get the name and email address of the person you are talking to."

  def call
    return { signed_in: false } unless user

    { signed_in: true, name: user.name, email: user.email }
  end
end
