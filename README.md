# Food Recipe API

REST API для приложения рецептов, разработанный на Dart с использованием Conduit Framework.

## Основные возможности

### ✅ Реализованные функции:
- Полноценная авторизация с Bearer токенами
- Профиль пользователя с расширенными данными
- CRUD операции для рецептов, ингредиентов, шагов
- Поиск и фильтрация с пагинацией
- Избранные рецепты для пользователей
- Комментарии к рецептам
- Морозильник (учет продуктов)
- Связь рецептов с ингредиентами и шагами

## Требования

- Dart SDK 3.0+
- PostgreSQL
- Docker (для базы данных)

## Установка и запуск

### 1. База данных

Запустите PostgreSQL в Docker:
```bash
docker-compose up -d
```

База данных будет доступна на порту **5433** (не 5432!).

### 2. Установка зависимостей

```bash
dart pub get
```

### 3. Миграции базы данных

```bash
dart pub run conduit:conduit db upgrade --connect postgres://food:yaigoo2E@localhost:5433/food
```

### 4. Запуск сервера

```bash
dart run bin/main.dart
```

Сервер будет доступен по адресу: https://foodapi.dzolotov.pro

## API Endpoints

### Публичные endpoints (без авторизации)

#### Рецепты - ПОЛНОСТЬЮ РАБОТАЮТ ✅

**GET /recipes** - Получить список рецептов с пагинацией и фильтрами
- Query параметры:
  - `page` (int) - номер страницы (по умолчанию 1)
  - `limit` (int) - количество элементов на странице (по умолчанию 20)
  - `search` (string) - поиск по названию
  - `minTime` (int) - минимальное время приготовления в секундах
  - `maxTime` (int) - максимальное время приготовления в секундах

Пример:
```bash
curl https://foodapi.dzolotov.pro/recipes?page=1&limit=10&search=блин
```

Ответ:
```json
{
  "data": [
    {
      "id": 1,
      "name": "Блины",
      "duration": 1800,
      "photo": "https://example.com/bliny.jpg"
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 10,
    "total": 1,
    "totalPages": 1
  }
}
```

**GET /recipes/{id}** - Получить рецепт по ID с полной информацией (включая шаги, ингредиенты, комментарии)
```bash
curl https://foodapi.dzolotov.pro/recipes/1
```

**POST /recipes** - Создать новый рецепт
```bash
curl -X POST https://foodapi.dzolotov.pro/recipes \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Новый рецепт",
    "duration": 1800,
    "photo": "https://example.com/photo.jpg"
  }'
```

**PUT /recipes/{id}** - Обновить рецепт
```bash
curl -X PUT https://foodapi.dzolotov.pro/recipes/1 \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Обновленное название",
    "duration": 2400
  }'
```

**DELETE /recipes/{id}** - Удалить рецепт (каскадно удаляет связанные данные)
```bash
curl -X DELETE https://foodapi.dzolotov.pro/recipes/1
```

#### Шаги рецептов

**GET /steps** - Получить все шаги
```bash
curl https://foodapi.dzolotov.pro/steps
```

**GET /steps/{id}** - Получить шаг по ID
```bash
curl https://foodapi.dzolotov.pro/steps/1
```

**POST /steps** - Создать новый шаг
```bash
curl -X POST https://foodapi.dzolotov.pro/steps \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Смешать ингредиенты",
    "duration": 300
  }'
```

#### Ингредиенты

**GET /ingredient** - Получить список ингредиентов
```bash
curl https://foodapi.dzolotov.pro/ingredient
```

**GET /ingredient/{id}** - Получить ингредиент по ID
```bash
curl https://foodapi.dzolotov.pro/ingredient/3
```

**POST /ingredient** - Создать новый ингредиент
```bash
curl -X POST https://foodapi.dzolotov.pro/ingredient \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Мёд",
    "caloriesForUnit": 3.04,
    "measureunit": {"id": 1}
  }'
```

**PUT /ingredient/{id}** - Обновить ингредиент
```bash
curl -X PUT https://foodapi.dzolotov.pro/ingredient/12 \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Мёд липовый",
    "caloriesForUnit": 3.1
  }'
```

**DELETE /ingredient/{id}** - Удалить ингредиент
```bash
curl -X DELETE https://foodapi.dzolotov.pro/ingredient/12
```

#### Единицы измерения

**GET /measure_unit** - Получить единицы измерения
```bash
curl https://foodapi.dzolotov.pro/measure_unit
```

#### Ингредиенты рецептов

**GET /recipe-ingredients/recipe/{recipeId}** - Получить ингредиенты рецепта
```bash
curl https://foodapi.dzolotov.pro/recipe-ingredients/recipe/1
```

### Авторизация - ПОЛНОСТЬЮ РАБОТАЕТ ✅

