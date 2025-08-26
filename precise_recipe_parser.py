#!/usr/bin/env python3
import requests
from bs4 import BeautifulSoup
import json
import time
import re
import psycopg2

def parse_single_recipe(recipe_url):
    """Точный парсинг одного рецепта"""
    try:
        headers = {
            'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
        }
        
        response = requests.get(recipe_url, headers=headers, timeout=15)
        response.raise_for_status()
        
        soup = BeautifulSoup(response.content, 'html.parser')
        
        recipe = {
            'url': recipe_url,
            'title': '',
            'duration': 0,  # в секундах
            'photo': '',
            'ingredients': [],
            'steps': []
        }
        
        # 1. Заголовок - ищем h1
        h1_tag = soup.find('h1')
        if h1_tag:
            recipe['title'] = h1_tag.get_text().strip()
            print(f"Найден заголовок: {recipe['title']}")
        
        # 2. Время приготовления - ищем PT формат или текст с "мин"
        page_text = soup.get_text()
        
        # Ищем ISO duration (PT25M)
        pt_match = re.search(r'PT(\d+)M', page_text)
        if pt_match:
            recipe['duration'] = int(pt_match.group(1)) * 60  # конвертируем в секунды
            print(f"Найдено время: {int(pt_match.group(1))} мин")
        else:
            # Ищем просто числа + "мин"
            time_match = re.search(r'(\d+)\s*мин', page_text)
            if time_match:
                recipe['duration'] = int(time_match.group(1)) * 60
                print(f"Найдено время (альт): {int(time_match.group(1))} мин")
        
        # 3. Главное изображение - ищем изображения с recipes в пути
        images = soup.find_all('img')
        for img in images:
            src = img.get('src', '')
            if 'recipes' in src and '00.jpg' in src:  # главное фото обычно 00.jpg
                if src.startswith('//'):
                    recipe['photo'] = 'https:' + src
                elif src.startswith('/'):
                    recipe['photo'] = 'https://blog-food.ru' + src
                elif src.startswith('http'):
                    recipe['photo'] = src
                print(f"Найдено фото: {recipe['photo']}")
                break
        
        # 4. Парсинг ингредиентов из текста
        lines = page_text.split('\n')
        
        # Собираем все строки которые содержат единицы измерения (ТОЛЬКО для ингредиентов)
        ingredient_units = ['гр.', 'гр', 'мл.', 'мл', 'шт.', 'шт', 'ст. л.', 'ч. л.', 'кг.', 'кг', 'л.', 'л', 'зубца', 'зубец', 'пучок']
        
        # Единицы времени НЕ считаются единицами ингредиентов
        time_units = ['минут', 'мин', 'секунд', 'сек', 'час']
        
        # Паттерн для реальных ингредиентов: "Название, количество единица"
        ingredient_pattern = r'^[А-Яа-яЁё\s\>\<\(\)]+,\s*\d+.*?(?:гр|мл|шт|ст\.|ч\.|кг|л|зубц|пуч)'
        
        for line in lines:
            line = line.strip()
            # Ищем строки с ингредиентами по паттерну
            if re.search(ingredient_pattern, line):
                # Дополнительная фильтрация - исключаем навигацию
                if not any(word in line.lower() for word in ['время', 'сложность', 'рейтинг', 'комментар', 'автор', 'кухня:', 'главная', 'салаты', 'блюда', 'паста с креветками']):
                    recipe['ingredients'].append(line)
            
            # Также ищем строки с числами + единицами без запятой (например "Чеснок, 2 зубца")
            elif any(unit in line for unit in ingredient_units) and len(line) < 100:
                if re.search(r'[А-Яа-яЁё]+.*?\d+', line) and ',' in line:
                    # Исключаем комментарии пользователей и служебные строки  
                    if not any(word in line.lower() for word in ['время', 'сложность', 'рейтинг', 'комментар', 'автор', 'кухня:', 'главная', 'салаты', 'блюда', 'паста с креветками', 'теги', 'готов', 'очень', 'вкусн', '2022', '2023', '2024', 'июл']):
                        # Проверяем что это не дата или комментарий
                        if not re.search(r'\d{2}\s+(января|февраля|марта|апреля|мая|июня|июля|августа|сентября|октября|ноября|декабря)', line):
                            recipe['ingredients'].append(line)
        
        print(f"Найдено ингредиентов: {len(recipe['ingredients'])}")
        for ing in recipe['ingredients'][:5]:  # показываем первые 5
            print(f"  - {ing}")
        
        # 5. Парсинг шагов приготовления - ищем по кулинарным действиям
        
        # Расширенный список кулинарных действий
        cooking_verbs = [
            # Основные действия
            'смешив', 'смеш', 'перемеш', 'взбив', 'взбитый',
            'обвалив', 'обваляв', 'панируем', 'обсыпаем', 
            'жар', 'обжар', 'поджар', 'прожар', 'зажар',
            'пар', 'припуск', 'тушим', 'томим',
            'остужаем', 'охлажд', 'остыв', 'остуд',
            'добав', 'влив', 'всыпаем', 'кладём', 'помещаем',
            'заправ', 'приправ', 'солим', 'перчим', 'посол',
            # Подготовка продуктов  
            'наре', 'нарезаем', 'реж', 'шинку', 'измельч', 'руб', 'крош',
            'чист', 'моем', 'промыв', 'сполосн', 'очищ',
            'отдел', 'разбир', 'разлож', 'раскладыв',
            # Процессы приготовления
            'вар', 'кипят', 'довед', 'провар', 'отвар',
            'пек', 'выпек', 'запек', 'подпек', 'румян',
            'готов', 'приготов', 'сготов', 'доготав',
            'растворяем', 'соединяем', 'залив', 'заливк',
            'настаив', 'выдерж', 'маринуем', 'настой',
            # Завершающие действия
            'подаём', 'сервируем', 'украш', 'гарнир', 'оформл',
            'нарез', 'порцион', 'разлив', 'раскладыв',
            'выкладыв', 'выложить', 'раскладыв', 'расстел',
            'полив', 'сбрызг', 'смаз', 'покрыв',
            # Дополнительные действия
            'нагрев', 'подогрев', 'разогрев', 'прогрев',
            'формиру', 'лепим', 'скатыв', 'раскаты',
            'процеж', 'проcеив', 'сит', 'фильтр',
            'маринов', 'засалив', 'солим', 'консерв',
            'взвеш', 'отмер', 'делим', 'порциони'
        ]
        
        step_candidates = []
        
        for line in lines:
            line_clean = line.strip()
            
            # Шаги: длинные строки (25+ символов), содержащие кулинарные действия
            if len(line_clean) > 25:
                # Содержат кулинарные действия
                if any(verb in line_clean.lower() for verb in cooking_verbs):
                    # Исключаем служебную информацию
                    if not any(word in line_clean.lower() for word in ['рейтинг', 'комментар', 'автор', 'кухня', 'время приготовления', 'ккал', 'калорий', 'белк', 'жир', 'углевод']):
                        # И это не ингредиент (нет паттерна "название, количество")
                        if not (any(unit in line_clean for unit in ingredient_units) and re.search(r',\s*\d+', line_clean)):
                            # Убираем двоеточие в конце если есть
                            clean_step = line_clean.rstrip(':')
                            step_candidates.append(clean_step)
        
        # Берем уникальные шаги
        seen = set()
        for step in step_candidates:
            if step not in seen and len(recipe['steps']) < 10:
                seen.add(step)
                recipe['steps'].append(step)
        
        print(f"Найдено шагов: {len(recipe['steps'])}")
        for i, step in enumerate(recipe['steps'][:3], 1):  # показываем первые 3
            print(f"  {i}. {step[:50]}...")
        
        return recipe
        
    except Exception as e:
        print(f"Ошибка при парсинге рецепта {recipe_url}: {e}")
        import traceback
        traceback.print_exc()
        return None

