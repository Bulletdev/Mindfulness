class InsightGeneratorService
  attr_reader :user, :start_date, :end_date

  def initialize(user, start_date, end_date)
    @user = user
    @start_date = start_date.to_date
    @end_date = end_date.to_date
  end

  def generate
    {
      habit_insights: generate_habit_insights,
      mood_trends: generate_mood_trends,
      sentiment_analysis: generate_sentiment_analysis,
      correlations: generate_correlations,
      recommendations: generate_recommendations
    }
  end

  private

  def generate_habit_insights
    habits = user.habits.includes(:habit_entries)

    habit_insights = habits.map do |habit|
      entries_in_period = habit.habit_entries.where(
        created_at: start_date.beginning_of_day..end_date.end_of_day
      )

      completion_percentage = calculate_completion_percentage(habit, entries_in_period)
      streak = calculate_streak(habit)

      {
        id: habit.id,
        name: habit.name,
        category: habit.category,
        completion_percentage: completion_percentage,
        current_streak: streak,
        total_completions: entries_in_period.where(completed: true).count,
        missed_days: entries_in_period.where(completed: false).count
      }
    end

    {
      habits: habit_insights,
      most_consistent: habit_insights.max_by { |h| h[:completion_percentage] }&.slice(:id, :name, :completion_percentage),
      longest_streak: habit_insights.max_by { |h| h[:current_streak] }&.slice(:id, :name, :current_streak)
    }
  end

  def generate_mood_trends
    entries = user.journal_entries.where(
      created_at: start_date.beginning_of_day..end_date.end_of_day
    )

    # Agregar dados por dia
    daily_moods = entries.group_by_day(:created_at).average(:mood)

    # Calcular média geral de humor
    average_mood = entries.average(:mood)

    # Encontrar dias com melhor e pior humor
    best_day = entries.group_by_day(:created_at).average(:mood)
                      .max_by { |_day, mood| mood }&.first
    worst_day = entries.group_by_day(:created_at).average(:mood)
                       .min_by { |_day, mood| mood }&.first

    # Valores específicos para melhor e pior dia
    best_day_entries = best_day ? entries.where(created_at: best_day.all_day) : []
    worst_day_entries = worst_day ? entries.where(created_at: worst_day.all_day) : []

    {
      daily_moods: daily_moods,
      average_mood: average_mood,
      best_day: {
        date: best_day,
        mood_average: best_day ? daily_moods[best_day] : nil,
        entries: best_day_entries.map { |e| { id: e.id, title: e.title, mood: e.mood } }
      },
      worst_day: {
        date: worst_day,
        mood_average: worst_day ? daily_moods[worst_day] : nil,
        entries: worst_day_entries.map { |e| { id: e.id, title: e.title, mood: e.mood } }
      }
    }
  end

  def generate_sentiment_analysis
    analyses = user.sentiment_analyses.joins(:journal_entry)
                   .where(journal_entries: {
                     created_at: start_date.beginning_of_day..end_date.end_of_day
                   })

    return {} if analyses.empty?

    # Contar ocorrências de cada sentimento primário
    sentiment_counts = analyses.group(:primary_sentiment).count

    # Calcular médias de escores emocionais
    avg_positive = analyses.average(:positive_score) || 0
    avg_negative = analyses.average(:negative_score) || 0
    avg_neutral = analyses.average(:neutral_score) || 0
    avg_mixed = analyses.average(:mixed_score) || 0

    # Encontrar entradas com maior positividade/negatividade
    most_positive = analyses.order(positive_score: :desc).first
    most_negative = analyses.order(negative_score: :desc).first

    # Identificar tópicos comuns
    common_topics = extract_common_topics(analyses)

    {
      sentiment_distribution: sentiment_counts,
      average_scores: {
        positive: avg_positive,
        negative: avg_negative,
        neutral: avg_neutral,
        mixed: avg_mixed
      },
      most_positive_entry: most_positive ? {
        id: most_positive.journal_entry_id,
        title: most_positive.journal_entry&.title,
        date: most_positive.created_at,
        score: most_positive.positive_score
      } : nil,
      most_negative_entry: most_negative ? {
        id: most_negative.journal_entry_id,
        title: most_negative.journal_entry&.title,
        date: most_negative.created_at,
        score: most_negative.negative_score
      } : nil,
      common_topics: common_topics
    }
  end

  def generate_correlations
    # Extrair dados para correlação
    mood_data = user.journal_entries
                    .where(created_at: start_date.beginning_of_day..end_date.end_of_day)
                    .group_by_day(:created_at).average(:mood)

    habits_data = {}
    user.habits.each do |habit|
      habits_data[habit.id] = habit.habit_entries
                                   .where(created_at: start_date.beginning_of_day..end_date.end_of_day)
                                   .group_by_day(:created_at)
                                   .average('CASE WHEN completed THEN 1 ELSE 0 END')
    end

    # Calcular correlações entre hábitos e humor
    correlations = {}
    habits_data.each do |habit_id, habit_completion|
      habit = user.habits.find(habit_id)
      correlation = calculate_correlation(mood_data, habit_completion)

      correlations[habit_id] = {
        habit_name: habit.name,
        correlation: correlation,
        strength: correlation_strength(correlation),
        description: correlation_description(habit.name, correlation)
      }
    end

    # Ordenar por força de correlação (absoluta)
    sorted_correlations = correlations.values.sort_by { |c| -c[:correlation].abs }

    {
      habit_mood_correlations: sorted_correlations,
      strongest_positive: sorted_correlations.find { |c| c[:correlation] > 0 },
      strongest_negative: sorted_correlations.find { |c| c[:correlation] < 0 }
    }
  end

  def generate_recommendations
    habit_insights = generate_habit_insights
    mood_trends = generate_mood_trends
    correlations = generate_correlations

    recommendations = []

    # Recomendação baseada em hábitos menos consistentes
    least_consistent = habit_insights[:habits].min_by { |h| h[:completion_percentage] }
    if least_consistent && least_consistent[:completion_percentage] < 50
      recommendations << {
        type: 'habit_improvement',
        title: "Melhore sua consistência em #{least_consistent[:name]}",
        description: "Você completou este hábito apenas #{least_consistent[:completion_percentage]}% das vezes. " +
          "Tente definir um horário específico do dia para este hábito ou vincule-o a outra atividade diária."
      }
    end

    # Recomendação baseada em correlações positivas
    if correlations[:strongest_positive]
      habit = correlations[:strongest_positive]
      recommendations << {
        type: 'positive_correlation',
        title: "Continue com #{habit[:habit_name]}",
        description: "Notamos uma forte correlação positiva entre #{habit[:habit_name]} e seu humor. " +
          "#{habit[:description]}"
      }
    end

    # Recomendação baseada em tendências de humor
    if mood_trends[:average_mood] && mood_trends[:average_mood] < 2
      recommendations << {
        type: 'mood_improvement',
        title: "Foco em atividades que melhoram seu bem-estar",
        description: "Seu humor médio durante este período foi baixo. " +
          "Considere aumentar atividades que sabemos que melhoram seu bem-estar, " +
          "como exercícios, meditação ou socialização."
      }
    end

    # Recomendação de novos hábitos
    if habit_insights[:habits].size < 3
      recommended_habits = recommend_new_habits(user)
      if recommended_habits.any?
        habit = recommended_habits.first
        recommendations << {
          type: 'new_habit',
          title: "Experimente um novo hábito: #{habit[:name]}",
          description: "#{habit[:description]} Usuários com perfil semelhante ao seu relataram melhoras no bem-estar com este hábito."
        }
      end
    end

    # Limitar a 3 recomendações
    recommendations.take(3)
  end

  # Métodos auxiliares

  def calculate_completion_percentage(habit, entries)
    expected_count = expected_entries_count(habit, start_date, end_date)
    return 0 if expected_count == 0

    actual_count = entries.where(completed: true).count
    (actual_count.to_f / expected_count * 100).round
  end

  def expected_entries_count(habit, start_date, end_date)
    days = (end_date - start_date).to_i + 1

    case habit.frequency
    when 'daily'
      days
    when 'weekdays'
      (start_date..end_date).count { |date| (1..5).include?(date.wday) }
    when 'weekends'
      (start_date..end_date).count { |date| [0, 6].include?(date.wday) }
    when 'weekly'
      (days / 7.0).ceil
    when 'monthly'
      start_month = start_date.beginning_of_month
      end_month = end_date.beginning_of_month
      (end_month.year * 12 + end_month.month) - (start_month.year * 12 + start_month.month) + 1
    when 'custom'
      if habit.custom_days.any?
        (start_date..end_date).count { |date| habit.custom_days.include?(date.wday) }
      else
        0
      end
    else
      0
    end
  end

  def calculate_streak(habit)
    entries = habit.habit_entries.where(completed: true).order(created_at: :desc)
    return 0 if entries.empty?

    # Implementação simplificada de cálculo de sequência
    streak = 1
    last_date = entries.first.created_at.to_date

    entries.drop(1).each do |entry|
      entry_date = entry.created_at.to_date

      if is_consecutive?(habit, last_date, entry_date)
        streak += 1
        last_date = entry_date
      else
        break
      end
    end

    streak
  end

  def is_consecutive?(habit, date1, date2)
    case habit.frequency
    when 'daily'
      date1 == date2 + 1.day
    when 'weekdays'
      if date2.wday == 5 # Friday
        date1 == date2 + 3.days
      else
        date1 == date2 + 1.day
      end
    when 'weekends'
      if date2.wday == 0 # Sunday
        date1 == date2 + 6.days
      else
        date1 == date2 + 1.day
      end
    when 'weekly'
      date1 >= date2 + 1.day && date1 <= date2 + 7.days
    else
      false
    end
  end

  def extract_common_topics(analyses)
    # Extrair entidades e frases-chave de todas as análises
    all_entities = []
    all_phrases = []

    analyses.each do |analysis|
      all_entities += analysis.entities if analysis.entities.is_a?(Array)
      all_phrases += analysis.key_phrases if analysis.key_phrases.is_a?(Array)
    end

    # Contar ocorrências de cada entidade/frase
    entity_counts = Hash.new(0)
    all_entities.each { |entity| entity_counts[entity['text']] += 1 }

    phrase_counts = Hash.new(0)
    all_phrases.each { |phrase| phrase_counts[phrase['text']] += 1 }

    # Combinar e ordenar por frequência
    combined_counts = entity_counts.merge(phrase_counts) { |_k, v1, v2| v1 + v2 }
    combined_counts.sort_by { |_k, v| -v }.first(5).to_h
  end

  def calculate_correlation(series1, series2)
    # Garantir que temos os mesmos dias em ambas as séries
    common_days = series1.keys & series2.keys
    return 0 if common_days.size < 3 # Muito poucos pontos para correlação significativa

    x_values = common_days.map { |day| series1[day] }
    y_values = common_days.map { |day| series2[day] }

    # Calcular médias
    x_mean = x_values.sum / x_values.size
    y_mean = y_values.sum / y_values.size

    # Calcular coeficiente de correlação de Pearson
    numerator = 0
    x_variance = 0
    y_variance = 0

    x_values.each_with_index do |x, i|
      y = y_values[i]

      x_diff = x - x_mean
      y_diff = y - y_mean

      numerator += x_diff * y_diff
      x_variance += x_diff * x_diff
      y_variance += y_diff * y_diff
    end

    denominator = Math.sqrt(x_variance * y_variance)
    return 0 if denominator.zero?

    numerator / denominator
  end

  def correlation_strength(correlation)
    abs_corr = correlation.abs

    if abs_corr >= 0.7
      'forte'
    elsif abs_corr >= 0.4
      'moderada'
    elsif abs_corr >= 0.2
      'fraca'
    else
      'insignificante'
    end
  end

  def correlation_description(habit_name, correlation)
    if correlation >= 0.7
      "Manter o hábito de #{habit_name} parece ter um forte impacto positivo no seu humor."
    elsif correlation >= 0.4
      "#{habit_name} parece estar associado a melhorias no seu humor."
    elsif correlation >= 0.2
      "#{habit_name} pode ter um pequeno efeito positivo no seu humor."
    elsif correlation <= -0.7
      "Os dias em que você pratica #{habit_name} parecem estar fortemente associados a um humor mais baixo. Isso pode indicar que você usa esse hábito como resposta a dias ruins, ou que o hábito precisa ser ajustado."
    elsif correlation <= -0.4
      "#{habit_name} parece estar associado a uma redução no seu humor. Considere ajustar este hábito ou quando você o pratica."
    elsif correlation <= -0.2
      "#{habit_name} pode ter um pequeno efeito negativo no seu humor. Monitore este padrão ao longo do tempo."
    else
      "Não encontramos uma relação clara entre #{habit_name} e seu humor."
    end
  end

  def recommend_new_habits(user)
    # Lista de hábitos recomendados baseados nas categorias que o usuário ainda não tem
    existing_categories = user.habits.pluck(:category).uniq

    recommendations = []

    unless existing_categories.include?('meditation')
      recommendations << {
        name: "Meditação Diária",
        category: "meditation",
        description: "5 minutos de meditação pela manhã pode reduzir o estresse e aumentar o foco."
      }
    end

    unless existing_categories.include?('exercise')
      recommendations << {
        name: "Caminhada de 15 minutos",
        category: "exercise",
        description: "Uma curta caminhada diária pode melhorar seu humor e energia."
      }
    end

    unless existing_categories.include?('mindfulness')
      recommendations << {
        name: "Gratidão Diária",
        category: "mindfulness",
        description: "Anotar 3 coisas pelas quais você é grato pode ter um impacto significativo na sua percepção de bem-estar."
      }
    end

    unless existing_categories.include?('sleep')
      recommendations << {
        name: "Rotina de Sono",
        category: "sleep",
        description: "Estabelecer um horário regular para dormir pode melhorar significativamente a qualidade do seu sono e humor."
      }
    end

    unless existing_categories.include?('social')
      recommendations << {
        name: "Conexão Social",
        category: "social",
        description: "Reservar tempo para conexões sociais significativas é crucial para o bem-estar mental."
      }
    end

    # Filtrar recomendações para categorias que o usuário ainda não tem
    recommendations.reject { |r| existing_categories.include?(r[:category]) }.sample(2)
  end
end