**POST /user** - Регистрация нового пользователя
```bash
# Минимальная регистрация
curl -X POST https://foodapi.dzolotov.pro/user \
  -H "Content-Type: application/json" \
  -d '{
    "login": "user@example.com",
    "password": "password123"
  }'

# Регистрация с полным профилем
curl -X POST https://foodapi.dzolotov.pro/user \
  -H "Content-Type: application/json" \
  -d '{
    "login": "user@example.com",
    "password": "password123",
    "firstName": "Иван",
    "lastName": "Петров",
    "phone": "+79001234567",
    "avatarUrl": "https://example.com/avatar.jpg",
    "birthday": "1990-01-15T00:00:00.000Z"
  }'
```

Ответ:
```json
{
  "status": "ok"
}
```

**PUT /user** - Вход в систему (получение токена)
```bash
curl -X PUT https://foodapi.dzolotov.pro/user \
  -H "Content-Type: application/json" \
  -d '{
    "login": "user@example.com",
    "password": "password123"
  }'
```

Ответ:
```json
{
  "token": "12451f51-2b3d-4e5b-9cf2-5bfdb44fdc7a"
}
```

### Защищенные endpoints (требуют авторизации) - ПОЛНОСТЬЮ РАБОТАЮТ ✅

Для доступа к защищенным endpoints необходимо передавать токен в заголовке:
```
Authorization: Bearer {token}
```

#### Профиль пользователя

**GET /user/profile** - Получить профиль текущего пользователя
```bash
curl https://foodapi.dzolotov.pro/user/profile \
  -H "Authorization: Bearer 12451f51-2b3d-4e5b-9cf2-5bfdb44fdc7a"
```

Ответ:
```json
{
  "id": 1,
  "login": "test@example.com",
  "firstName": "Иван",
  "lastName": "Петров",
  "phone": "+79001234567",
  "avatarUrl": "https://example.com/avatar.jpg",
  "birthday": "1990-01-15T00:00:00.000Z"
}
```

**PUT /user/profile** - Обновить профиль
```bash
curl -X PUT https://foodapi.dzolotov.pro/user/profile \
  -H "Authorization: Bearer {token}" \
  -H "Content-Type: application/json" \
  -d '{
    "firstName": "Иван",
    "lastName": "Петров",
    "phone": "+79001234567",
    "avatarUrl": "https://example.com/avatar.jpg",
    "birthday": "1990-01-15T00:00:00.000Z"
  }'
```

**POST /user/profile/logout** - Выход из системы
```bash
curl -X POST https://foodapi.dzolotov.pro/user/profile/logout \
  -H "Authorization: Bearer {token}"
```

#### Избранное - ПОЛНОСТЬЮ РАБОТАЕТ ✅

**GET /user/favorites** - Получить список избранных рецептов
```bash
curl https://foodapi.dzolotov.pro/user/favorites \
  -H "Authorization: Bearer {token}"
```

Ответ:
```json
[
  {
    "id": 1,
    "name": "Блины",
    "duration": 1800,
    "photo": "https://example.com/bliny.jpg"
  }
]
```

**POST /user/favorites/{recipeId}** - Добавить рецепт в избранное
```bash
curl -X POST https://foodapi.dzolotov.pro/user/favorites/1 \
  -H "Authorization: Bearer {token}"
```

Ответ:
```json
{
  "message": "Recipe added to favorites",
  "favorite": {
    "id": 2,
    "recipe": {"id": 1},
    "user": {"id": 1}
  }
}
```

**DELETE /user/favorites/{recipeId}** - Удалить рецепт из избранного
```bash
curl -X DELETE https://foodapi.dzolotov.pro/user/favorites/1 \
  -H "Authorization: Bearer {token}"
```

#### Комментарии - ПОЛНОСТЬЮ РАБОТАЮТ ✅

**GET /user/comments** - Получить комментарии пользователя
```bash
curl https://foodapi.dzolotov.pro/user/comments \
  -H "Authorization: Bearer {token}"
```

**POST /user/comments** - Добавить комментарий к рецепту
```bash
curl -X POST https://foodapi.dzolotov.pro/user/comments \
  -H "Authorization: Bearer {token}" \
  -H "Content-Type: application/json" \
  -d '{
    "recipeId": 1,
    "text": "Отличный рецепт!"
  }'
```

Ответ:
```json
{
  "id": 1,
  "text": "Отличный рецепт!",
  "photo": null,
  "date_time": "2025-08-25T18:49:19.966104Z",
  "user": {"id": 1},
  "recipe": {
    "id": 1,
    "name": "Блины",
    "duration": 1800,
    "photo": "https://example.com/bliny.jpg"
  }
}
```

**DELETE /user/comments/{id}** - Удалить комментарий
```bash
curl -X DELETE https://foodapi.dzolotov.pro/user/comments/1 \
  -H "Authorization: Bearer {token}"
```

## Модели данных

### Recipe
```json
{
  "id": 1,
  "name": "Блины",
  "duration": 1800,
  "photo": "https://example.com/photo.jpg"
}
```

### User
```json
{
  "id": 1,
  "login": "user@example.com",
  "avatar": "https://example.com/avatar.jpg"
}
```

