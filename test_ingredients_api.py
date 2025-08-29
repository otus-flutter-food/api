#!/usr/bin/env python3
"""
Интеграционные тесты для ингредиентов и единиц измерения
"""

import sys
import time
import requests

BASE_URL = sys.argv[1] if len(sys.argv) > 1 else "http://localhost:8888"


def log(name: str, ok: bool, msg: str = ""):
    print(f"{'✅ PASS' if ok else '❌ FAIL'} | {name}{(' | ' + msg) if msg else ''}")


def create_measure_unit():
    name = str(int(time.time()))
    r = requests.post(f"{BASE_URL}/measure_unit", json={
        "one": f"one-{name}",
        "few": f"few-{name}",
        "many": f"many-{name}"
    })
    ok = r.status_code == 200 and r.json().get("id")
    log("CREATE MeasureUnit", ok, f"id={r.json().get('id') if ok else '?'}")
    return r.json().get("id") if ok else None

def list_measure_units():
    r = requests.get(f"{BASE_URL}/measure_unit")
    ok = r.status_code == 200 and isinstance(r.json(), list)
    log("LIST MeasureUnits", ok)
    return ok


def create_ingredient(mu_id: int):
    r = requests.post(f"{BASE_URL}/ingredient", json={
        "name": f"Ing-{int(time.time())}",
        "caloriesForUnit": 1.23,
        "measureUnit": {"id": mu_id}
    })
    ok = r.status_code == 200 and r.json().get("id")
    log("CREATE Ingredient", ok, f"id={r.json().get('id') if ok else '?'}")
    return r.json().get("id") if ok else None


def get_ingredient(iid: int):
    r = requests.get(f"{BASE_URL}/ingredient/{iid}")
    ok = r.status_code == 200 and r.json().get("id") == iid
    log("GET Ingredient", ok)
    return ok


def update_ingredient(iid: int):
    r = requests.put(f"{BASE_URL}/ingredient/{iid}", json={"name": "UpdatedName"})
    ok = r.status_code == 200 and r.json().get("name") == "UpdatedName"
    log("UPDATE Ingredient", ok)
    return ok


def try_delete_measure_unit(mu_id: int):
    r = requests.delete(f"{BASE_URL}/measure_unit/{mu_id}")
    ok = r.status_code == 409
    log("DELETE MeasureUnit (in-use -> conflict)", ok)
    return ok


def delete_ingredient(iid: int):
    r = requests.delete(f"{BASE_URL}/ingredient/{iid}")
    ok = r.status_code == 200
    log("DELETE Ingredient", ok)
    return ok


def delete_measure_unit(mu_id: int):
    r = requests.delete(f"{BASE_URL}/measure_unit/{mu_id}")
    ok = r.status_code == 200
    log("DELETE MeasureUnit", ok)
    return ok


def main():
    print("=" * 60)
    print("🧪 INGREDIENTS + MEASURE UNITS TESTS")
    print(f"📍 Testing: {BASE_URL}")
    print("=" * 60)

    mu = create_measure_unit()
    if not mu:
        sys.exit(1)
    list_measure_units()
    ing = create_ingredient(mu)
    if not ing:
        delete_measure_unit(mu)
        sys.exit(1)
    get_ingredient(ing)
    update_ingredient(ing)
    try_delete_measure_unit(mu)
    delete_ingredient(ing)
    delete_measure_unit(mu)


if __name__ == "__main__":
    main()
