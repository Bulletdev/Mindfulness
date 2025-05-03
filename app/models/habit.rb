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
  validates :custom_days, presence: true, if: -> { frequency == 'custom' && custom_dates.blank? }
  validates :custom_dates, presence: true, if: -> { frequency == 'custom' && custom_days.blank? }
  validates :goal_value, numericality: { greater_than: 0 }, allow_nil: true
  validate :validate_custom_frequency_options

  # Serialized columns
  serialize :custom_days, Array
  serialize :custom_dates, Array

  # Callbacks
  after_create :schedule_reminders
  after_update :reschedule_reminders, if: -> { saved_change_to_reminder_time? || saved_change_to_reminder_type? }
  before_save :set_default_start_date, if: -> { start_date.nil? }

  # Scopes
  scope :active, -> { where(archived: false) }
  scope :archived, -> { where(archived: true) }
  scope :due_today, -> { active.select { |habit| habit.due_today? } }
  scope :by_category, ->(category) { where(category: category) }
  scope :with_streak, ->(min_streak) { active.where('current_streak >= ?', min_streak) }
  scope :recently_created, -> { order(created_at: :desc) }
  scope :most_completed, -> { active.order(total_completions: :desc) }

  # Métodos de instância
  def due_today?
    return false if archived?

    case frequency
    when 'daily'
      true
    when 'weekdays'
      !Date.today.saturday? && !Date.today.sunday?
    when 'weekends'
      Date.today.saturday? || Date.today.sunday?
    when 'weekly'
      Date.today.wday == start_date.wday
    when 'monthly'
      Date.today.day == start_date.day
    when 'custom'
      if custom_days.present?
        custom_days.include?(Date.today.wday)
      elsif custom_dates.present?
        custom_dates.include?(Date.today.day)
      else
        false
      end
    else
      false
    end
  end

  def complete_for_today!(value = 1)
    return false unless due_today?

    transaction do
      entry = habit_entries.find_or_initialize_by(date: Date.today)

      if entry.new_record?
        entry.value = value
        entry.save!

        # Update streak
        self.current_streak += 1
        self.longest_streak = [longest_streak, current_streak].max
        self.total_completions += 1
        self.last_completed_at = Time.current
        save!

        true
      else
        # Already completed today
        false
      end
    end
  end

  def incomplete_for_today!
    entry = habit_entries.find_by(date: Date.today)

    if entry
      transaction do
        entry.destroy!

        # Reset streak if it was completed today
        self.current_streak -= 1
        self.total_completions -= 1

        # Find the last completion date
        last_entry = habit_entries.order(date: :desc).first
        self.last_completed_at = last_entry ? last_entry.created_at : nil

        save!
      end
      true
    else
      false
    end
  end

  def reset_streak!
    self.current_streak = 0
    save!
  end

  def completed_today?
    habit_entries.exists?(date: Date.today)
  end

  def missed_days_in_current_month
    return 0 unless start_date

    start_of_month = Date.today.beginning_of_month
    end_date = Date.today.prev_day

    (start_of_month..end_date).count do |date|
      should_be_completed = false

      case frequency
      when 'daily'
        should_be_completed = true
      when 'weekdays'
        should_be_completed = !date.saturday? && !date.sunday?
      when 'weekends'
        should_be_completed = date.saturday? || date.sunday?
      when 'weekly'
        should_be_completed = date.wday == start_date.wday
      when 'monthly'
        should_be_completed = date.day == start_date.day
      when 'custom'
        if custom_days.present?
          should_be_completed = custom_days.include?(date.wday)
        elsif custom_dates.present?
          should_be_completed = custom_dates.include?(date.day)
        end
      end

      should_be_completed && !habit_entries.exists?(date: date)
    end
  end

  def completion_rate(start_date = nil, end_date = nil)
    start_date ||= self.start_date || created_at.to_date
    end_date ||= Date.today

    total_due_days = 0
    completed_days = 0

    (start_date..end_date).each do |date|
      # Check if the habit was due on this date based on frequency
      is_due = case frequency
               when 'daily'
                 true
               when 'weekdays'
                 !date.saturday? && !date.sunday?
               when 'weekends'
                 date.saturday? || date.sunday?
               when 'weekly'
                 date.wday == self.start_date.wday
               when 'monthly'
                 date.day == self.start_date.day
               when 'custom'
                 if custom_days.present?
                   custom_days.include?(date.wday)
                 elsif custom_dates.present?
                   custom_dates.include?(date.day)
                 else
                   false
                 end
               end

      if is_due
        total_due_days += 1
        completed_days += 1 if habit_entries.exists?(date: date)
      end
    end

    total_due_days.zero? ? 0 : (completed_days.to_f / total_due_days * 100).round(2)
  end

  def archive!
    update!(archived: true)
  end

  def unarchive!
    update!(archived: false)
  end

  def frequency_text
    case frequency
    when 'daily'
      'Diariamente'
    when 'weekdays'
      'Dias úteis (Seg-Sex)'
    when 'weekends'
      'Finais de semana (Sáb-Dom)'
    when 'weekly'
      "Semanalmente (#{I18n.l(start_date, format: '%A')})" if start_date
    when 'monthly'
      "Mensalmente (Dia #{start_date.day})" if start_date
    when 'custom'
      if custom_days.present?
        days = custom_days.map { |day| I18n.t('date.day_names')[day] }.join(', ')
        "Personalizado (#{days})"
      elsif custom_dates.present?
        "Personalizado (Dias #{custom_dates.join(', ')})"
      else
        'Personalizado'
      end
    end
  end

  private

  def validate_custom_frequency_options
    if frequency == 'custom'
      if custom_days.blank? && custom_dates.blank?
        errors.add(:base, 'Para frequência personalizada, forneça dias da semana ou dias do mês')
      end

      if custom_days.present?
        custom_days.each do |day|
          errors.add(:custom_days, 'contém valor inválido') unless (0..6).include?(day.to_i)
        end
      end

      if custom_dates.present?
        custom_dates.each do |date|
          errors.add(:custom_dates, 'contém valor inválido') unless (1..31).include?(date.to_i)
        end
      end
    end
  end

  def set_default_start_date
    self.start_date = Date.today
  end

  def schedule_reminders
    return if reminder_type == 'none' || reminder_time.blank?

    # Implementation depends on your reminder system
    # Example with Sidekiq:
    # ReminderWorker.perform_at(next_reminder_time, id)
  end

  def reschedule_reminders
    # Cancel existing reminders and reschedule
    # Implementation depends on your reminder system
  end

  def next_reminder_time
    # Calculate next reminder time based on frequency and reminder_time
    # This is a placeholder implementation
    today = Date.today
    reminder_datetime = Time.zone.parse("#{today} #{reminder_time.strftime('%H:%M')}")

    if reminder_datetime < Time.zone.now
      # If the time has already passed today, schedule for tomorrow
      reminder_datetime += 1.day
    end

    reminder_datetime
  end
end