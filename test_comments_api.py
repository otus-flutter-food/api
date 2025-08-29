#!/usr/bin/env python3
"""
Интеграционный тест для комментариев: создание, получение, обновление и удаление.
Требует существующего userId и создаёт временный рецепт.
"""

import sys
import time
import requests

BASE_URL = sys.argv[1] if len(sys.argv) > 1 else "https://foodapi.dzolotov.pro"
USER_ID = int(sys.argv[2]) if len(sys.argv) > 2 else None


def log(name: str, ok: bool, msg: str = ""):
    print(f"{'✅ PASS' if ok else '❌ FAIL'} | {name}{(' | ' + msg) if msg else ''}")


def resolve_user_id() -> int | None:
    return USER_ID


def create_recipe() -> int | None:
    name = f"Comm Test Recipe {int(time.time())}"
    r = requests.post(f"{BASE_URL}/recipe", json={"name": name, "duration": 300, "photo": "https://ex.com/p.jpg"})
    if r.status_code == 200 and r.json().get("id"):
        rid = r.json()["id"]
        log("CREATE Recipe", True, f"id={rid}")
        return rid
    log("CREATE Recipe", False, f"status={r.status_code}")
    return None


def create_comment(user_id: int, recipe_id: int) -> int | None:
    r = requests.post(f"{BASE_URL}/comment", json={
        "userId": user_id,
        "recipeId": recipe_id,
        "text": "Great!",
        "photo": None
    })
    if r.status_code == 200 and r.json().get("id"):
        cid = r.json()["id"]
        log("CREATE Comment", True, f"id={cid}")
        return cid
    log("CREATE Comment", False, f"status={r.status_code} body={r.text}")
    return None


def get_comment(cid: int) -> bool:
    r = requests.get(f"{BASE_URL}/comment/{cid}")
    ok = r.status_code == 200 and r.json().get("id") == cid
    log("GET Comment", ok)
    return ok


def update_comment(cid: int) -> bool:
    r = requests.put(f"{BASE_URL}/comment/{cid}", json={"text": "Updated"})
    ok = r.status_code == 200 and r.json().get("text") == "Updated"
    log("UPDATE Comment", ok)
    return ok


def delete_comment(cid: int) -> bool:
    r = requests.delete(f"{BASE_URL}/comment/{cid}")
    ok = r.status_code == 200
    log("DELETE Comment", ok)
    return ok


def delete_recipe(rid: int) -> bool:
    r = requests.delete(f"{BASE_URL}/recipe/{rid}")
    ok = r.status_code == 200
    log("DELETE Recipe", ok)
    return ok


def main():
    print("=" * 60)
    print("🧪 COMMENTS TESTS")
    print(f"📍 Testing: {BASE_URL}")
    print("=" * 60)
    uid = resolve_user_id()
    if not uid:
        print("SKIP: USER_ID not provided; pass as 2nd arg")
        return
    rid = create_recipe()
    if not (uid and rid):
        sys.exit(1)
    cid = create_comment(uid, rid)
    if not cid:
        delete_recipe(rid)
        sys.exit(1)
    get_comment(cid)
    update_comment(cid)
    delete_comment(cid)
    delete_recipe(rid)


if __name__ == "__main__":
    main()
