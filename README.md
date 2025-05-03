# 🧠 Mindfulness

<div align="center">

![Ruby](https://img.shields.io/badge/ruby-3.3.0-red)
![Rails](https://img.shields.io/badge/rails-7.1.2-red)
![License](https://img.shields.io/badge/license-MIT-blue)
[![CI](https://github.com/seu-usuario/mindful-tracker/actions/workflows/ci.yml/badge.svg)](https://github.com/seu-usuario/mindful-tracker/actions/workflows/ci.yml)

🧘‍♀️ **Construtor de Hábitos Colaborativo para Bem-Estar Mental** 🧘‍♂️

Uma plataforma que capacita a melhorar seu bem-estar mental através do rastreamento de hábitos, jornalização em tempo real e análise de sentimentos com IA.

</div>

## ✨ Características

- 📝 **Diário** - Registre seus pensamentos e sentimentos com análise de sentimentos em tempo real
- 📊 **Rastreamento de Hábitos** - Acompanhe hábitos relacionados à saúde mental e bem-estar
- 🤝 **Colaboração Segura** - Compartilhe registros com terapeutas ou grupos de apoio com controle total
- 🔍 **Análise de Sentimentos** - Descubra padrões emocionais através de IA avançada
- 📱 **PWA Responsivo** - Acesse em qualquer dispositivo, mesmo offline
- 🔔 **Sistema de Notificações** - Lembretes personalizados para manter o foco
- 🛡️ **Privacidade Primeiro** - Criptografia robusta e controles de privacidade granulares
 
### 📚 Gems Principais

- 🔐 `devise` - Autenticação  
- 👮 `pundit` - Políticas de autorização
- ⚡ `hotwire-rails` - SPA-like sem JavaScript complexo
- 🔄 `sidekiq` - Processamento assíncrono
- 📊 `chartkick` - Visualizações de dados
- 🧩 `view_component` - Componentização da UI
- 🔔 `noticed` - Sistema de notificações
- 🔍 `aws-sdk-comprehend` - Análise de sentimentos com IA

## 🏗️ Arquitetura

O MindfulTracker segue uma arquitetura moderna orientada a domínio:

```
┌─────────────────┐      ┌─────────────────┐      ┌─────────────────┐
│                 │      │                 │      │                 │
│  Presentation   │◄────►│    Domain       │◄────►│  Infrastructure │
│     Layer       │      │     Layer       │      │     Layer       │
│                 │      │                 │      │                 │
└─────────────────┘      └─────────────────┘      └─────────────────┘
```

- **Presentation Layer**: Controllers, Views, Components
- **Domain Layer**: Models, Services, Policies
- **Infrastructure Layer**: External APIs, Database, Cache

## 🛠️ Instalação

### Pré-requisitos

- Ruby 3.3.0
- Rails 7.1.2
- PostgreSQL 14+
- Redis 7+
- Node.js 18+
- Yarn 1.22+

### Setup

```bash
# Clone o repositório
git clone https://github.com/seu-usuario/mindful-tracker.git
cd mindful-tracker

# Instale as dependências
bundle install
yarn install

# Configure o banco de dados
rails db:create db:migrate db:seed

# Inicie os servidores
./bin/dev
```

Ou usando Docker:

```bash
docker-compose up
```

## 📝 API

A API RESTful está disponível em `/api/v1` com autenticação JWT.

```http
GET /api/v1/habits
Authorization: Bearer <token>
```

Veja a documentação completa da API no [Postman](https://documenter.getpostman.com/view/123456/mindful-tracker-api).

## 📱 Progressive Web App

O MindfulTracker funciona como um PWA com:

- ⚡ Carregamento rápido
- 🔄 Sincronização offline
- 📲 Instalável em dispositivos
- 🔔 Notificações push

## 🧪 Testes

```bash
# Execute todos os testes
bundle exec rspec

# Execute testes específicos
bundle exec rspec spec/models/
bundle exec rspec spec/services/
```

## 📈 Roadmap

- [x] MVP com rastreamento básico de hábitos
- [x] Diário com análise de sentimentos
- [x] Colaboração em tempo real
- [ ] Integração com wearables para rastreamento de sono
- [ ] Exportação de relatórios para profissionais de saúde
- [ ] App móvel nativo (React Native)

## 🤝 Contribuições

Contribuições são bem-vindas! Por favor, veja o [guia de contribuição](CONTRIBUTING.md) para mais detalhes.

## 📄 Licença

Este projeto está licenciado sob a [Licença MIT](LICENSE).

## 💖 Agradecimentos

- Todos os contribuidores e membros da comunidade
- Rails, Hotwire e o ecossistema Ruby
- Todos que apoiam a causa da saúde mental

---

<div align="center">
  <p>Feito com ❤️ para o bem-estar mental de todos</p>
  <p>
    <a href="https://twitter.com/mindfultracker">Twitter</a> •
    <a href="https://github.com/seu-usuario/mindful-tracker">GitHub</a> •
    <a href="https://mindfultracker.app">Website</a>
  </p>
</div>