# Food Recipe API

REST API для приложения рецептов, разработанный на Dart с использованием Conduit Framework.

## Основные возможности

### ✅ Реализованные функции:
- Полноценная авторизация с Bearer токенами
- Профиль пользователя с расширенными данными
- CRUD операции для рецептов, ингредиентов, шагов
- Поиск и фильтрация с пагинацией (включая специальный /recipe/search endpoint)
- Избранные рецепты для пользователей (публичный и защищенный доступ)
- Комментарии к рецептам (публичные CRUD операции)
- Морозильник - учет продуктов с количеством (полный CRUD)
- Единицы измерения для ингредиентов
- Связь рецептов с ингредиентами и шагами
- Поддержка camelCase для Flutter клиентов

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

#### Рецепты

**GET /recipe** - Получить список рецептов с пагинацией и фильтрами
- Query параметры:
  - `page` (int) - номер страницы (по умолчанию 1)
  - `limit` (int) - количество элементов на странице (по умолчанию 20)
  - `search` (string) - поиск по названию
  - `minTime` (int) - минимальное время приготовления в секундах
  - `maxTime` (int) - максимальное время приготовления в секундах

Пример:
```bash
curl https://foodapi.dzolotov.pro/recipe?page=1&limit=10&search=блин

# ИЛИ использовать search endpoint (для кириллицы нужна URL-кодировка)
curl -G "https://foodapi.dzolotov.pro/recipe/search" \
  --data-urlencode "q=блин" \
  --data-urlencode "page=1" \
  --data-urlencode "limit=10"
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

**GET /recipe/{id}** - Получить рецепт по ID с полной информацией (включая шаги, ингредиенты, комментарии)
```bash
curl https://foodapi.dzolotov.pro/recipe/1
```

**POST /recipe** - Создать новый рецепт
```bash
curl -X POST https://foodapi.dzolotov.pro/recipe \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Новый рецепт",
    "duration": 1800,
    "photo": "https://example.com/photo.jpg"
  }'
```

**PUT /recipe/{id}** - Обновить рецепт
```bash
curl -X PUT https://foodapi.dzolotov.pro/recipe/1 \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Обновленное название",
    "duration": 2400
  }'
```

**DELETE /recipe/{id}** - Удалить рецепт (каскадно удаляет связанные данные)
```bash
curl -X DELETE https://foodapi.dzolotov.pro/recipe/1
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
    "measureUnit": {"id": 1}
  }'
```

Ответ:
```json
{
  "id": 13,
  "name": "Мёд",
  "caloriesForUnit": 3.04,
  "measureunit": {
    "id": 1,
    "one": "грамм",
    "few": "грамма",
    "many": "граммов"
  }
}
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

Ответ:
```json
[
  {
    "id": 1,
    "one": "грамм",
    "few": "грамма",
    "many": "граммов"
  },
  {
    "id": 2,
    "one": "штука",
    "few": "штуки",
    "many": "штук"
  }
]
```

#### Избранное (публичный доступ)

**GET /favorite** - Получить все избранные рецепты
```bash
curl https://foodapi.dzolotov.pro/favorite
```

**POST /favorite** - Добавить рецепт в избранное
```bash
curl -X POST https://foodapi.dzolotov.pro/favorite \
  -H "Content-Type: application/json" \
  -d '{
    "user": {"id": 1},
    "recipe": {"id": 2}
  }'
```

Ответ (список избранного):
```bash
curl https://foodapi.dzolotov.pro/favorite
```
```json
[
  {
    "id": 1,
    "user": {"id": 1},
    "recipe": {"id": 2, "name": "Блины"}
  }
]
```

#### Морозилка

**GET /freezer** - Получить содержимое морозилки
```bash
curl https://foodapi.dzolotov.pro/freezer
```

Ответ:
```json
[
  {
    "id": 1,
    "count": 750,
    "user": {"id": 1},
    "ingredient": {"id": 3, "name": "Сахарный песок"}
  }
]
```

**POST /freezer** - Добавить продукт в морозилку
```bash
curl -X POST https://foodapi.dzolotov.pro/freezer \
  -H "Content-Type: application/json" \
  -d '{
    "count": 500.0,
    "user": {"id": 1},
    "ingredient": {"id": 2}
  }'
```

**PUT /freezer/{id}** - Обновить количество продукта
```bash
curl -X PUT https://foodapi.dzolotov.pro/freezer/1 \
  -H "Content-Type: application/json" \
  -d '{"count": 900.0}'
```

