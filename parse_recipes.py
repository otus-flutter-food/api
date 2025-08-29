#!/usr/bin/env python3
import requests
from bs4 import BeautifulSoup
import json
import time
import re

# Категории рецептов для парсинга
CATEGORIES = [
    {'name': 'закуски', 'url': 'https://blog-food.ru/recipes/zakuski'},
    {'name': 'салаты', 'url': 'https://blog-food.ru/recipes/salatyi'}, 
    {'name': 'первые блюда', 'url': 'https://blog-food.ru/recipes/first-dishes'},
    {'name': 'основные блюда', 'url': 'https://blog-food.ru/recipes/main-dishes'},
    {'name': 'выпечка', 'url': 'https://blog-food.ru/recipes/vypechka'}
]

def parse_category_page(category_url):
    """Парсит страницу категории и извлекает ссылки на рецепты"""
    try:
        headers = {
            'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
        }
        
        response = requests.get(category_url, headers=headers, timeout=10)
        response.raise_for_status()
        
        soup = BeautifulSoup(response.content, 'html.parser')
        
        # Находим все ссылки на рецепты
        recipe_links = []
        recipe_titles = {}
        
        # Ищем ссылки в различных возможных контейнерах
        links = soup.find_all('a', href=True)
        
        for link in links:
            href = link.get('href', '')
            text = link.get_text().strip()
            
            # Проверяем что это ссылка на рецепт и у неё есть осмысленное название
            # Исключаем ссылки на категории и навигацию
            if ('recipes/' in href and 
                not href.endswith('/recipes') and 
                not href.endswith('/zakuski') and
                not href.endswith('/salatyi') and
                not href.endswith('/first-dishes') and
                not href.endswith('/main-dishes') and
                not href.endswith('/vypechka') and
                len(text) > 10 and
                'рецепт' not in text.lower() and
                'кухн' not in text.lower() and
                'блюд' not in text.lower() and
                'закуск' not in text.lower() and
                'салат' not in text.lower() and
                'выпечк' not in text.lower() and
                not text.isdigit()):
                
                # Преобразуем относительные ссылки в абсолютные
                if href.startswith('/'):
                    full_url = 'https://blog-food.ru' + href
                elif href.startswith('recipes/'):
                    full_url = 'https://blog-food.ru/' + href
                else:
                    full_url = href
                
                # Сохраняем и название рецепта
                recipe_links.append(full_url)
                recipe_titles[full_url] = text
        
        # Убираем дубликаты и берем только первые 6
        unique_links = list(dict.fromkeys(recipe_links))[:6]
        print(f"Найдено {len(unique_links)} рецептов в категории {category_url}")
        
        for url in unique_links:
            title = recipe_titles.get(url, 'Без названия')
            print(f"  - {title}")
        
        return unique_links
    except Exception as e:
        print(f"Ошибка при парсинге категории {category_url}: {e}")
        return []

def parse_recipe_page(recipe_url):
    """Парсит страницу отдельного рецепта"""
    try:
        headers = {
            'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
        }
        
        response = requests.get(recipe_url, headers=headers, timeout=10)
        response.raise_for_status()
        
        soup = BeautifulSoup(response.content, 'html.parser')
        
        recipe = {
            'url': recipe_url,
            'title': '',
            'duration': 0,  # в минутах
            'photo': '',
            'ingredients': [],
            'steps': []
        }
        
        # Название рецепта
        title_elem = soup.find('h1') or soup.find(class_=re.compile(r'title', re.I))
        if title_elem:
            recipe['title'] = title_elem.get_text().strip()
        
        # Время приготовления
        time_text = soup.get_text()
        time_matches = re.findall(r'(\d+)\s*мин', time_text)
        if time_matches:
            recipe['duration'] = int(time_matches[0]) * 60  # конвертируем в секунды
        
        # Главная фотография
        img_elem = soup.find('img')
        if img_elem and img_elem.get('src'):
            src = img_elem['src']
            if src.startswith('/'):
                recipe['photo'] = 'https://blog-food.ru' + src
            elif src.startswith('images/'):
                recipe['photo'] = 'https://blog-food.ru/' + src
            else:
                recipe['photo'] = src
        
        # Парсинг ингредиентов и шагов из текста
        text_content = soup.get_text()
        
        # Ищем секцию ингредиентов (обычно после слова "ингредиенты" или перед шагами)
        lines = text_content.split('\n')
        
        ingredients_section = False
        steps_section = False
        
        for line in lines:
            line = line.strip()
            if not line:
                continue
                
            # Определяем секции
            if any(word in line.lower() for word in ['ингредиент', 'состав', 'продукт']):
                ingredients_section = True
                steps_section = False
                continue
            elif any(word in line.lower() for word in ['приготовление', 'способ', 'шаг', 'инструкция']):
                ingredients_section = False
                steps_section = True
                continue
            
            # Парсим ингредиенты
            if ingredients_section and ('гр' in line or 'мл' in line or 'шт' in line or 'ст' in line):
                recipe['ingredients'].append(line)
            
            # Парсим шаги
            if steps_section and len(line) > 10:  # фильтруем короткие строки
                if not line.isdigit():  # не добавляем номера шагов
                    recipe['steps'].append(line)
        
        # Если не нашли ингредиенты, пробуем более простой подход
        if not recipe['ingredients']:
            # Ищем строки с единицами измерения
            for line in lines:
                line = line.strip()
                if any(unit in line for unit in ['гр.', 'мл.', 'шт.', 'ст. л.', 'ч. л.', 'кг.', 'л.']):
                    recipe['ingredients'].append(line)
        
        # Если не нашли шаги, берем длинные строки из середины текста
        if not recipe['steps']:
            long_lines = [line.strip() for line in lines if len(line.strip()) > 30]
            recipe['steps'] = long_lines[:6]  # берем первые 6 длинных строк как шаги
        
        print(f"Спарсен рецепт: {recipe['title']}")
        return recipe
        
    except Exception as e:
        print(f"Ошибка при парсинге рецепта {recipe_url}: {e}")
        return None

def main():
    """Главная функция парсинга"""
    all_recipes = []
    
    for category in CATEGORIES:
        print(f"\nПарсим категорию: {category['name']}")
        
        # Получаем ссылки на рецепты из категории
        recipe_links = parse_category_page(category['url'])
        
        # Парсим каждый рецепт
        for link in recipe_links:
            time.sleep(1)  # задержка между запросами
            
            recipe = parse_recipe_page(link)
            if recipe and recipe['title']:
                recipe['category'] = category['name']
                all_recipes.append(recipe)
    
    # Сохраняем результаты в JSON файл
    with open('/Users/dmitrii/api/parsed_recipes.json', 'w', encoding='utf-8') as f:
        json.dump(all_recipes, f, ensure_ascii=False, indent=2)
    
    print(f"\nВсего спарсено {len(all_recipes)} рецептов")
    print("Результаты сохранены в parsed_recipes.json")

if __name__ == "__main__":
    main()