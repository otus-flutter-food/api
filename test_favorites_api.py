#!/usr/bin/env python3
"""
Интеграционный тест для избранного: добавление и удаление.
Требует существующего userId и создаёт временный рецепт.
"""

import sys
import time
import requests

BASE_URL = sys.argv[1] if len(sys.argv) > 1 else "http://localhost:8888"
USER_ID = int(sys.argv[2]) if len(sys.argv) > 2 else None


def log(name: str, ok: bool, msg: str = ""):
    print(f"{'✅ PASS' if ok else '❌ FAIL'} | {name}{(' | ' + msg) if msg else ''}")


def resolve_user_id() -> int | None:
    return USER_ID


def create_recipe() -> int | None:
    name = f"Fav Test Recipe {int(time.time())}"
    r = requests.post(f"{BASE_URL}/recipe", json={"name": name, "duration": 300, "photo": "https://ex.com/p.jpg"})
    if r.status_code == 200 and r.json().get("id"):
        rid = r.json()["id"]
        log("CREATE Recipe", True, f"id={rid}")
        return rid
    log("CREATE Recipe", False, f"status={r.status_code}")
    return None


def add_favorite(user_id: int, recipe_id: int) -> int | None:
    r = requests.post(f"{BASE_URL}/favorite", json={"userId": user_id, "recipeId": recipe_id})
    if r.status_code == 200 and r.json().get("id"):
        fid = r.json()["id"]
        log("CREATE Favorite", True, f"id={fid}")
        return fid
    log("CREATE Favorite", False, f"status={r.status_code} body={r.text}")
    return None


def list_all_favorites_contains(fid: int) -> bool:
    r = requests.get(f"{BASE_URL}/favorite")
    ok = r.status_code == 200 and any(item.get('id') == fid for item in (r.json() if isinstance(r.json(), list) else []))
    log("GET Favorites includes created", ok)
    return ok


def delete_favorite(fid: int) -> bool:
    r = requests.delete(f"{BASE_URL}/favorite/{fid}")
    ok = r.status_code == 200
    log("DELETE Favorite", ok)
    return ok


def delete_recipe(rid: int) -> bool:
    r = requests.delete(f"{BASE_URL}/recipe/{rid}")
    ok = r.status_code == 200
    log("DELETE Recipe", ok)
    return ok


def main():
    print("=" * 60)
    print("🧪 FAVORITES TESTS")
    print(f"📍 Testing: {BASE_URL}")
    print("=" * 60)
    uid = resolve_user_id()
    if not uid:
        print("SKIP: USER_ID not provided; pass as 2nd arg")
        return
    rid = create_recipe()
    if not (uid and rid):
        sys.exit(1)
    fid = add_favorite(uid, rid)
    if not fid:
        delete_recipe(rid)
        sys.exit(1)
    list_all_favorites_contains(fid)
    delete_favorite(fid)
    delete_recipe(rid)


if __name__ == "__main__":
    main()