**DELETE /freezer/{id}** - Удалить продукт из морозилки
```bash
curl -X DELETE https://foodapi.dzolotov.pro/freezer/1
```

#### Комментарии (публичный доступ)

**GET /comment** - Получить все комментарии (поддерживает фильтры `?recipeId=..` и `?userId=..`)
```bash
curl https://foodapi.dzolotov.pro/comment
```

Ответ:
```json
[
  {
    "id": 1,
    "text": "Отличный рецепт!",
    "photo": null,
    "dateTime": "2025-08-25T18:49:19.966104Z",
    "user": {"id": 1},
    "recipe": {"id": 1, "name": "Блины"}
  }
]
```

**GET /comment/{id}** - Получить комментарий по ID
```bash
curl https://foodapi.dzolotov.pro/comment/1
```

Фильтрация:
```bash
# Комментарии к рецепту
curl "https://foodapi.dzolotov.pro/comment?recipeId=1"
# Комментарии пользователя
curl "https://foodapi.dzolotov.pro/comment?userId=1"
```

**POST /comment** - Добавить комментарий (с авторизацией автор определяется автоматически)
```bash
curl -X POST https://foodapi.dzolotov.pro/comment \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer {token}" \
  -d '{
    "text": "Отличный рецепт",
    "photo": "https://example.com/my-photo.jpg",
    "recipe": {"id": 1}
  }'
```

Ответ:
```json
{
  "id": 3,
  "text": "Отличный рецепт!",
  "photo": "https://example.com/my-photo.jpg",
  "dateTime": "2025-08-26T10:30:00.000000Z",
  "user": {"id": 1},
  "recipe": {"id": 1, "name": "Блины"}
}
```

**PUT /comment/{id}** - Обновить комментарий
```bash
curl -X PUT https://foodapi.dzolotov.pro/comment/1 \
  -H "Content-Type: application/json" \
  -d '{
    "text": "Обновленный текст комментария",
    "photo": "https://example.com/new-photo.jpg"
  }'
```

**DELETE /comment/{id}** - Удалить комментарий
```bash
curl -X DELETE https://foodapi.dzolotov.pro/comment/1
```

#### Health Check

**GET /healthz** - Проверка состояния сервера (health check)
```bash
curl https://foodapi.dzolotov.pro/healthz
```

Ответ:
```json
{
  "status": "healthy"
}
```

Поддерживается также HEAD запрос:
```bash
curl -I https://foodapi.dzolotov.pro/healthz
```

### Связи рецептов с ингредиентами и шагами

#### Ингредиенты рецептов

**GET /recipe-ingredients** - Получить все связи рецептов с ингредиентами
```bash
curl https://foodapi.dzolotov.pro/recipe-ingredients
```

Ответ (с вложенными объектами):
```json
[
  {
    "id": 1,
    "count": 500,
    "recipe": {"id": 1, "name": "Блины"},
    "ingredient": {"id": 2, "name": "Молоко"}
  }
]
```

**GET /recipe-ingredients/recipe/{recipeId}** - Получить ингредиенты конкретного рецепта
```bash
curl https://foodapi.dzolotov.pro/recipe-ingredients/recipe/1
```

Ответ:
```json
[
  {
    "id": 1,
    "count": 500,
    "ingredient": {
      "id": 2,
      "name": "Мука пшеничная",
      "caloriesForUnit": 3.5,
      "measureunit": {
        "id": 1,
        "one": "грамм",
        "few": "грамма",
        "many": "граммов"
      }
    }
  },
  {
    "id": 2,
    "count": 3,
    "ingredient": {
      "id": 4,
      "name": "Яйца",
      "caloriesForUnit": 70.0,
      "measureunit": {
        "id": 2,
        "one": "штука",
        "few": "штуки",
        "many": "штук"
      }
    }
  }
]
```

**POST /recipe-ingredients** - Добавить ингредиент к рецепту

> ⚠️ **Важно**: Поле `count` поддерживает дробные значения (тип `double`). Например: 1.5, 2.75, 0.25

```bash
curl -X POST https://foodapi.dzolotov.pro/recipe-ingredients \
  -H "Content-Type: application/json" \
  -d '{
    "recipe": {"id": 1},
    "ingredient": {"id": 5},
    "count": 200.5
  }'
```

