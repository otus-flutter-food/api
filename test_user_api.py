#!/usr/bin/env python3
"""
Интеграционные тесты для логина/регистрации пользователя.
Проверяет: регистрация, повторная регистрация (409), вход (200), неверный пароль (403), чтение профиля.
"""

import sys
import time
import re
import requests

BASE_URL = sys.argv[1] if len(sys.argv) > 1 else "http://localhost:8888"


def log(name: str, ok: bool, msg: str = ""):
    print(f"{'✅ PASS' if ok else '❌ FAIL'} | {name}{(' | ' + msg) if msg else ''}")


def register(login: str, password: str):
    r = requests.post(f"{BASE_URL}/user", json={"login": login, "password": password})
    ok = r.status_code == 200 and r.json().get("user", {}).get("id") is not None
    if ok:
        uid = r.json()["user"]["id"]
        log("REGISTER", True, f"id={uid}")
        return uid
    log("REGISTER", False, f"status={r.status_code} body={r.text}")
    return None


def register_duplicate(login: str, password: str):
    r = requests.post(f"{BASE_URL}/user", json={"login": login, "password": password})
    ok = r.status_code == 409
    log("REGISTER duplicate", ok)
    return ok


def auth_ok(login: str, password: str):
    r = requests.put(f"{BASE_URL}/user", json={"login": login, "password": password})
    ok = r.status_code == 200 and isinstance(r.json().get("token"), str)
    log("AUTH ok", ok, (r.json().get("token") if ok else f"status={r.status_code}"))
    return ok


def auth_bad(login: str, wrong_password: str):
    r = requests.put(f"{BASE_URL}/user", json={"login": login, "password": wrong_password})
    ok = r.status_code == 403
    log("AUTH wrong password", ok)
    return ok


def get_user(uid: int, expected_login: str):
    r = requests.get(f"{BASE_URL}/user/{uid}")
    ok = r.status_code == 200 and r.json().get("id") == uid and r.json().get("login") == expected_login
    log("GET /user/{id}", ok)
    return ok


def main():
    print("=" * 60)
    print("🧪 USER LOGIN TESTS")
    print(f"📍 Testing: {BASE_URL}")
    print("=" * 60)

    login = f"user_{int(time.time())}@example.com"
    password = "pass123"

    uid = register(login, password)
    if not uid:
        sys.exit(1)

    register_duplicate(login, password)
    auth_ok(login, password)
    auth_bad(login, password + "X")
    get_user(uid, login)


if __name__ == "__main__":
    main()

