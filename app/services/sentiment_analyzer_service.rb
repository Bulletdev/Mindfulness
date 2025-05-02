class SentimentAnalyzerService
  attr_reader :text, :language

  def initialize(text, language = 'pt')
    @text = text
    @language = language
  end

  def analyze
    return nil if text.blank?

    # Usar AWS Comprehend para análise avançada
    if Rails.application.config.use_aws_comprehend
      analyze_with_aws
    else
      # Fallback para análise local
      analyze_with_sentimental
    end
  end

  private

  def analyze_with_aws
    client = Aws::Comprehend::Client.new(
      region: Rails.application.credentials.aws[:region],
      access_key_id: Rails.application.credentials.aws[:access_key_id],
      secret_access_key: Rails.application.credentials.aws[:secret_access_key]
    )

    # Análise de sentimento
    sentiment_response = client.detect_sentiment({
                                                   text: text,
                                                   language_code: aws_language_code
                                                 })

    # Detecção de entidades
    entities_response = client.detect_entities({
                                                 text: text,
                                                 language_code: aws_language_code
                                               })

    # Detecção de frases-chave
    key_phrases_response = client.detect_key_phrases({
                                                       text: text,
                                                       language_code: aws_language_code
                                                     })

    # Construir o resultado completo
    {
      primary_sentiment: sentiment_response.sentiment.downcase,
      sentiment_scores: {
        positive: sentiment_response.sentiment_score.positive,
        negative: sentiment_response.sentiment_score.negative,
        neutral: sentiment_response.sentiment_score.neutral,
        mixed: sentiment_response.sentiment_score.mixed
      },
      entities: entities_response.entities.map { |e|
        { text: e.text, type: e.type, score: e.score }
      },
      key_phrases: key_phrases_response.key_phrases.map { |p|
        { text: p.text, score: p.score }
      }
    }
  end

  def analyze_with_sentimental
    # Configurar analisador com o dicionário apropriado
    analyzer = Sentimental.new

    # Carregar dicionário específico do idioma
    dictionary_path = Rails.root.join('lib', 'sentiment', 'dictionaries', "#{language}.yml")
    if File.exist?(dictionary_path)
      analyzer.load_sentimental_dictionary(dictionary_path)
    else
      analyzer.load_defaults
    end

    analyzer.threshold = 0.1

    # Fazer a análise
    sentiment = analyzer.sentiment(text)
    score = analyzer.score(text)

    # Conversão dos resultados para um formato consistente
    sentiment_scores = {}

    if score > 0
      sentiment_scores[:positive] = score
      sentiment_scores[:negative] = 0
      sentiment_scores[:neutral] = 1.0 - score
      sentiment_scores[:mixed] = 0
    elsif score < 0
      sentiment_scores[:positive] = 0
      sentiment_scores[:negative] = score.abs
      sentiment_scores[:neutral] = 1.0 - score.abs
      sentiment_scores[:mixed] = 0
    else
      sentiment_scores[:positive] = 0
      sentiment_scores[:negative] = 0
      sentiment_scores[:neutral] = 1.0
      sentiment_scores[:mixed] = 0
    end

    # Extração manual de entidades simples (não tão avançado quanto AWS)
    simple_entities = extract_simple_entities(text)

    {
      primary_sentiment: sentiment.to_s,
      sentiment_scores: sentiment_scores,
      entities: simple_entities,
      key_phrases: [] # Não disponível na versão simples
    }
  end

  def aws_language_code
    case language
    when 'pt', 'pt-BR'
      'pt'
    when 'en', 'en-US'
      'en'
    else
      'en' # Fallback para inglês
    end
  end

  def extract_simple_entities(text)
    # Implementação básica para extração de entidades
    # Apenas para ilustrar a estrutura. Em produção, seria necessário
    # um sistema mais robusto como Stanford NER ou outro serviço.
    []
  end
end