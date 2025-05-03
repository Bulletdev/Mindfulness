class HabitRecommenderService
  attr_reader :user

  def initialize(user)
    @user = user
  end

  def recommend(limit = 3)
    # Combinação de recomendações baseadas em diferentes estratégias
    recommendations = []

    # 1. Recomendações baseadas em categorias faltantes
    recommendations += recommend_by_missing_categories(2)

    # 2. Recomendações baseadas em padrões de humor
    recommendations += recommend_by_mood_patterns(2)

    # 3. Recomendações populares entre usuários semelhantes
    recommendations += recommend_by_similar_users(2)

    # 4. Recomendações baseadas em objetivos do usuário
    recommendations += recommend_by_user_goals(2)

    # 5. Recomendações baseadas em consistência atual
    recommendations += recommend_by_consistency(2)

    # Remover duplicatas e limitar ao número solicitado
    recommendations.uniq { |r| r[:name] }.take(limit)
  end

  private

  def recommend_by_missing_categories(limit = 2)
    existing_categories = user.habits.pluck(:category).uniq

    # Definir hábitos recomendados para cada categoria
    category_recommendations = {
      'exercise' => [
        { name: 'Caminhada de 15 minutos', description: 'Uma breve caminhada diária pode melhorar seu humor e energia.' },
        { name: 'Alongamento matinal', description: '5 minutos de alongamento ao acordar para energizar o corpo.' },
        { name: 'Exercícios de mobilidade', description: 'Exercícios simples para manter as articulações saudáveis.' }
      ],
      'meditation' => [
        { name: 'Meditação guiada', description: '10 minutos de meditação guiada para reduzir ansiedade.' },
        { name: 'Respiração consciente', description: '2 minutos de respiração profunda durante o dia.' },
        { name: 'Escaneamento corporal', description: '5 minutos para relaxar cada parte do corpo sequencialmente.' }
      ],
      'sleep' => [
        { name: 'Hora de dormir consistente', description: 'Dormir no mesmo horário todas as noites melhora a qualidade do sono.' },
        { name: 'Rotina de relaxamento noturno', description: '15 minutos sem telas antes de dormir.' },
        { name: 'Preparação do ambiente', description: 'Criar um ambiente escuro e fresco para melhorar o sono.' }
      ],
      'nutrition' => [
        { name: 'Café da manhã nutritivo', description: 'Começar o dia com uma refeição equilibrada.' },
        { name: 'Hidratação adequada', description: 'Beber água regularmente durante o dia.' },
        { name: 'Planejamento de refeições', description: 'Planejar refeições saudáveis com antecedência.' }
      ],
      'social' => [
        { name: 'Contato social diário', description: 'Uma conversa significativa com alguém todos os dias.' },
        { name: 'Desconexão digital', description: 'Tempo sem dispositivos para conexões pessoais.' },
        { name: 'Voluntariado regular', description: 'Dedicar tempo para ajudar os outros fortalece laços sociais.' }
      ],
      'learning' => [
        { name: 'Leitura diária', description: '15 minutos de leitura para estimular a mente.' },
        { name: 'Aprender algo novo', description: 'Dedique tempo para aprender uma nova habilidade.' },
        { name: 'Prática de idiomas', description: 'Dedicar 10 minutos diários ao aprendizado de um novo idioma.' }
      ],
      'mindfulness' => [
        { name: 'Prática de gratidão', description: 'Anotar 3 coisas pelas quais você é grato diariamente.' },
        { name: 'Momento presente', description: 'Pausar durante o dia para notar seus sentidos.' },
        { name: 'Check-in emocional', description: 'Identificar e reconhecer suas emoções regularmente.' }
      ],
      'other' => [
        { name: 'Autodesenvolvimento', description: 'Tempo dedicado a refletir sobre suas metas e crescimento pessoal.' },
        { name: 'Organização diária', description: 'Planejar seu dia na noite anterior ou pela manhã.' },
        { name: 'Tempo na natureza', description: 'Passar tempo ao ar livre regularmente para bem-estar físico e mental.' }
      ]
    }

    # Selecionar categorias que o usuário ainda não possui
    missing_categories = category_recommendations.keys - existing_categories

    # Se todas as categorias já estiverem cobertas, recomende categorias menos utilizadas
    if missing_categories.empty?
      category_counts = user.habits.group(:category).count
      least_used_categories = category_counts.sort_by { |_, count| count }.take(3).map(&:first)
      missing_categories = least_used_categories
    end

    # Criar recomendações
    recommendations = []
    missing_categories.sample(limit).each do |category|
      habit = category_recommendations[category].sample

      recommendations << {
        name: habit[:name],
        category: category,
        description: habit[:description],
        source: 'missing_category',
        frequency: suggest_frequency_for_habit(habit[:name])
      }
    end

    recommendations
  end

  def recommend_by_mood_patterns(limit = 2)
    # Analisar entradas de diário para identificar padrões de humor
    recent_entries = user.journal_entries.order(created_at: :desc).limit(30)

    # Verificar se temos entradas suficientes para análise
    return [] if recent_entries.count < 5

    # Calcular humor médio
    average_mood = recent_entries.average(:mood).to_f

    recommendations = []

    # Recomendações baseadas no humor médio
    if average_mood < 2 # Humor baixo
      recommendations += [
        {
          name: 'Caminhada ao ar livre',
          category: 'exercise',
          description: 'Exercício leve ao ar livre pode liberar endorfinas e melhorar o humor.',
          source: 'mood_pattern',
          frequency: 'daily'
        },
        {
          name: 'Conexão social diária',
          category: 'social',
          description: 'Conversar com amigos ou familiares ajuda a prevenir o isolamento.',
          source: 'mood_pattern',
          frequency: 'daily'
        },
        {
          name: 'Meditação para ansiedade',
          category: 'meditation',
          description: 'Práticas de meditação específicas para reduzir ansiedade e melhorar o humor.',
          source: 'mood_pattern',
          frequency: 'daily'
        }
      ]
    elsif average_mood < 3 # Humor médio
      recommendations += [
        {
          name: 'Prática de gratidão',
          category: 'mindfulness',
          description: 'Anotar coisas pelas quais você é grato pode melhorar a percepção de bem-estar.',
          source: 'mood_pattern',
          frequency: 'daily'
        },
        {
          name: 'Hobby criativo',
          category: 'learning',
          description: 'Dedicar tempo a atividades criativas pode trazer satisfação e realização.',
          source: 'mood_pattern',
          frequency: 'weekdays'
        }
      ]
    else # Humor bom
      recommendations += [
        {
          name: 'Registro de vitórias',
          category: 'mindfulness',
          description: 'Anotar suas conquistas para reforçar comportamentos positivos.',
          source: 'mood_pattern',
          frequency: 'daily'
        },
        {
          name: 'Compartilhar positividade',
          category: 'social',
          description: 'Espalhar positividade ajudando alguém ou fazendo um elogio sincero.',
          source: 'mood_pattern',
          frequency: 'daily'
        }
      ]
    end

    # Verificar padrões de variação de humor
    mood_variation = calculate_mood_variation(recent_entries)

    if mood_variation > 1.2 # Alta variação de humor
      recommendations << {
        name: 'Rotina consistente',
        category: 'sleep',
        description: 'Manter horários regulares para refeições e sono pode ajudar a estabilizar o humor.',
        source: 'mood_pattern',
        frequency: 'daily'
      }

      recommendations << {
        name: 'Check-in emocional',
        category: 'mindfulness',
        description: 'Breves momentos durante o dia para verificar como você está se sentindo.',
        source: 'mood_pattern',
        frequency: 'daily'
      }
    end

    # Selecionar aleatoriamente entre as recomendações apropriadas
    recommendations.sample(limit)
  end

  def recommend_by_similar_users(limit = 2)
    # Em um sistema real, isso seria implementado com um algoritmo de recomendação
    # baseado em similaridade de usuários. Aqui, simplificamos com recomendações
    # populares gerais.

    popular_habits = [
      {
        name: 'Meditação matinal',
        category: 'meditation',
        description: '10 minutos de meditação ao acordar para começar o dia com clareza.',
        popularity: 85,
        frequency: 'daily'
      },
      {
        name: 'Diário de gratidão',
        category: 'mindfulness',
        description: 'Anotar 3 coisas pelas quais você é grato todos os dias.',
        popularity: 78,
        frequency: 'daily'
      },
      {
        name: 'Desconexão digital',
        category: 'mindfulness',
        description: '30 minutos sem dispositivos eletrônicos antes de dormir.',
        popularity: 72,
        frequency: 'daily'
      },
      {
        name: 'Hidratação consciente',
        category: 'nutrition',
        description: 'Beber um copo de água a cada 2 horas durante o dia.',
        popularity: 68,
        frequency: 'daily'
      },
      {
        name: 'Leitura noturna',
        category: 'learning',
        description: '20 minutos de leitura antes de dormir para relaxar a mente.',
        popularity: 65,
        frequency: 'daily'
      },
      {
        name: 'Alongamento corporal',
        category: 'exercise',
        description: '5 minutos de alongamento para melhorar flexibilidade e postura.',
        popularity: 63,
        frequency: 'daily'
      }
    ]

    # Filtrar hábitos que o usuário já possui
    existing_habit_names = user.habits.pluck(:name)
    filtered_habits = popular_habits.reject { |h| existing_habit_names.include?(h[:name]) }

    # Ordenar por popularidade e selecionar
    recommendations = filtered_habits.sort_by { |h| -h[:popularity] }.take(limit)

    # Formatar recomendações
    recommendations.map do |habit|
      {
        name: habit[:name],
        category: habit[:category],
        description: habit[:description],
        source: 'popular_habit',
        frequency: habit[:frequency]
      }
    end
  end

  def recommend_by_user_goals(limit = 2)
    # Recomendações baseadas nos objetivos declarados pelo usuário
    # Isso depende de como os objetivos são estruturados em seu sistema
    return [] unless user.respond_to?(:goals) && user.goals.present?

    recommendations = []

    user.goals.each do |goal|
      case goal.category
      when 'fitness'
        recommendations += [
          {
            name: 'Exercício diário curto',
            category: 'exercise',
            description: '10 minutos de exercícios de alta intensidade para otimizar seu tempo.',
            source: 'user_goal',
            frequency: 'daily'
          },
          {
            name: 'Registro de medidas',
            category: 'mindfulness',
            description: 'Acompanhar seu progresso para manter a motivação.',
            source: 'user_goal',
            frequency: 'weekly'
          }
        ]
      when 'mental_health'
        recommendations += [
          {
            name: 'Prática de atenção plena',
            category: 'mindfulness',
            description: '5 minutos de meditação focada para reduzir o estresse.',
            source: 'user_goal',
            frequency: 'daily'
          },
          {
            name: 'Limite de notícias',
            category: 'other',
            description: 'Limitar o consumo de notícias para reduzir a ansiedade.',
            source: 'user_goal',
            frequency: 'daily'
          }
        ]
      when 'productivity'
        recommendations += [
          {
            name: 'Planejamento matinal',
            category: 'other',
            description: '5 minutos para definir prioridades antes de começar o dia.',
            source: 'user_goal',
            frequency: 'weekdays'
          },
          {
            name: 'Técnica Pomodoro',
            category: 'other',
            description: 'Trabalhar em intervalos focados de 25 minutos com pequenas pausas.',
            source: 'user_goal',
            frequency: 'weekdays'
          }
        ]
      when 'learning'
        recommendations += [
          {
            name: 'Sessão de estudo diária',
            category: 'learning',
            description: 'Dedicar 20 minutos para aprender algo novo todos os dias.',
            source: 'user_goal',
            frequency: 'daily'
          },
          {
            name: 'Revisão semanal',
            category: 'learning',
            description: 'Revisar aprendizados da semana para consolidar o conhecimento.',
            source: 'user_goal',
            frequency: 'weekly'
          }
        ]
      end
    end

    # Filtrar hábitos que o usuário já possui
    existing_habit_names = user.habits.pluck(:name)
    filtered_recommendations = recommendations.reject { |r| existing_habit_names.include?(r[:name]) }

    # Selecionar aleatoriamente
    filtered_recommendations.sample(limit)
  end

  def recommend_by_consistency(limit = 2)
    # Analisar padrões de consistência nos hábitos existentes
    habits_with_stats = user.habits.active.map do |habit|
      completion_rate = habit.completion_rate(Date.today - 30.days, Date.today)
      { habit: habit, completion_rate: completion_rate }
    end

    # Calcular taxa média de conclusão
    average_completion_rate = habits_with_stats.map { |h| h[:completion_rate] }.sum / habits_with_stats.size.to_f rescue 0

    recommendations = []

    if average_completion_rate < 30
      # Baixa consistência geral - sugerir hábitos mais fáceis ou menos frequentes
      recommendations += [
        {
          name: 'Mini-hábito diário',
          category: 'other',
          description: 'Começar com um hábito tão pequeno que seja impossível falhar (30 segundos).',
          source: 'consistency',
          frequency: 'daily'
        },
        {
          name: 'Hábito ancorado',
          category: 'other',
          description: 'Conectar um novo hábito a algo que você já faz todos os dias.',
          source: 'consistency',
          frequency: 'daily'
        },
        {
          name: 'Uma vez por semana',
          category: 'other',
          description: 'Comece com um compromisso semanal em vez de diário para construir confiança.',
          source: 'consistency',
          frequency: 'weekly'
        }
      ]
    elsif average_completion_rate > 80
      # Alta consistência - sugerir hábitos mais desafiadores
      recommendations += [
        {
          name: 'Desafio progressivo',
          category: 'other',
          description: 'Aumentar gradualmente a dificuldade de um hábito existente.',
          source: 'consistency',
          frequency: 'daily'
        },
        {
          name: 'Hábito composto',
          category: 'other',
          description: 'Combinar dois hábitos existentes para maior eficiência.',
          source: 'consistency',
          frequency: 'daily'
        },
        {
          name: 'Compartilhar progresso',
          category: 'social',
          description: 'Compartilhar seu sucesso com outros para maior responsabilidade.',
          source: 'consistency',
          frequency: 'weekly'
        }
      ]
    else
      # Consistência média - sugerir hábitos de suporte
      recommendations += [
        {
          name: 'Preparação do ambiente',
          category: 'other',
          description: 'Organizar seu ambiente para facilitar seus hábitos.',
          source: 'consistency',
          frequency: 'weekly'
        },
        {
          name: 'Revisão de hábitos',
          category: 'mindfulness',
          description: 'Reservar um momento semanal para revisar e ajustar seus hábitos.',
          source: 'consistency',
          frequency: 'weekly'
        },
        {
          name: 'Celebrar pequenas vitórias',
          category: 'mindfulness',
          description: 'Reconhecer e celebrar seu progresso regularmente.',
          source: 'consistency',
          frequency: 'daily'
        }
      ]
    end

    # Filtrar hábitos que o usuário já possui
    existing_habit_names = user.habits.pluck(:name)
    filtered_recommendations = recommendations.reject { |r| existing_habit_names.include?(r[:name]) }

    # Selecionar aleatoriamente
    filtered_recommendations.sample(limit)
  end

  # Métodos auxiliares

  def calculate_mood_variation(entries)
    return 0 if entries.empty?

    moods = entries.pluck(:mood)
    return 0 if moods.empty?

    # Cálculo manual do desvio padrão
    mean = moods.sum / moods.size.to_f
    variance = moods.map { |m| (m - mean) ** 2 }.sum / moods.size.to_f
    Math.sqrt(variance)
  end

  def suggest_frequency_for_habit(habit_name)
    # Sugerir uma frequência apropriada com base no nome ou tipo de hábito
    case habit_name.downcase
    when /diário|matinal|noturno|dia/
      'daily'
    when /trabalho|estudo|produti/
      'weekdays'
    when /relaxamento|lazer|descanso/
      'weekends'
    when /semanal|semana/
      'weekly'
    when /mensal|mês/
      'monthly'
    else
      # Análise do padrão de uso do usuário
      user_preferred_frequency = user.habits.group(:frequency).count.max_by { |_, count| count }&.first
      user_preferred_frequency || 'daily' # Frequência padrão
    end
  end
end