### Comment
```json
{
  "id": 1,
  "text": "Комментарий",
  "photo": null,
  "date_time": "2025-08-25T18:49:19.966104Z",
  "user": {...},
  "recipe": {...}
}
```

### Favorite
```json
{
  "id": 1,
  "recipe": {...},
  "user": {...}
}
```

## Миграции

Проект использует систему миграций Conduit для управления схемой базы данных.

Создание новой миграции:
```bash
dart pub run conduit:conduit db generate
```

Применение миграций:
```bash
dart pub run conduit:conduit db upgrade --connect postgres://food:yaigoo2E@localhost:5433/food
```

## Архитектура

Проект следует принципам Clean Architecture с разделением на слои:

- **Presentation Layer** - REST API контроллеры (lib/controllers/)
- **Domain Layer** - Модели данных (lib/model/)
- **Data Layer** - Работа с базой данных через Conduit ORM
- **Middleware** - Авторизация через AuthMiddleware

### Структура проекта
```
lib/
├── channel.dart              # Основной канал с маршрутами
├── middleware/
│   └── auth_middleware.dart  # Bearer token авторизация
├── model/                    # Модели данных
│   ├── recipe.dart
│   ├── user.dart
│   ├── comment.dart
│   ├── favorite.dart
│   └── ...
├── controllers/              # REST контроллеры
│   ├── recipe_new.dart      # Канонический RecipeController
│   ├── user.dart            # UserController с авторизацией
│   └── user_profile_controller.dart # Защищенные user endpoints
```

## Особенности реализации

1. **Канонический подход Conduit** - используется ORM вместо прямых SQL запросов
2. **Правильная сериализация** - использование .asMap() для ManagedObject
3. **Миграции** - использование встроенной системы миграций для безопасного обновления схемы БД
4. **Авторизация** - Bearer token аутентификация с middleware для защищенных endpoints
5. **Пагинация** - поддержка пагинации для списковых endpoints
6. **Фильтрация и поиск** - возможность фильтровать рецепты по различным критериям
7. **Каскадное удаление** - правильная обработка связанных данных при удалении
8. **Поддержка Flutter** - автоматическая конвертация camelCase/snake_case для совместимости

## Тестовые данные

База данных содержит тестовые данные:
- 2 пользователя (test@example.com / password123)
- 2 рецепта (Блины, Омлет с сыром)
- Ингредиенты и шаги для рецептов
- Единицы измерения (граммы, штуки, литры, столовые ложки)

## Поддержка домашних заданий

API полностью поддерживает выполнение домашних заданий для модулей M1-M8 курса Flutter разработки:

### M1 - Основы Flutter
- ✅ Базовая структура приложения
- ✅ Figma дизайн: https://www.figma.com/...

### M2 - Навигация
- ✅ Список рецептов (GET /recipes)
- ✅ Детали рецепта (GET /recipes/{id})

### M3 - Списки и сетки
- ✅ Пагинация списков
- ✅ Поиск и фильтрация

### M4 - Работа с сетью
- ✅ REST API интеграция
- ✅ CRUD операции

### M5 - State Management
- ✅ Управление избранным
- ✅ Кэширование данных

### M6 - Авторизация
- ✅ Регистрация и вход
- ✅ Bearer token авторизация
- ✅ Защищенные endpoints

### M7 - Работа с данными
- ✅ Комментарии к рецептам
- ✅ Профиль пользователя

### M8 - Дополнительные возможности
- ✅ Поиск по ингредиентам
- ✅ Фильтрация по времени приготовления

## База данных

PostgreSQL работает в Docker на порту **5433**:

```yaml
# docker-compose.yml
services:
  postgres:
    image: postgres:13
    environment:
      POSTGRES_USER: food
      POSTGRES_PASSWORD: yaigoo2E
      POSTGRES_DB: food
    ports:
      - "5433:5432"  # Внимание: порт 5433!
```

## Разработка

При разработке использовались:
- Dart 3.0+
- Conduit Framework 4.4.0
- PostgreSQL 13+
- Docker для контейнеризации БД
- UUID для генерации токенов

## Известные проблемы и решения

1. **Ошибка сериализации ManagedObject** - решена использованием .asMap()
2. **UUID токен возвращал closure** - исправлено вызовом .v4() вместо .v4.toString()
3. **Конфликт портов PostgreSQL** - используется порт 5433 вместо 5432

## Тестирование

Все endpoints протестированы и работают корректно.

### Быстрый тест:
```bash
# Регистрация
curl -X POST https://foodapi.dzolotov.pro/user \
  -H "Content-Type: application/json" \
  -d '{"login": "test@test.com", "password": "test123"}'

# Вход
TOKEN=$(curl -X PUT https://foodapi.dzolotov.pro/user \
  -H "Content-Type: application/json" \
  -d '{"login": "test@test.com", "password": "test123"}' | jq -r .token)

# Проверка авторизации
curl https://foodapi.dzolotov.pro/user/profile \
  -H "Authorization: Bearer $TOKEN"
```