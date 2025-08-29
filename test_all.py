#!/usr/bin/env python3
import argparse
import subprocess
import sys


def run_cmd(cmd):
    p = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
    out = p.stdout
    print(out)
    failed = (p.returncode != 0) or ('❌ FAIL' in out)
    return (not failed), out


def main():
    ap = argparse.ArgumentParser(description='Run API integration tests')
    ap.add_argument('base_url', nargs='?', default='http://localhost:8888')
    ap.add_argument('--user-id', type=int, help='Existing user id for favorites/comments/freezer tests')
    args = ap.parse_args()

    base = args.base_url
    uid = args.user_id

    jobs = [
        ['python3', 'test_user_api.py', base],
        ['python3', 'test_recipe_api.py', base],
        ['python3', 'test_recipe_ingredients_api.py', base],
        ['python3', 'test_step_links_api.py', base],
        ['python3', 'test_ingredients_api.py', base],
    ]
    if uid:
        jobs += [
            ['python3', 'test_favorites_api.py', base, str(uid)],
            ['python3', 'test_comments_api.py', base, str(uid)],
            ['python3', 'test_freezer_api.py', base, str(uid)],
        ]
    # Always include protected flow (creates own user and token)
    jobs.append(['python3', 'test_user_protected_api.py', base])

    total = 0
    passed = 0
    for cmd in jobs:
        print('=' * 60)
        print('RUN', ' '.join(cmd))
        ok, _ = run_cmd(cmd)
        total += 1
        passed += 1 if ok else 0

    print('\n' + '=' * 60)
    print(f'SUMMARY: {passed}/{total} suites passed')
    sys.exit(0 if passed == total else 1)


if __name__ == '__main__':
    main()
