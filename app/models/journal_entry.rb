class JournalEntry < ApplicationRecord
  include PgSearch::Model
  include Taggable
  include Encryptable

  # Relacionamentos
  belongs_to :user
  has_one :sentiment_analysis, dependent: :destroy
  belongs_to :therapy_session, optional: true
  belongs_to :support_group, optional: true

  has_paper_trail
  has_rich_text :content
  has_many_attached :attachments

  # Encriptação de dados sensíveis
  encrypt_column :content_plaintext

  # Callbacks
  after_create :analyze_sentiment
  after_update :reanalyze_sentiment, if: :content_changed?
  after_create_commit :broadcast_creation
  after_update_commit :broadcast_update

  # Enums
  enum mood: { very_bad: 0, bad: 1, neutral: 2, good: 3, very_good: 4 }
  enum visibility: { private: 0, shared_with_therapist: 1, shared_with_group: 2, public: 3 }

  # Validações
  validates :title, presence: true
  validates :content, presence: true
  validates :mood, presence: true

  # Busca de texto completo
  pg_search_scope :search_by_content,
                  against: [:title, :content_plaintext, :tags],
                  using: {
                    tsearch: { prefix: true, dictionary: "portuguese" },
                    trigram: { threshold: 0.3 }
                  }

  # Scopes
  scope :visible_to, ->(user) {
    where(user: user)
      .or(where(visibility: :shared_with_therapist)
            .joins(:therapy_session)
            .where(therapy_sessions: { therapist_id: user.id }))
      .or(where(visibility: :shared_with_group)
            .joins("INNER JOIN support_group_memberships ON support_group_memberships.support_group_id = journal_entries.support_group_id")
            .where(support_group_memberships: { user_id: user.id }))
      .or(where(visibility: :public))
  }

  scope :by_date_range, ->(start_date, end_date) {
    where(created_at: start_date.beginning_of_day..end_date.end_of_day)
  }

  scope :by_mood, ->(mood) { where(mood: mood) }
  scope :by_sentiment, ->(sentiment) { joins(:sentiment_analysis).where(sentiment_analyses: { primary_sentiment: sentiment }) }

  # Métodos
  def content_snippet(length = 100)
    ActionView::Base.full_sanitizer.sanitize(content.to_s).truncate(length)
  end

  def viewable_by?(user)
    return true if user.id == user_id
    return user.therapist? && shared_with_therapist? && therapy_session&.therapist_id == user.id
    return shared_with_group? && user.member_of?(support_group)
    visibility == "public"
  end

  def editable_by?(user)
    user.id == user_id ||
      (user.therapist? && collaborative? && therapy_session&.therapist_id == user.id)
  end

  def generate_summary
    SummarizationService.new(self).summarize
  end

  private

  def analyze_sentiment
    SentimentAnalysisJob.perform_later(id)
  end

  def reanalyze_sentiment
    sentiment_analysis&.destroy
    analyze_sentiment
  end

  def extract_content_plaintext
    self.content_plaintext = ActionView::Base.full_sanitizer.sanitize(content.to_s)
  end

  def broadcast_creation
    JournalChannel.broadcast_to(user, {
      type: 'entry_created',
      entry: JournalEntryComponent.new(journal_entry: self).render_to_string
    })

    broadcast_to_shared_users
  end

  def broadcast_update
    JournalChannel.broadcast_to(user, {
      type: 'entry_updated',
      entry_id: id,
      entry: JournalEntryComponent.new(journal_entry: self).render_to_string
    })

    broadcast_to_shared_users
  end

  def broadcast_to_shared_users
    if shared_with_therapist? && therapy_session&.therapist
      JournalChannel.broadcast_to(therapy_session.therapist, {
        type: 'shared_entry_updated',
        entry_id: id,
        entry: JournalEntryComponent.new(journal_entry: self, current_user: therapy_session.therapist).render_to_string
      })
    end

    if shared_with_group? && support_group
      support_group.members.where.not(id: user_id).each do |member|
        JournalChannel.broadcast_to(member, {
          type: 'group_entry_updated',
          entry_id: id,
          group_id: support_group.id,
          entry: JournalEntryComponent.new(journal_entry: self, current_user: member).render_to_string
        })
      end
    end
  end
end
