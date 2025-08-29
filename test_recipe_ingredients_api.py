#!/usr/bin/env python3
"""
Тесты для связей рецепт-ингредиент: глобальный список, список по рецепту,
создание, обновление количества и удаление.
"""

import sys
import time
import requests

BASE_URL = sys.argv[1] if len(sys.argv) > 1 else "https://foodapi.dzolotov.pro"


def log(name: str, ok: bool, msg: str = ""):
    print(f"{'✅ PASS' if ok else '❌ FAIL'} | {name}{(' | ' + msg) if msg else ''}")


def create_recipe():
    r = requests.post(f"{BASE_URL}/recipe", json={"name": f"RI Test {int(time.time())}", "duration": 600})
    return (r.status_code == 200, (r.json().get("id") if r.ok else None))


def create_ingredient():
    r = requests.post(f"{BASE_URL}/ingredient", json={"name": f"RI-Ingredient {int(time.time())}", "caloriesForUnit": 1.0})
    return (r.status_code == 200, (r.json().get("id") if r.ok else None))


def link_ri(rid: int, iid: int, count: float = 2.5):
    r = requests.post(f"{BASE_URL}/recipe-ingredients", json={"recipe": {"id": rid}, "ingredient": {"id": iid}, "count": count})
    return (r.status_code == 200, (r.json().get("id") if r.ok else None), (r.json().get("count") if r.ok else None))


def list_global(rid: int):
    r = requests.get(f"{BASE_URL}/recipe-ingredients", params={"recipeId": rid})
    ok = r.status_code == 200 and isinstance(r.json(), list)
    log("LIST /recipe-ingredients", ok)
    return ok


def list_for_recipe(rid: int):
    r = requests.get(f"{BASE_URL}/recipe-ingredients/recipe/{rid}")
    ok = r.status_code == 200 and isinstance(r.json(), list) and len(r.json()) >= 1
    log("LIST ingredients for recipe", ok)
    return ok


def update_ri(ri_id: int):
    r = requests.put(f"{BASE_URL}/recipe-ingredients/{ri_id}", json={"count": 5.75})
    ok = r.status_code == 200 and float(r.json().get("count", 0)) == 5.75
    log("UPDATE RecipeIngredient count to 5.75", ok)
    return ok


def delete_ri(ri_id: int):
    r = requests.delete(f"{BASE_URL}/recipe-ingredients/{ri_id}")
    ok = r.status_code == 200
    log("DELETE RecipeIngredient", ok)
    return ok


def cleanup(rid: int, iid: int):
    requests.delete(f"{BASE_URL}/recipe/{rid}")
    requests.delete(f"{BASE_URL}/ingredient/{iid}")


def main():
    ok, rid = create_recipe()
    if not ok:
        log("CREATE Recipe", False)
        sys.exit(1)
    log("CREATE Recipe", True, f"id={rid}")

    ok, iid = create_ingredient()
    if not ok:
        log("CREATE Ingredient", False)
        cleanup(rid, 0)
        sys.exit(1)
    log("CREATE Ingredient", True, f"id={iid}")

    ok, ri_id, count = link_ri(rid, iid, 3.25)
    if not ok:
        log("CREATE RI", False)
        cleanup(rid, iid)
        sys.exit(1)
    log("CREATE RI", True, f"id={ri_id}, count={count}")
    
    # Проверяем, что дробное значение сохранилось
    if count != 3.25:
        log("FLOAT support", False, f"Expected 3.25, got {count}")
    else:
        log("FLOAT support", True, "count=3.25 saved correctly")

    list_global(rid)
    list_for_recipe(rid)
    update_ri(ri_id)
    delete_ri(ri_id)
    cleanup(rid, iid)


if __name__ == "__main__":
    main()