**PUT /recipe-ingredients/{id}** - Обновить количество ингредиента в рецепте
```bash
curl -X PUT https://foodapi.dzolotov.pro/recipe-ingredients/1 \
  -H "Content-Type: application/json" \
  -d '{
    "count": 600.0
  }'
```

**DELETE /recipe-ingredients/{id}** - Удалить ингредиент из рецепта
```bash
curl -X DELETE https://foodapi.dzolotov.pro/recipe-ingredients/1
```

#### Шаги рецептов

**GET /recipe-step-links** - Получить все связи рецептов с шагами
```bash
curl https://foodapi.dzolotov.pro/recipe-step-links
```

Ответ:
```json
[
  {
    "id": 1,
    "number": 1,
    "recipe": {"id": 1, "name": "Блины"},
    "step": {"id": 1, "name": "Смешать муку с молоком"}
  }
]
```

**GET /recipe-step-links/{id}** - Получить связь по ID
```bash
curl https://foodapi.dzolotov.pro/recipe-step-links/1
```

**GET /recipe-step-links/recipe/{recipeId}** - Получить шаги конкретного рецепта в правильном порядке
```bash
curl https://foodapi.dzolotov.pro/recipe-step-links/recipe/1
```

Ответ:
```json
[
  {
    "id": 1,
    "number": 1,
    "step": {
      "id": 1,
      "name": "Смешать муку с молоком",
      "duration": 300
    }
  },
  {
    "id": 2,
    "number": 2,
    "step": {
      "id": 2,
      "name": "Добавить яйца и соль",
      "duration": 180
    }
  },
  {
    "id": 3,
    "number": 3,
    "step": {
      "id": 3,
      "name": "Жарить на сковороде",
      "duration": 600
    }
  }
]
```

**POST /recipe-step-links** - Добавить шаг к рецепту
```bash
curl -X POST https://foodapi.dzolotov.pro/recipe-step-links \
  -H "Content-Type: application/json" \
  -d '{
    "recipe": {"id": 1},
    "step": {"id": 4},
    "number": 4
  }'
```

**PUT /recipe-step-links/{id}** - Изменить порядок шага в рецепте
```bash
curl -X PUT https://foodapi.dzolotov.pro/recipe-step-links/1 \
  -H "Content-Type: application/json" \
  -d '{
    "number": 2
  }'
```

**DELETE /recipe-step-links/{id}** - Удалить шаг из рецепта
```bash
curl -X DELETE https://foodapi.dzolotov.pro/recipe-step-links/1
```

#### Batch операции

**POST /recipe-step-links/batch** - Добавить несколько шагов к рецепту за раз
```bash
curl -X POST https://foodapi.dzolotov.pro/recipe-step-links/batch \
  -H "Content-Type: application/json" \
  -d '[
    {"recipe": {"id": 1}, "step": {"id": 1}, "number": 1},
    {"recipe": {"id": 1}, "step": {"id": 2}, "number": 2},
    {"recipe": {"id": 1}, "step": {"id": 3}, "number": 3}
  ]'
```

**PUT /recipe-step-links/reorder** - Переупорядочить шаги рецепта
```bash
curl -X PUT https://foodapi.dzolotov.pro/recipe-step-links/reorder \
  -H "Content-Type: application/json" \
  -d '{
    "recipeId": 1,
    "stepOrders": [
      {"linkId": 3, "number": 1},
      {"linkId": 1, "number": 2},
      {"linkId": 2, "number": 3}
    ]
  }'
```

**POST /recipe-ingredients/batch** - Добавить несколько ингредиентов к рецепту за раз
```bash
curl -X POST https://foodapi.dzolotov.pro/recipe-ingredients/batch \
  -H "Content-Type: application/json" \
  -d '[
    {"recipe": {"id": 1}, "ingredient": {"id": 2}, "count": 500.0},
    {"recipe": {"id": 1}, "ingredient": {"id": 3}, "count": 750.5},
    {"recipe": {"id": 1}, "ingredient": {"id": 4}, "count": 3.25}
  ]'
```

#### Полная информация о рецепте

При запросе рецепта по ID возвращается полная информация, включая все связанные данные:

**GET /recipe/{id}** - Получить полную информацию о рецепте
```bash
curl https://foodapi.dzolotov.pro/recipe/1
```

Ответ содержит:
- Основную информацию о рецепте (название, время приготовления, фото)
- Список ингредиентов с количеством и единицами измерения
- Список шагов приготовления в правильном порядке
- Комментарии пользователей к рецепту

### Пользователи