def parse_ingredient_amount_and_unit(ingredient_text):
    """Парсит количество и единицу измерения из строки ингредиента"""
    # Словарь соответствия сокращений к ID единиц измерения
    unit_mapping = {
        'гр': 1, 'гр.': 1, 'грамм': 1, 'г': 1,
        'мл': 2, 'мл.': 2, 'миллилитр': 2,
        'шт': 3, 'шт.': 3, 'штук': 3, 'штука': 3, 'зубца': 3, 'зубец': 3,
        'ст. л.': 4, 'ст.л.': 4, 'столовая ложка': 4, 'столовых ложек': 4,
        'ч. л.': 5, 'ч.л.': 5, 'чайная ложка': 5, 'чайных ложек': 5
    }
    
    # Пытаемся найти количество и единицу измерения
    # Паттерн: "Название, количество единица"
    parts = ingredient_text.split(',')
    if len(parts) >= 2:
        amount_part = parts[1].strip()
        
        # Ищем число в начале
        number_match = re.search(r'^(\d+(?:\.\d+)?)', amount_part)
        if number_match:
            amount = float(number_match.group(1))
            
            # Ищем единицу измерения после числа
            remaining_text = amount_part[number_match.end():].strip()
            
            for unit_text, unit_id in unit_mapping.items():
                if unit_text in remaining_text.lower():
                    return amount, unit_id
            
            # Если не нашли точное совпадение, возвращаем количество без единицы
            return amount, None
    
    return 1.0, None  # По умолчанию

