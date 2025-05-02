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
        { name: 'Alongamento matinal', description: '5 minutos de alongamento ao acordar para energizar o corpo.' }
      ],
      'meditation' => [
        { name: 'Meditação guiada', description: '10 minutos de meditação guiada para reduzir ansiedade.' },
        { name: 'Respiração consciente', description: '2 minutos de respiração profunda durante o dia.' }
      ],
      'sleep' => [
        { name: 'Hora de dormir consistente', description: 'Dormir no mesmo horário todas as noites melhora a qualidade do sono.' },
        { name: 'Rotina de relaxamento noturno', description: '15 minutos sem telas antes de dormir.' }
      ],
      'nutrition' => [
        { name: 'Café da manhã nutritivo', description: 'Começar o dia com uma refeição equilibrada.' },
        { name: 'Hidratação adequada', description: 'Beber água regularmente durante o dia.' }
      ],
      'social' => [
        { name: 'Contato social diário', description: 'Uma conversa significativa com alguém todos os dias.' },
        { name: 'Desconexão digital', description: 'Tempo sem dispositivos para conexões pessoais.' }
      ],
      'learning' => [
        { name: 'Leitura diária', description: '15 minutos de leitura para estimular a mente.' },
        { name: 'Aprender algo novo', description: 'Dedique tempo para aprender uma nova habilidade.' }
      ],
      'mindfulness' => [
        { name: 'Prática de gratidão', description: 'Anotar 3 coisas pelas quais você é grato diariamente.' },
        { name: 'Momento presente', description: 'Pausar durante o dia para notar seus sentidos.' }
      ]
    }

    # Selecionar categorias que o usuário ainda não possui
    missing_categories = category_recommendations.keys - existing_categories

    # Criar recomendações
    recommendations = []
    missing_categories.sample(limit).each do |category|
      habit = category_recommendations[category].sample

      recommendations << {
        name: habit[:name],
        category: category,
        description: habit[:description],
        source: 'missing_category'
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
          source: 'mood_pattern'
        },
        {
          name: 'Conexão social diária',
          category: 'social',
          description: 'Conversar com amigos ou familiares ajuda a prevenir o isolamento.',
          source: 'mood_pattern'
        },
        {
          name: 'Meditação para ansiedade',
          category: 'meditation',
          description: 'Práticas de meditação específicas para reduzir ansiedade e melhorar o humor.',
          source: 'mood_pattern'
        }
      ]
    elsif average_mood < 3 # Humor médio
      recommendations += [
        {
          name: 'Prática de gratidão',
          category: 'mindfulness',
          description: 'Anotar coisas pelas quais você é grato pode melhorar a percepção de bem-estar.',
          source: 'mood_pattern'
        },
        {
          name: 'Hobby criativo',
          category: 'learning',
          description: 'Dedicar tempo a atividades criativas pode trazer satisfação e realização.',
          source: 'mood_pattern'
        }
      ]
    else # Humor bom
      recommendations += [
        {
          name: 'Registro de vitórias',
          category: 'mindfulness',
          description: 'Anotar suas conquistas para reforçar comportamentos positivos.',
          source: 'mood_pattern'
        },
        {
          name: 'Compartilhar positividade',
          category: 'social',
          description: 'Espalhar positividade ajudando alguém ou fazendo um elogio sincero.',
          source: 'mood_pattern'
        }
      ]
    end

    # Verificar padrões de variação de humor
    mood_variation = recent_entries.pluck(:mood).standard_deviation rescue 0

    if mood_variation > 1.2 # Alta variação de humor
      recommendations << {
        name: 'Rotina consistente',
        category: 'sleep',
        description: 'Manter horários regulares para refeições e sono pode ajudar a estabilizar o humor.',
        source: 'mood_pattern'
      }

      recommendations << {
        name: 'Check-in emocional',
        category: 'mindfulness',
        description: 'Breves momentos durante o dia para verificar como você está se sentindo.',
        source: 'mood_pattern'
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
        popularity: 85
      },
      {
        name: 'Diário de gratidão',
        category: 'mindfulness',
        description: 'Anotar 3 coisas pelas quais você é grato todos os dias.',
        popularity: 78
      },
      {
        name: 'Desconexão digital',
        category: 'mindfulness',
        description: '30 minutos sem dispositivos eletrônicos antes de dormir.',
        popularity: 72
      },
      {
        name: 'Hidratação consciente',
        category: 'nutrition',
        description: 'Beber um copo de água a cada 2 horas durante o dia.',
        popularity: 68 }, }