**GET /user/{id}** - Получить публичную информацию о пользователе
```bash
curl https://foodapi.dzolotov.pro/user/1
```

Ответ:
```json
{
  "id": 1,
  "login": "test@example.com",
  "firstName": "Иван",
  "lastName": "Петров",
  "avatarUrl": "https://example.com/avatar.jpg"
}
```

### Авторизация

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

Ответ (camelCase):
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

#### Избранное

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
    "text": "Отличный рецепт"
  }'
```

Ответ:
```json
{
  "id": 1,
  "text": "Отличный рецепт!",
  "photo": null,
  "dateTime": "2025-08-25T18:49:19.966104Z",
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
  "firstName": null,
  "lastName": null,
  "avatarUrl": null,
  "phone": null,
  "birthday": null
}
```

### Comment
```json
{
  "id": 1,
  "text": "Комментарий",
  "photo": null,
  "dateTime": "2025-08-25T18:49:19.966104Z",
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

### Freezer
```json
{
  "id": 1,
  "count": 750,
  "user": {"id": 1},
  "ingredient": {"id": 3, "name": "Сахарный песок"}
}
```

### Ingredient
```json
{
  "id": 2,
  "name": "Мука пшеничная",
  "caloriesForUnit": 3.5,
  "measureunit": {
    "id": 1,
    "one": "грамм",
    "few": "грамма",
    "many": "граммов"
  }
}
```

### MeasureUnit
```json
{
  "id": 1,
  "one": "грамм",
  "few": "грамма",
  "many": "граммов"
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

## Тесты

Зависимости: Python 3 и библиотека `requests` (`python3 -m pip install --user requests`).

- Запуск полного набора (без пользовательских сущностей):
  - `python3 test_all.py https://foodapi.dzolotov.pro`
- Запуск с тестами избранного/комментариев/морозилки (нужен существующий `USER_ID`):
  - `python3 test_all.py https://foodapi.dzolotov.pro --user-id <USER_ID>`

Индивидуальные тесты:
- `python3 test_user_api.py https://foodapi.dzolotov.pro`
- `python3 test_recipe_api.py https://foodapi.dzolotov.pro`
- `python3 test_step_links_api.py https://foodapi.dzolotov.pro`
- `python3 test_ingredients_api.py https://foodapi.dzolotov.pro`
- `python3 test_favorites_api.py https://foodapi.dzolotov.pro <USER_ID>`
- `python3 test_comments_api.py https://foodapi.dzolotov.pro <USER_ID>`
- `python3 test_freezer_api.py https://foodapi.dzolotov.pro <USER_ID>`

Внимание: тесты создают и удаляют сущности (рецепты, шаги, ингредиенты). Не запускайте их против боевой базы без необходимости.

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
- ✅ Список рецептов (GET /recipe)
- ✅ Детали рецепта (GET /recipe/{id})

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
4. **Search endpoint JSON сериализация** - исправлена в RecipeSearchController (v0.3.1)
5. **POST /comment JSON декодирование** - требует вложенные объекты {"user": {"id": 1}}

## Полный цикл работы с рецептом (примеры curl)

### 🔐 Авторизация
```bash
# Регистрация (если нужен новый пользователь)
curl -X POST https://foodapi.dzolotov.pro/user \
  -H "Content-Type: application/json" \
  -d '{"login": "chef@example.com", "password": "password123"}'

# Вход и получение токена
TOKEN=$(curl -X PUT https://foodapi.dzolotov.pro/user \
  -H "Content-Type: application/json" \
  -d '{"login": "chef@example.com", "password": "password123"}' | jq -r '.token')

echo "Токен: $TOKEN"
```

### 📝 Создание рецепта с нуля

#### 1. Создаем рецепт
```bash
RECIPE_ID=$(curl -X POST https://foodapi.dzolotov.pro/recipe \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "name": "Борщ",
    "duration": 7200,
    "photo": "https://example.com/borsch.jpg"
  }' | jq -r '.id')

echo "Создан рецепт ID: $RECIPE_ID"
```

#### 2. Добавляем ингредиенты

```bash
# Создаем новый ингредиент (если его еще нет)
BEET_ID=$(curl -X POST https://foodapi.dzolotov.pro/ingredient \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "name": "Свекла",
    "caloriesForUnit": 0.43,
    "measureUnitId": 1
  }' | jq -r '.id')

# Привязываем ингредиент к рецепту (поддерживаются дробные значения!)
# Ответ содержит ID связи (INGREDIENT_LINK_ID), который нужен для обновления
INGREDIENT_LINK_ID=$(curl -X POST https://foodapi.dzolotov.pro/recipe-ingredients \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d "{
    \"recipe\": {\"id\": $RECIPE_ID},
    \"ingredient\": {\"id\": $BEET_ID},
    \"count\": 300.5
  }" | jq -r '.id')
echo "Создана связь рецепт-ингредиент ID: $INGREDIENT_LINK_ID"

# Добавляем существующие ингредиенты (например, 0.5 кг картошки)
curl -X POST https://foodapi.dzolotov.pro/recipe-ingredients \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d "{
    \"recipe\": {\"id\": $RECIPE_ID},
    \"ingredient\": {\"id\": 27},
    \"count\": 0.5
  }"
```

#### 3. Добавляем шаги приготовления

```bash
# Создаем первый шаг
STEP1_ID=$(curl -X POST https://foodapi.dzolotov.pro/steps \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "name": "Подготовить овощи: свеклу натереть на крупной терке, морковь и лук нарезать",
    "duration": 900
  }' | jq -r '.id')

# Привязываем шаг к рецепту
# Ответ содержит ID связи (STEP_LINK_ID), который нужен для изменения порядка
STEP_LINK_ID=$(curl -X POST https://foodapi.dzolotov.pro/recipe-step-links \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d "{
    \"recipe\": {\"id\": $RECIPE_ID},
    \"step\": {\"id\": $STEP1_ID},
    \"number\": 1
  }" | jq -r '.id')
echo "Создана связь рецепт-шаг ID: $STEP_LINK_ID"

# Создаем второй шаг
STEP2_ID=$(curl -X POST https://foodapi.dzolotov.pro/steps \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "name": "В кипящий бульон добавить картофель, варить 10 минут",
    "duration": 600
  }' | jq -r '.id')

# Привязываем второй шаг
curl -X POST https://foodapi.dzolotov.pro/recipe-step-links \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d "{
    \"recipe\": {\"id\": $RECIPE_ID},
    \"step\": {\"id\": $STEP2_ID},
    \"number\": 2
  }"

# Создаем третий шаг
STEP3_ID=$(curl -X POST https://foodapi.dzolotov.pro/steps \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "name": "Добавить свеклу и тушеные овощи, варить еще 15 минут",
    "duration": 900
  }' | jq -r '.id')

curl -X POST https://foodapi.dzolotov.pro/recipe-step-links \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d "{
    \"recipe\": {\"id\": $RECIPE_ID},
    \"step\": {\"id\": $STEP3_ID},
    \"number\": 3
  }"
```

### 🔍 Получение полной информации о рецепте

```bash
# Получить рецепт со всеми данными
curl -X GET "https://foodapi.dzolotov.pro/recipe/$RECIPE_ID" \
  -H "Authorization: Bearer $TOKEN" | jq '.'

# Получить все ингредиенты рецепта
curl -X GET "https://foodapi.dzolotov.pro/recipe-ingredients/recipe/$RECIPE_ID" \
  -H "Authorization: Bearer $TOKEN" | jq '.'

# Получить все шаги рецепта (отсортированы по номеру)
curl -X GET "https://foodapi.dzolotov.pro/recipe-step-links/recipe/$RECIPE_ID" \
  -H "Authorization: Bearer $TOKEN" | jq '.'
```

### ✏️ Изменение рецепта

```bash
# Обновить основную информацию
curl -X PUT "https://foodapi.dzolotov.pro/recipe/$RECIPE_ID" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "name": "Борщ с пампушками",
    "duration": 9000,
    "photo": "https://example.com/borsch-updated.jpg"
  }'

# Получить список ингредиентов рецепта (чтобы найти INGREDIENT_LINK_ID)
curl "https://foodapi.dzolotov.pro/recipe-ingredients/recipe/$RECIPE_ID" \
  -H "Authorization: Bearer $TOKEN"
# Ответ содержит массив с полем "id" - это и есть INGREDIENT_LINK_ID для каждой связи

# Изменить количество ингредиента (используя INGREDIENT_LINK_ID из предыдущего запроса)
curl -X PUT "https://foodapi.dzolotov.pro/recipe-ingredients/$INGREDIENT_LINK_ID" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d "{
    \"count\": 400
  }"

# Получить список шагов рецепта (чтобы найти STEP_LINK_ID)
curl "https://foodapi.dzolotov.pro/recipe-step-links/recipe/$RECIPE_ID" \
  -H "Authorization: Bearer $TOKEN"
# Ответ содержит массив с полем "id" - это и есть STEP_LINK_ID для каждой связи

# Изменить порядок шага (используя STEP_LINK_ID из предыдущего запроса)
curl -X PUT "https://foodapi.dzolotov.pro/recipe-step-links/$STEP_LINK_ID" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d "{
    \"number\": 4
  }"
```

### 🔗 Отвязка ингредиентов и шагов

```bash
# Отвязать ингредиент от рецепта
curl -X DELETE "https://foodapi.dzolotov.pro/recipe-ingredients/$INGREDIENT_LINK_ID" \
  -H "Authorization: Bearer $TOKEN"

# Отвязать шаг от рецепта
curl -X DELETE "https://foodapi.dzolotov.pro/recipe-step-links/$STEP_LINK_ID" \
  -H "Authorization: Bearer $TOKEN"

# Привязать заново с другими параметрами
curl -X POST https://foodapi.dzolotov.pro/recipe-ingredients \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d "{
    \"recipe\": {\"id\": $RECIPE_ID},
    \"ingredient\": {\"id\": $BEET_ID},
    \"count\": 250
  }"
```

### ⭐ Дополнительные операции

```bash
# Добавить рецепт в избранное
curl -X POST https://foodapi.dzolotov.pro/user/favorites/$RECIPE_ID \
  -H "Authorization: Bearer $TOKEN"
echo "Рецепт добавлен в избранное"

# Получить список избранных рецептов
curl https://foodapi.dzolotov.pro/user/favorites \
  -H "Authorization: Bearer $TOKEN"

# Добавить комментарий к рецепту (автор определяется по токену)
curl -X POST https://foodapi.dzolotov.pro/comment \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d "{
    \"recipe\": {\"id\": $RECIPE_ID},
    \"text\": \"Отличный рецепт борща\"
  }"

# Получить комментарии к рецепту
curl "https://foodapi.dzolotov.pro/comment?recipeId=$RECIPE_ID"

# Удалить рецепт из избранного
curl -X DELETE "https://foodapi.dzolotov.pro/user/favorites/$RECIPE_ID" \
  -H "Authorization: Bearer $TOKEN"
echo "Рецепт удален из избранного"
```

### 🗑️ Удаление

```bash
# Удалить отдельный ингредиент (если не используется в рецептах)
curl -X DELETE "https://foodapi.dzolotov.pro/ingredient/$BEET_ID" \
  -H "Authorization: Bearer $TOKEN"

# Удалить отдельный шаг (если не используется в рецептах)
curl -X DELETE "https://foodapi.dzolotov.pro/steps/$STEP1_ID" \
  -H "Authorization: Bearer $TOKEN"

# Удалить весь рецепт (автоматически удалит все связи)
curl -X DELETE "https://foodapi.dzolotov.pro/recipe/$RECIPE_ID" \
  -H "Authorization: Bearer $TOKEN"
```

## Тестирование

Все endpoints протестированы и работают корректно.

### Быстрый тест:
```bash
# Получение ингредиентов
curl https://foodapi.dzolotov.pro/ingredient

# Получение единиц измерения
curl https://foodapi.dzolotov.pro/measure_unit

# Получение морозилки
curl https://foodapi.dzolotov.pro/freezer

# Получение избранного
curl https://foodapi.dzolotov.pro/favorite

# Поиск рецептов (с URL-кодировкой для кириллицы)
curl -G "https://foodapi.dzolotov.pro/recipe/search" --data-urlencode "q=борщ"

# Регистрация пользователя
curl -X POST https://foodapi.dzolotov.pro/user \
  -H "Content-Type: application/json" \
  -d '{"login": "test@test.com", "password": "test123"}'

# Вход в систему
TOKEN=$(curl -X PUT https://foodapi.dzolotov.pro/user \
  -H "Content-Type: application/json" \
  -d '{"login": "test@test.com", "password": "test123"}' | jq -r .token)

# Проверка авторизации
curl https://foodapi.dzolotov.pro/user/profile \
  -H "Authorization: Bearer $TOKEN"

# Добавление продукта в морозилку
curl -X POST https://foodapi.dzolotov.pro/freezer \
  -H "Content-Type: application/json" \
  -d '{"count": 250.0, "user": {"id": 1}, "ingredient": {"id": 2}}'
```