def save_recipe_to_production_db(recipe):
    """Сохраняет рецепт со всеми ингредиентами и шагами в продовую базу данных"""
    try:
        # Подключение к продовой базе
        conn = psycopg2.connect(
            host="192.162.246.40",
            port="5433", 
            database="food",
            user="food",
            password="yaigoo2E"
        )
        
        cur = conn.cursor()
        
        # 1. Вставляем основной рецепт
        insert_recipe_sql = """
            INSERT INTO _recipe (name, duration, photo) 
            VALUES (%s, %s, %s) 
            RETURNING id
        """
        
        cur.execute(insert_recipe_sql, (
            recipe['title'],
            recipe['duration'], 
            recipe['photo']
        ))
        
        recipe_id = cur.fetchone()[0]
        print(f"✅ Рецепт '{recipe['title']}' сохранен с ID: {recipe_id}")
        
        # 2. Сохраняем ингредиенты
        ingredients_saved = 0
        for i, ingredient_text in enumerate(recipe['ingredients'][:10]):  # берем первые 10 чистых
            # Парсим название ингредиента (до запятой)
            ingredient_name = ingredient_text.split(',')[0].strip()
            
            # Парсим количество и единицу измерения
            amount, unit_id = parse_ingredient_amount_and_unit(ingredient_text)
            
            if len(ingredient_name) > 3:  # только если название достаточно длинное
                try:
                    # Проверяем, существует ли уже такой ингредиент
                    check_ingredient_sql = """
                        SELECT id FROM _ingredient WHERE name = %s
                    """
                    
                    cur.execute(check_ingredient_sql, (ingredient_name,))
                    existing_ingredient = cur.fetchone()
                    
                    if existing_ingredient:
                        # Используем существующий ингредиент
                        ingredient_id = existing_ingredient[0]
                        print(f"  → Найден существующий ингредиент: {ingredient_name} (ID: {ingredient_id})")
                    else:
                        # Создаем новый ингредиент с единицей измерения
                        insert_ingredient_sql = """
                            INSERT INTO _ingredient (name, calories_for_unit, measureunit_id) 
                            VALUES (%s, %s, %s) 
                            RETURNING id
                        """
                        
                        cur.execute(insert_ingredient_sql, (ingredient_name, 0.0, unit_id))
                        ingredient_id = cur.fetchone()[0]
                        print(f"  + Создан новый ингредиент: {ingredient_name} (ID: {ingredient_id})")
                    
                    # Связываем с рецептом с правильным количеством
                    insert_recipe_ingredient_sql = """
                        INSERT INTO _recipeingredient (recipe_id, ingredient_id, count) 
                        VALUES (%s, %s, %s)
                    """
                    
                    cur.execute(insert_recipe_ingredient_sql, (recipe_id, ingredient_id, amount))
                    ingredients_saved += 1
                    
                    # Выводим детали парсинга
                    unit_name = "без единицы" if unit_id is None else f"unit_id={unit_id}"
                    print(f"  ✓ {ingredient_name}: {amount} ({unit_name})")
                    
                except Exception as e:
                    print(f"⚠️ Пропуск ингредиента '{ingredient_name}': {e}")
        
        print(f"✅ Сохранено ингредиентов: {ingredients_saved}")
        
        # 3. Сохраняем шаги приготовления
        steps_saved = 0
        for i, step_text in enumerate(recipe['steps']):
            # Убираем двоеточие в конце
            step_name = step_text.rstrip(':')
            
            if len(step_name) > 10:  # только содержательные шаги
                try:
                    # Создаем шаг (с примерной длительностью)
                    step_duration = 300  # 5 минут по умолчанию
                    
                    insert_step_sql = """
                        INSERT INTO _recipestep (name, duration) 
                        VALUES (%s, %s) 
                        RETURNING id
                    """
                    
                    cur.execute(insert_step_sql, (step_name, step_duration))
                    step_id = cur.fetchone()[0]
                    
                    # Связываем с рецептом
                    insert_recipe_step_sql = """
                        INSERT INTO _recipesteplink (recipe_id, step_id, number) 
                        VALUES (%s, %s, %s)
                    """
                    
                    cur.execute(insert_recipe_step_sql, (recipe_id, step_id, i + 1))
                    steps_saved += 1
                    
                except Exception as e:
                    print(f"⚠️ Пропуск шага '{step_name[:30]}...': {e}")
        
        print(f"✅ Сохранено шагов: {steps_saved}")
        
        # Сохраняем все изменения
        conn.commit()
        
        # Закрываем соединение
        cur.close()
        conn.close()
        
        print(f"🎉 Полный рецепт сохранен: {ingredients_saved} ингредиентов, {steps_saved} шагов")
        return recipe_id
        
    except Exception as e:
        print(f"❌ Ошибка сохранения в базу: {e}")
        import traceback
        traceback.print_exc()
        if 'conn' in locals():
            conn.rollback()
            conn.close()
        return None

