class User < ApplicationRecord
  devise :database_authenticatable,
    :validatable,
    :recoverable,
    :lockable,
    :rememberable,
    :timeoutable,
    :trackable
end
