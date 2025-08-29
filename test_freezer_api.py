#!/usr/bin/env python3
"""
Интеграционный тест для морозилки: добавление, получение, обновление и удаление.
Требует существующего userId, создаёт временный ингредиент.
"""

import sys
import time
import requests

BASE_URL = sys.argv[1] if len(sys.argv) > 1 else "http://localhost:8888"
USER_ID = int(sys.argv[2]) if len(sys.argv) > 2 else None


def log(name: str, ok: bool, msg: str = ""):
    print(f"{'✅ PASS' if ok else '❌ FAIL'} | {name}{(' | ' + msg) if msg else ''}")


def resolve_user_id():
    return USER_ID


def create_ingredient() -> int | None:
    r = requests.post(f"{BASE_URL}/ingredient", json={
        "name": f"Frz-{int(time.time())}",
        "caloriesForUnit": 1.0
    })
    if r.status_code == 200 and r.json().get("id"):
        iid = r.json()["id"]
        log("CREATE Ingredient", True, f"id={iid}")
        return iid
    log("CREATE Ingredient", False, f"status={r.status_code} body={r.text}")
    return None


def add_freezer(uid: int, iid: int) -> int | None:
    r = requests.post(f"{BASE_URL}/freezer", json={
        "userId": uid,
        "ingredientId": iid,
        "count": 2.5
    })
    if r.status_code == 200 and r.json().get("id"):
        fid = r.json()["id"]
        log("CREATE Freezer Item", True, f"id={fid}")
        return fid
    log("CREATE Freezer Item", False, f"status={r.status_code} body={r.text}")
    return None


def get_freezer(fid: int) -> bool:
    r = requests.get(f"{BASE_URL}/freezer/{fid}")
    ok = r.status_code == 200 and r.json().get("id") == fid
    log("GET Freezer Item", ok)
    return ok


def update_freezer(fid: int) -> bool:
    r = requests.put(f"{BASE_URL}/freezer/{fid}", json={"count": 5.0})
    ok = r.status_code == 200 and abs(r.json().get("count", 0) - 5.0) < 1e-6
    log("UPDATE Freezer Item", ok)
    return ok


def delete_freezer(fid: int) -> bool:
    r = requests.delete(f"{BASE_URL}/freezer/{fid}")
    ok = r.status_code == 200
    log("DELETE Freezer Item", ok)
    return ok


def delete_ingredient(iid: int) -> bool:
    r = requests.delete(f"{BASE_URL}/ingredient/{iid}")
    ok = r.status_code == 200
    log("DELETE Ingredient", ok)
    return ok


def main():
    print("=" * 60)
    print("🧪 FREEZER TESTS")
    print(f"📍 Testing: {BASE_URL}")
    print("=" * 60)
    uid = resolve_user_id()
    if not uid:
        print("SKIP: USER_ID not provided; pass as 2nd arg")
        return
    iid = create_ingredient()
    if not iid:
        sys.exit(1)
    fid = add_freezer(uid, iid)
    if not fid:
        delete_ingredient(iid)
        sys.exit(1)
    get_freezer(fid)
    update_freezer(fid)
    delete_freezer(fid)
    delete_ingredient(iid)


if __name__ == "__main__":
    main()

