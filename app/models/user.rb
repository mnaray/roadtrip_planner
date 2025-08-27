class User < ApplicationRecord
  has_secure_password

  validates :username, presence: true,
                      length: { minimum: 3 },
                      uniqueness: { case_sensitive: false }

  validates :password, presence: true,
                      length: { minimum: 8 },
                      format: { with: /\A(?=.*[a-zA-Z])(?=.*\d)/,
                               message: "must contain both letters and numbers" }

  before_save :downcase_username

  private

  def downcase_username
    self.username = username.downcase if username.present?
  end
end
