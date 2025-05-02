class Habit < ApplicationRecord
  # Relacionamentos
  belongs_to :user
  has_many :habit_entries, dependent: :destroy

  has_paper_trail

  # Enums
  enum frequency: { daily: 0, weekdays: 1, weekends: 2, weekly: 3, monthly: 4, custom: 5 }
  enum category: { exercise: 0, meditation: 1, sleep: 2, nutrition: 3, social: 4, learning: 5, mindfulness: 6, other: 7 }
  enum reminder_type: { none: 0, push: 1, email: 2, both: 3 }

  # Validações
  validates :name, presence: true
  validates :frequency, presence: true
  validates :reminder_time, presence: true, if: -> { reminder_type != 'none' }

  # Serialized columns
  serialize :custom_days, Array
  serialize :custom_dates, Array

  # Callbacks
  after_create :schedule_reminders
  after_update :reschedule_reminders, if: -> { saved_change_to_reminder_time? || saved_change_to_reminder_type? }

  # Scopes
  scope :active, -> { where(archived: false) }
  scope :archived, -> { where(archived: true) }
  scope :due_today, -> { active.select { |habit| habit.due_today? } }
  scope :by_category, ->(category) { where(category: category) }