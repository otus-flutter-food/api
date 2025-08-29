#!/usr/bin/env python3
"""
Автотесты для связей шагов и рецептов
Создаёт рецепт и шаг, линкует их, проверяет выборки и удаляет.
"""

import sys
import time
from typing import Optional
import requests

BASE_URL = sys.argv[1] if len(sys.argv) > 1 else "http://localhost:8888"


def log(name: str, ok: bool, msg: str = ""):
    status = "✅ PASS" if ok else "❌ FAIL"
    print(f"{status} | {name}{(' | ' + msg) if msg else ''}")


def create_recipe() -> Optional[int]:
    name = f"StepLink Test Recipe {int(time.time())}"
    r = requests.post(f"{BASE_URL}/recipe", json={
        "name": name,
        "duration": 600,
        "photo": "https://example.com/r.jpg"
    })
    if r.status_code == 200 and r.json().get("id"):
        rid = r.json()["id"]
        log("CREATE Recipe", True, f"id={rid}")
        return rid
    log("CREATE Recipe", False, f"status={r.status_code} body={r.text}")
    return None


def create_step() -> Optional[int]:
    name = f"StepLink Test Step {int(time.time())}"
    r = requests.post(f"{BASE_URL}/steps", json={
        "name": name,
        "duration": 60
    })
    if r.status_code == 200 and r.json().get("id"):
        sid = r.json()["id"]
        log("CREATE Step", True, f"id={sid}")
        return sid
    log("CREATE Step", False, f"status={r.status_code} body={r.text}")
    return None

def get_steps_list() -> bool:
    r = requests.get(f"{BASE_URL}/steps")
    ok = r.status_code == 200 and isinstance(r.json(), list)
    log("GET Steps List", ok)
    return ok

def get_step_by_id(step_id: int) -> bool:
    r = requests.get(f"{BASE_URL}/steps/{step_id}")
    ok = r.status_code == 200 and r.json().get("id") == step_id
    log("GET Step by ID", ok)
    return ok


def create_link(recipe_id: int, step_id: int) -> Optional[int]:
    r = requests.post(f"{BASE_URL}/recipe-step-links", json={
        "recipeId": recipe_id,
        "stepId": step_id,
        "number": 1
    })
    if r.status_code == 200 and r.json().get("id"):
        lid = r.json()["id"]
        log("CREATE Link", True, f"id={lid}")
        return lid
    log("CREATE Link", False, f"status={r.status_code} body={r.text}")
    return None


def get_links_for_recipe(recipe_id: int) -> bool:
    r = requests.get(f"{BASE_URL}/recipe-step-links/recipe/{recipe_id}")
    ok = r.status_code == 200 and isinstance(r.json(), list)
    log("GET Links For Recipe", ok, f"count={len(r.json()) if ok else '?'}")
    return ok


def update_link(link_id: int) -> bool:
    r = requests.put(f"{BASE_URL}/recipe-step-links/{link_id}", json={"number": 2})
    ok = r.status_code == 200 and r.json().get("number") == 2
    log("UPDATE Link", ok)
    return ok


def delete_link(link_id: int) -> bool:
    r = requests.delete(f"{BASE_URL}/recipe-step-links/{link_id}")
    ok = r.status_code == 200
    log("DELETE Link", ok)
    return ok


def delete_step(step_id: int) -> bool:
    r = requests.delete(f"{BASE_URL}/steps/{step_id}")
    ok = r.status_code == 200
    log("DELETE Step", ok)
    return ok


def delete_recipe(recipe_id: int) -> bool:
    r = requests.delete(f"{BASE_URL}/recipe/{recipe_id}")
    ok = r.status_code == 200
    log("DELETE Recipe", ok)
    return ok


def main():
    print("=" * 60)
    print("🧪 RECIPE-STEP-LINKS TESTS")
    print(f"📍 Testing: {BASE_URL}")
    print("=" * 60)

    rid = create_recipe()
    sid = create_step()
    if not (rid and sid):
        sys.exit(1)

    # sanity list
    get_steps_list()
    get_step_by_id(sid)

    lid = create_link(rid, sid)
    if lid is None:
        delete_step(sid)
        delete_recipe(rid)
        sys.exit(1)

    get_links_for_recipe(rid)
    update_link(lid)
    delete_link(lid)

    # cleanup
    delete_step(sid)
    delete_recipe(rid)


if __name__ == "__main__":
    main()
