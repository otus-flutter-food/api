#!/usr/bin/env python3
"""
Автотесты для API рецептов
Тестирует CRUD операции: создание, получение, обновление и удаление рецептов
"""

import requests
import json
import sys
from typing import Dict, Any, Optional
import time

# Конфигурация
BASE_URL = "https://foodapi.dzolotov.pro"
# BASE_URL = "http://localhost:8888"  # Для локального тестирования

class RecipeAPITester:
    def __init__(self, base_url: str = BASE_URL):
        self.base_url = base_url
        self.created_recipe_ids = []  # Для очистки после тестов
        self.test_results = []
        
    def log_result(self, test_name: str, success: bool, message: str = ""):
        """Логирование результата теста"""
        status = "✅ PASS" if success else "❌ FAIL"
        result = f"{status} | {test_name}"
        if message:
            result += f" | {message}"
        print(result)
        self.test_results.append((test_name, success, message))
        
    def test_create_recipe(self) -> Optional[int]:
        """Тест создания нового рецепта"""
        test_name = "CREATE Recipe"
        
        recipe_data = {
            "name": f"Тестовый рецепт Python {int(time.time())}",
            "duration": 2400,
            "photo": "https://example.com/test-recipe.jpg"
        }
        
        try:
            response = requests.post(
                f"{self.base_url}/recipe",
                json=recipe_data,
                headers={"Content-Type": "application/json"}
            )
            
            if response.status_code == 200:
                data = response.json()
                recipe_id = data.get("id")
                
                # Проверяем, что все поля правильно сохранены
                if (data.get("name") == recipe_data["name"] and
                    data.get("duration") == recipe_data["duration"] and
                    data.get("photo") == recipe_data["photo"] and
                    recipe_id is not None):
                    
                    self.created_recipe_ids.append(recipe_id)
                    self.log_result(test_name, True, f"Created recipe ID: {recipe_id}")
                    return recipe_id
                else:
                    self.log_result(test_name, False, "Response data doesn't match request")
                    return None
            else:
                self.log_result(test_name, False, f"Status code: {response.status_code}")
                return None
                
        except Exception as e:
            self.log_result(test_name, False, f"Exception: {str(e)}")
            return None
            
    def test_get_recipe(self, recipe_id: int) -> bool:
        """Тест получения рецепта по ID"""
        test_name = f"GET Recipe/{recipe_id}"
        
        try:
            response = requests.get(f"{self.base_url}/recipe/{recipe_id}")
            
            if response.status_code == 200:
                data = response.json()
                
                # Проверяем наличие основных полей
                required_fields = ["id", "name", "duration", "photo"]
                if all(field in data for field in required_fields):
                    self.log_result(test_name, True, f"Recipe name: {data.get('name')}")
                    return True
                else:
                    self.log_result(test_name, False, "Missing required fields")
                    return False
            else:
                self.log_result(test_name, False, f"Status code: {response.status_code}")
                return False
                
        except Exception as e:
            self.log_result(test_name, False, f"Exception: {str(e)}")
            return False
            
    def test_update_recipe(self, recipe_id: int) -> bool:
        """Тест обновления рецепта"""
        test_name = f"UPDATE Recipe/{recipe_id}"
        
        update_data = {
            "name": f"Обновленный рецепт {int(time.time())}",
            "duration": 3600,
            "photo": "https://example.com/updated.jpg"
        }
        
        try:
            response = requests.put(
                f"{self.base_url}/recipe/{recipe_id}",
                json=update_data,
                headers={"Content-Type": "application/json"}
            )
            
            if response.status_code == 200:
                data = response.json()
                
                # Проверяем, что данные обновились
                if (data.get("id") == recipe_id and
                    data.get("name") == update_data["name"] and
                    data.get("duration") == update_data["duration"] and
                    data.get("photo") == update_data["photo"]):
                    
                    self.log_result(test_name, True, "Recipe updated successfully")
                    return True
                else:
                    self.log_result(test_name, False, "Updated data doesn't match")
                    return False
            else:
                self.log_result(test_name, False, f"Status code: {response.status_code}")
                return False
                
        except Exception as e:
            self.log_result(test_name, False, f"Exception: {str(e)}")
            return False
            
    def test_get_recipe_list(self) -> bool:
        """Тест получения списка рецептов с пагинацией"""
        test_name = "GET Recipe List"
        
        try:
            response = requests.get(
                f"{self.base_url}/recipe",
                params={"limit": 5, "page": 1}
            )
            
            if response.status_code == 200:
                data = response.json()
                
                # Проверяем структуру ответа
                if "data" in data and "pagination" in data:
                    recipes = data["data"]
                    pagination = data["pagination"]
                    
                    if isinstance(recipes, list) and len(recipes) > 0:
                        self.log_result(test_name, True, 
                                      f"Found {len(recipes)} recipes, total: {pagination.get('total')}")
                        return True
                    else:
                        self.log_result(test_name, False, "No recipes in response")
                        return False
                else:
                    self.log_result(test_name, False, "Invalid response structure")
                    return False
            else:
                self.log_result(test_name, False, f"Status code: {response.status_code}")
                return False
                
        except Exception as e:
            self.log_result(test_name, False, f"Exception: {str(e)}")
            return False
            
    def test_search_recipes(self, search_term: str = "тест") -> bool:
        """Тест поиска рецептов"""
        test_name = f"SEARCH Recipes (query: '{search_term}')"
        
        try:
            response = requests.get(
                f"{self.base_url}/recipe",
                params={"search": search_term, "limit": 10}
            )
            
            if response.status_code == 200:
                data = response.json()
                
                if "data" in data:
                    recipes = data["data"]
                    matching = [r for r in recipes if search_term.lower() in r.get("name", "").lower()]
                    
                    self.log_result(test_name, True, 
                                  f"Found {len(matching)}/{len(recipes)} matching recipes")
                    return True
                else:
                    self.log_result(test_name, False, "Invalid response structure")
                    return False
            else:
                self.log_result(test_name, False, f"Status code: {response.status_code}")
                return False
                
        except Exception as e:
            self.log_result(test_name, False, f"Exception: {str(e)}")
            return False
            
    def test_delete_recipe(self, recipe_id: int) -> bool:
        """Тест удаления рецепта"""
        test_name = f"DELETE Recipe/{recipe_id}"
        
        try:
            response = requests.delete(f"{self.base_url}/recipe/{recipe_id}")
            
            if response.status_code == 200:
                # Проверяем, что рецепт действительно удален
                check_response = requests.get(f"{self.base_url}/recipe/{recipe_id}")
                
                if check_response.status_code == 404:
                    self.log_result(test_name, True, "Recipe deleted and not found")
                    if recipe_id in self.created_recipe_ids:
                        self.created_recipe_ids.remove(recipe_id)
                    return True
                else:
                    self.log_result(test_name, False, "Recipe still exists after deletion")
                    return False
            else:
                self.log_result(test_name, False, f"Status code: {response.status_code}")
                return False
                
        except Exception as e:
            self.log_result(test_name, False, f"Exception: {str(e)}")
            return False
            
    def test_invalid_recipe_id(self) -> bool:
        """Тест обработки несуществующего ID"""
        test_name = "GET Recipe/99999 (invalid)"
        
        try:
            response = requests.get(f"{self.base_url}/recipe/99999")
            
            if response.status_code == 404:
                self.log_result(test_name, True, "Correctly returns 404")
                return True
            else:
                self.log_result(test_name, False, f"Unexpected status: {response.status_code}")
                return False
                
        except Exception as e:
            self.log_result(test_name, False, f"Exception: {str(e)}")
            return False
            
    def test_recipe_with_ingredients(self, recipe_id: int) -> bool:
        """Тест добавления ингредиентов к рецепту"""
        test_name = f"ADD Ingredients to Recipe/{recipe_id}"
        
        ingredient_data = {
            "recipe": {"id": recipe_id},
            "ingredient": {"id": 3},  # ID существующего ингредиента
            "count": 2.0
        }
        
        try:
            response = requests.post(
                f"{self.base_url}/recipe-ingredients",
                json=ingredient_data,
                headers={"Content-Type": "application/json"}
            )
            
            if response.status_code == 200:
                data = response.json()
                
                if (data.get("recipe", {}).get("id") == recipe_id and
                    data.get("ingredient", {}).get("id") == 3 and
                    data.get("count") == 2.0):
                    
                    self.log_result(test_name, True, "Ingredient added successfully")
                    return True
                else:
                    self.log_result(test_name, False, "Response data doesn't match")
                    return False
            else:
                # Если не работает новый формат, попробуем старый
                self.log_result(test_name, False, 
                              f"New format failed ({response.status_code}), API might use old format")
                return False
                
        except Exception as e:
            self.log_result(test_name, False, f"Exception: {str(e)}")
            return False
            
    def cleanup(self):
        """Удаление всех созданных тестовых рецептов"""
        print("\n🧹 Cleaning up test data...")
        for recipe_id in self.created_recipe_ids[:]:
            try:
                response = requests.delete(f"{self.base_url}/recipe/{recipe_id}")
                if response.status_code == 200:
                    print(f"  - Deleted test recipe {recipe_id}")
                    self.created_recipe_ids.remove(recipe_id)
            except:
                pass
                
    def run_all_tests(self):
        """Запуск всех тестов"""
        print("=" * 60)
        print("🧪 RECIPE API TESTS")
        print(f"📍 Testing: {self.base_url}")
        print("=" * 60)
        
        # 1. Тест списка рецептов
        self.test_get_recipe_list()
        
        # 2. Создание рецепта
        recipe_id = self.test_create_recipe()
        
        if recipe_id:
            # 3. Получение созданного рецепта
            self.test_get_recipe(recipe_id)
            
            # 4. Обновление рецепта
            self.test_update_recipe(recipe_id)
            
            # 5. Добавление ингредиентов
            self.test_recipe_with_ingredients(recipe_id)
            
            # 6. Удаление рецепта
            self.test_delete_recipe(recipe_id)
        
        # 7. Тест поиска
        self.test_search_recipes()
        
        # 8. Тест несуществующего ID
        self.test_invalid_recipe_id()
        
        # Очистка
        self.cleanup()
        
        # Итоги
        print("\n" + "=" * 60)
        print("📊 TEST RESULTS SUMMARY")
        print("=" * 60)
        
        passed = sum(1 for _, success, _ in self.test_results if success)
        failed = sum(1 for _, success, _ in self.test_results if not success)
        total = len(self.test_results)
        
        print(f"✅ Passed: {passed}/{total}")
        print(f"❌ Failed: {failed}/{total}")
        
        if failed > 0:
            print("\nFailed tests:")
            for name, success, message in self.test_results:
                if not success:
                    print(f"  - {name}: {message}")
        
        return failed == 0


if __name__ == "__main__":
    # Можно передать URL как аргумент
    url = sys.argv[1] if len(sys.argv) > 1 else BASE_URL
    
    tester = RecipeAPITester(url)
    success = tester.run_all_tests()
    
    sys.exit(0 if success else 1)