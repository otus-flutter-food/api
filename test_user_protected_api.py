#!/usr/bin/env python3
"""
Проверка защищенных эндпоинтов с Bearer токеном:
- /user/profile GET/PUT, /user/profile/logout
- /user/favorites add/list/delete
- /user/comments create/list
"""

import sys
import time
import requests

BASE_URL = sys.argv[1] if len(sys.argv) > 1 else "https://foodapi.dzolotov.pro"


def log(name: str, ok: bool, msg: str = ""):
    print(f"{'✅ PASS' if ok else '❌ FAIL'} | {name}{(' | ' + msg) if msg else ''}")


def register_and_auth():
    login = f"prot_{int(time.time())}@example.com"
    password = "pass123"
    r = requests.post(f"{BASE_URL}/user", json={"login": login, "password": password})
    ok_reg = r.status_code == 200
    log("REGISTER (protected)", ok_reg)
    ra = requests.put(f"{BASE_URL}/user", json={"login": login, "password": password})
    ok_auth = ra.status_code == 200 and ra.json().get("token")
    token = ra.json().get("token") if ok_auth else None
    log("AUTH (protected)", ok_auth)
    return token


def auth_headers(token: str):
    return {"Authorization": f"Bearer {token}"}


def profile_get(token: str):
    r = requests.get(f"{BASE_URL}/user/profile", headers=auth_headers(token))
    ok = r.status_code == 200 and r.json().get("id")
    log("GET /user/profile", ok)
    return ok


def profile_put(token: str):
    r = requests.put(f"{BASE_URL}/user/profile", headers=auth_headers(token), json={"firstName": "Test"})
    ok = r.status_code == 200 and r.json().get("firstName") == "Test"
    log("PUT /user/profile", ok)
    return ok


def make_recipe() -> int | None:
    r = requests.post(f"{BASE_URL}/recipe", json={"name": f"Prot Recipe {int(time.time())}", "duration": 300})
    return r.json().get("id") if r.status_code == 200 else None


def favorites_flow(token: str, rid: int):
    r = requests.post(f"{BASE_URL}/user/favorites/{rid}", headers=auth_headers(token))
    ok_add = r.status_code == 200
    log("POST /user/favorites/{rid}", ok_add)
    r = requests.get(f"{BASE_URL}/user/favorites", headers=auth_headers(token))
    ok_list = r.status_code == 200 and isinstance(r.json(), list)
    log("GET /user/favorites", ok_list)
    r = requests.delete(f"{BASE_URL}/user/favorites/{rid}", headers=auth_headers(token))
    ok_del = r.status_code == 200
    log("DELETE /user/favorites/{rid}", ok_del)


def comments_flow(token: str, rid: int):
    r = requests.post(f"{BASE_URL}/user/comments", headers=auth_headers(token), json={"recipeId": rid, "text": "Nice"})
    ok_create = r.status_code == 200 and r.json().get("id")
    log("POST /user/comments", ok_create)
    r = requests.get(f"{BASE_URL}/user/comments", headers=auth_headers(token))
    ok_list = r.status_code == 200 and isinstance(r.json(), list)
    log("GET /user/comments", ok_list)


def logout(token: str):
    r = requests.post(f"{BASE_URL}/user/profile/logout", headers=auth_headers(token))
    ok = r.status_code == 200
    log("POST /user/profile/logout", ok)


def main():
    token = register_and_auth()
    if not token:
        sys.exit(1)
    profile_get(token)
    profile_put(token)
    rid = make_recipe()
    if rid:
        favorites_flow(token, rid)
        comments_flow(token, rid)
        requests.delete(f"{BASE_URL}/recipe/{rid}")
    logout(token)


if __name__ == "__main__":
    main()
