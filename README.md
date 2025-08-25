# Food Recipe API

REST API для управления рецептами, ингредиентами и связанными данными.

## Содержание
- [Установка и запуск](#установка-и-запуск)
- [Архитектура](#архитектура)
- [API Endpoints](#api-endpoints)
  - [Рецепты](#рецепты-recipes)
  - [Шаги рецептов](#шаги-рецептов-recipe-steps)
  - [Связи рецептов и шагов](#связи-рецептов-и-шагов-recipe-step-links)
  - [Ингредиенты](#ингредиенты-ingredients)
  - [Связи рецептов и ингредиентов](#связи-рецептов-и-ингредиентов-recipe-ingredients)
  - [Комментарии](#комментарии-comments)
  - [Пользователи](#пользователи-users)
  - [Избранное](#избранное-favorites)
  - [Морозилка](#морозилка-freezer)
- [Примеры использования](#примеры-использования)

## Установка и запуск

### Требования
- Dart SDK >= 3.0.0
- PostgreSQL >= 12

### Настройка базы данных
```bash
# Создание базы данных
createdb food

# Настройка переменных окружения (опционально)
export DATABASE_HOST=localhost
export DATABASE_PORT=5432
export DATABASE_USER=food
export DATABASE_PASSWORD=your_password
export DATABASE_NAME=food
```

### Запуск сервера
```bash
# Установка зависимостей
dart pub get

# Запуск в режиме разработки
dart run bin/main.dart

# Сервер запустится на http://localhost:8888
```

## Архитектура

### Структура проекта
```
lib/
├── channel.dart              # Основной канал приложения с маршрутами
├── foodapi.dart             # Экспорт всех моделей
├── model/                   # Модели данных
│   ├── recipe.dart          # Recipe, RecipeStep, RecipeStepLink
│   ├── ingredient.dart      # Ingredient, RecipeIngredient, MeasureUnit
│   ├── comment.dart         # Comment
│   ├── user.dart           # User
│   ├── favorite.dart       # Favorite
│   └── freezer.dart        # Freezer
├── controller/              # REST контроллеры
│   ├── recipe_step_controller.dart
│   ├── recipe_step_link_controller.dart
│   ├── recipe_ingredient_controller.dart
│   └── comment_controller.dart
└── controllers/             # Существующие контроллеры
    ├── base_controller.dart # Базовый контроллер
    ├── recipe.dart
    ├── ingredient.dart
    └── ...
```

## API Endpoints

### Рецепты (Recipes)

#### `GET /recipe`
Получить список всех рецептов
```json
Response: [
  {
    "id": 1,
    "name": "Борщ",
    "duration": 3600,
    "photo": "url_to_photo"
  }
]
```

#### `GET /recipe/{id}`
Получить рецепт по ID
```json
Response: {
  "id": 1,
  "name": "Борщ",
  "duration": 3600,
  "photo": "url_to_photo"
}
```

#### `POST /recipe`
Создать новый рецепт
```json
Request: {
  "name": "Борщ",
  "duration": 3600,
  "photo": "url_to_photo"
}
```

#### `PUT /recipe/{id}`
Обновить рецепт
```json
Request: {
  "name": "Украинский борщ",
  "duration": 4200
}
```

#### `DELETE /recipe/{id}`
Удалить рецепт

### Шаги рецептов (Recipe Steps)

#### `GET /steps`
Получить все шаги
```json
Response: [
  {
    "id": 1,
    "name": "Нарезать овощи",
    "duration": 600,
    "recipeStepLinks": []
  }
]
```

#### `GET /steps/{id}`
Получить шаг по ID

#### `GET /steps/search?name={query}`
Поиск шагов по названию

#### `POST /steps`
Создать новый шаг
```json
Request: {
  "name": "Нарезать овощи",
  "duration": 600
}
```

#### `PUT /steps/{id}`
Обновить шаг

#### `DELETE /steps/{id}`
Удалить шаг (если нет связей с рецептами)

### Связи рецептов и шагов (Recipe Step Links)

#### `GET /recipe-step-links`
Получить все связи
```json
Query parameters:
- recipeId: фильтр по рецепту
- stepId: фильтр по шагу

Response: [
  {
    "id": 1,
    "recipe": {...},
    "step": {...},
    "number": 1
  }
]
```

#### `GET /recipe-step-links/{id}`
Получить связь по ID

#### `GET /recipe-step-links/recipe/{recipeId}`
Получить все шаги для рецепта в правильном порядке

#### `POST /recipe-step-links`
Создать связь рецепта и шага
```json
Request: {
  "recipe": {"id": 1},
  "step": {"id": 5},
  "number": 2
}
```

#### `POST /recipe-step-links/batch`
Создать несколько связей одновременно
```json
Request: [
  {
    "recipeId": 1,
    "stepId": 5,
    "number": 1
  },
  {
    "recipeId": 1,
    "stepId": 6,
    "number": 2
  }
]
```

#### `POST /recipe-step-links/reorder`
Изменить порядок шагов в рецепте
```json
Request: {
  "recipeId": 1,
  "stepOrders": [
    {"linkId": 1, "number": 3},
    {"linkId": 2, "number": 1},
    {"linkId": 3, "number": 2}
  ]
}
```

#### `DELETE /recipe-step-links/{id}`
Удалить связь

#### `DELETE /recipe-step-links/recipe/{recipeId}`
Удалить все шаги для рецепта

### Ингредиенты (Ingredients)

#### `GET /ingredient`
Получить список всех ингредиентов

#### `GET /ingredient/{id}`
Получить ингредиент по ID

#### `POST /ingredient`
Создать новый ингредиент
```json
Request: {
  "name": "Морковь",
  "caloriesForUnit": 41.0,
  "measureUnit": {"id": 1}
}
```

### Связи рецептов и ингредиентов (Recipe Ingredients)

#### `GET /recipe-ingredients`
Получить все связи рецептов с ингредиентами
```json
Query parameters:
- recipeId: фильтр по рецепту
- ingredientId: фильтр по ингредиенту

Response: [
  {
    "id": 1,
    "recipe": {...},
    "ingredient": {...},
    "count": 200
  }
]
```

#### `GET /recipe-ingredients/{id}`
Получить связь по ID

#### `POST /recipe-ingredients`
Добавить ингредиент в рецепт
```json
Request: {
  "recipe": {"id": 1},
  "ingredient": {"id": 3},
  "count": 200
}
```

#### `POST /recipe-ingredients/batch`
Добавить несколько ингредиентов в рецепт
```json
Request: [
  {
    "recipeId": 1,
    "ingredientId": 3,
    "count": 200
  },
  {
    "recipeId": 1,
    "ingredientId": 5,
    "count": 100
  }
]
```

#### `PUT /recipe-ingredients/{id}`
Обновить количество ингредиента

#### `DELETE /recipe-ingredients/{id}`
Удалить ингредиент из рецепта

#### `DELETE /recipe-ingredients/recipe/{recipeId}`
Удалить все ингредиенты из рецепта

### Комментарии (Comments)

#### `GET /comments`
Получить все комментарии
```json
Query parameters:
- recipeId: фильтр по рецепту
- userId: фильтр по пользователю

Response: [
  {
    "id": 1,
    "user": {...},
    "recipe": {...},
    "text": "Отличный рецепт!",
    "photo": "url_to_photo",
    "dateTime": "2024-03-20T10:30:00"
  }
]
```

#### `GET /comments/{id}`
Получить комментарий по ID

#### `GET /comments/recipe/{recipeId}`
Получить все комментарии к рецепту

#### `GET /comments/user/{userId}`
Получить все комментарии пользователя

#### `POST /comments`
Создать новый комментарий
```json
Request: {
  "user": {"id": 1},
  "recipe": {"id": 1},
  "text": "Отличный рецепт!",
  "photo": "url_to_photo"
}
```

#### `PUT /comments/{id}`
Обновить комментарий

#### `DELETE /comments/{id}`
Удалить комментарий

#### `DELETE /comments/recipe/{recipeId}`
Удалить все комментарии к рецепту

### Пользователи (Users)

#### `POST /user`
Регистрация нового пользователя
```json
Request: {
  "username": "john_doe",
  "password": "secure_password",
  "email": "john@example.com"
}
```

#### `GET /user/{id}`
Получить информацию о пользователе

### Избранное (Favorites)

#### `GET /favorite`
Получить список избранных рецептов

#### `POST /favorite`
Добавить рецепт в избранное
```json
Request: {
  "user": {"id": 1},
  "recipe": {"id": 5}
}
```

#### `DELETE /favorite/{id}`
Удалить из избранного

### Морозилка (Freezer)

#### `GET /freezer`
Получить содержимое морозилки

#### `POST /freezer`
Добавить продукт в морозилку
```json
Request: {
  "ingredient": {"id": 3},
  "count": 500,
  "expirationDate": "2024-12-31"
}
```

## Примеры использования

### Сценарий 1: Создание нового рецепта с шагами и ингредиентами

```bash
# 1. Создаем рецепт
curl -X POST http://localhost:8888/recipe \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Овощной салат",
    "duration": 900,
    "photo": "salad.jpg"
  }'
# Получаем: {"id": 10, ...}

# 2. Создаем или находим шаги
curl -X POST http://localhost:8888/steps \
  -H "Content-Type: application/json" \
  -d '{"name": "Нарезать овощи", "duration": 300}'
# Получаем: {"id": 20, ...}

curl -X POST http://localhost:8888/steps \
  -H "Content-Type: application/json" \
  -d '{"name": "Заправить маслом", "duration": 60}'
# Получаем: {"id": 21, ...}

# 3. Связываем шаги с рецептом
curl -X POST http://localhost:8888/recipe-step-links/batch \
  -H "Content-Type: application/json" \
  -d '[
    {"recipeId": 10, "stepId": 20, "number": 1},
    {"recipeId": 10, "stepId": 21, "number": 2}
  ]'

# 4. Добавляем ингредиенты
curl -X POST http://localhost:8888/recipe-ingredients/batch \
  -H "Content-Type: application/json" \
  -d '[
    {"recipeId": 10, "ingredientId": 1, "count": 200},
    {"recipeId": 10, "ingredientId": 2, "count": 150},
    {"recipeId": 10, "ingredientId": 3, "count": 50}
  ]'
```

### Сценарий 2: Получение полной информации о рецепте

```bash
# Получаем основную информацию о рецепте
curl http://localhost:8888/recipe/10

# Получаем шаги рецепта в правильном порядке
curl http://localhost:8888/recipe-step-links/recipe/10

# Получаем ингредиенты рецепта
curl "http://localhost:8888/recipe-ingredients?recipeId=10"

# Получаем комментарии к рецепту
curl http://localhost:8888/comments/recipe/10
```

### Сценарий 3: Изменение порядка шагов в рецепте

```bash
# Получаем текущие связи
curl http://localhost:8888/recipe-step-links/recipe/10

# Меняем порядок
curl -X POST http://localhost:8888/recipe-step-links/reorder \
  -H "Content-Type: application/json" \
  -d '{
    "recipeId": 10,
    "stepOrders": [
      {"linkId": 1, "number": 2},
      {"linkId": 2, "number": 1}
    ]
  }'
```

### Сценарий 4: Добавление комментария с фото

```bash
curl -X POST http://localhost:8888/comments \
  -H "Content-Type: application/json" \
  -d '{
    "user": {"id": 1},
    "recipe": {"id": 10},
    "text": "Получилось очень вкусно! Добавила больше оливкового масла.",
    "photo": "https://example.com/my-salad.jpg"
  }'
```

### Сценарий 5: Поиск рецептов по ингредиентам в морозилке

```bash
# 1. Получаем содержимое морозилки
curl http://localhost:8888/freezer

# 2. Для каждого ингредиента находим рецепты
curl "http://localhost:8888/recipe-ingredients?ingredientId=3"
```

### Сценарий 6: Управление избранными рецептами

```bash
# Добавить в избранное
curl -X POST http://localhost:8888/favorite \
  -H "Content-Type: application/json" \
  -d '{
    "user": {"id": 1},
    "recipe": {"id": 10}
  }'

# Получить список избранного
curl http://localhost:8888/favorite

# Удалить из избранного
curl -X DELETE http://localhost:8888/favorite/5
```

## Коды ответов

- `200 OK` - Успешный запрос
- `201 Created` - Ресурс создан
- `400 Bad Request` - Неверный запрос
- `404 Not Found` - Ресурс не найден
- `500 Internal Server Error` - Ошибка сервера

## Обратная совместимость

Для обратной совместимости сохранены старые эндпоинты:
- `/recipe_step` - аналог `/steps`
- `/recipe_step_link` - аналог `/recipe-step-links`
- `/recipe_ingredient` - аналог `/recipe-ingredients`
- `/comment` - аналог `/comments`

## Переменные окружения

| Переменная | Описание | По умолчанию |
|------------|----------|--------------|
| DATABASE_HOST | Хост базы данных | localhost |
| DATABASE_PORT | Порт базы данных | 5432 |
| DATABASE_USER | Пользователь БД | food |
| DATABASE_PASSWORD | Пароль БД | yaigoo2E |
| DATABASE_NAME | Имя базы данных | food |

## Разработка

### Запуск тестов
```bash
dart test
```

### Миграции базы данных
```bash
# Создание миграции
conduit db generate

# Применение миграций
conduit db upgrade
```

## Лицензия

MIT