def main():
    """Парсинг рецепта и загрузка в продовую базу"""
    import sys
    
    if len(sys.argv) != 2:
        print("❌ Использование: python3 precise_recipe_parser.py <URL>")
        print("📖 Пример: python3 precise_recipe_parser.py https://blog-food.ru/recipes/first-dishes/borscht")
        sys.exit(1)
    
    recipe_url = sys.argv[1]
    
    if 'blog-food.ru' not in recipe_url:
        print("❌ Поддерживаются только рецепты с сайта blog-food.ru")
        sys.exit(1)
    
    print(f"🔍 Парсим рецепт: {recipe_url}")
    recipe = parse_single_recipe(recipe_url)
    
    if recipe:
        print(f"\n📊 Результат парсинга:")
        print(f"Название: {recipe['title']}")
        print(f"Время: {recipe['duration']//60} мин")
        print(f"Фото: {recipe['photo']}")
        print(f"Ингредиентов: {len(recipe['ingredients'])}")
        print(f"Шагов: {len(recipe['steps'])}")
        
        # Сохраняем в JSON для отладки
        with open('/Users/dmitrii/api/test_recipe.json', 'w', encoding='utf-8') as f:
            json.dump(recipe, f, ensure_ascii=False, indent=2)
        print("📄 JSON сохранен в test_recipe.json")
        
        # Загружаем в продовую базу
        print(f"\n🚀 Загружаем в продовую базу данных...")
        recipe_id = save_recipe_to_production_db(recipe)
        
        if recipe_id:
            print(f"\n🎉 Успешно! Рецепт загружен в продовую базу с ID: {recipe_id}")
            print(f"🌐 Проверить можно: https://foodapi.dzolotov.pro/recipe/{recipe_id}")
        else:
            print("\n❌ Не удалось загрузить в продовую базу")
            
    else:
        print("❌ Не удалось спарсить рецепт")

if __name__ == "__main__":
    main()