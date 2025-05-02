class User < ApplicationRecord
  include PgSearch::Model
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable, :lockable, :timeoutable, :trackable,
         :omniauthable, omniauth_providers: [:google_oauth2]

  # Relacionamentos
  has_many :habits, dependent: :destroy
  has_many :habit_entries, through: :habits
  has_many :journal_entries, dependent: :destroy
  has_many :sentiment_analyses, through: :journal_entries
  has_many :support_group_memberships, dependent: :destroy
  has_many :support_groups, through: :support_group_memberships
  has_many :therapy_sessions_as_client, class_name: 'TherapySession', foreign_key: 'client_id', dependent: :destroy
  has_many :therapy_sessions_as_therapist, class_name: 'TherapySession', foreign_key: 'therapist_id', dependent: :nullify

  has_noticed_notifications
  has_one_attached :avatar
  has_many :web_push_subscriptions, dependent: :destroy

  # Enums
  enum role: { user: 0, therapist: 1, admin: 2 }
  enum theme: { light: 0, dark: 1, system: 2 }, _default: :system

  # Validações
  validates :email, presence: true, uniqueness: true
  validates :first_name, :last_name, presence: true
  validates :timezone, presence: true

  # Configuração de preferências
  store_accessor :preferences, :email_reminders, :push_notifications,
                 :daily_summary, :journal_reminders,
                 :sharing_preferences, :language

  # Métodos
  def full_name
    "#{first_name} #{last_name}"
  end

  def active_habits
    habits.where(archived: false)
  end

  def journal_streak
    # Calcula sequência de dias com entradas de diário
    current_streak = 0
    max_streak = 0

    dates = journal_entries.order(created_at: :desc)
                           .pluck('DISTINCT DATE(created_at)')
                           .map(&:to_date)

    return 0 if dates.empty?

    current_date = Date.today
    dates.each do |date|
      if date == current_date || date == current_date - 1.day
        current_streak += 1
        current_date = date
      else
        max_streak = [max_streak, current_streak].max
        current_streak = 1
        current_date = date
      end
    end

    [max_streak, current_streak].max
  end

  def member_of?(group)
    support_group_memberships.where(support_group: group).exists?
  end

  def insights_for_period(start_date, end_date)
    InsightGeneratorService.new(self, start_date, end_date).generate
  end
end