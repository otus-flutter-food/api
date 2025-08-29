#!/bin/bash
# E2E тестирование Food API

echo "🚀 Запуск E2E тестов Food API..."
echo "================================"

# Проверка, что сервер запущен
if ! curl -s https://foodapi.dzolotov.pro/healthz > /dev/null; then
    echo "❌ Сервер не запущен на порту 8888!"
    echo "Запустите сервер командой: dart bin/main.dart"
    exit 1
fi

echo "✅ Сервер доступен"
echo ""

# Запуск всех тестов
echo "📋 Запуск полного набора тестов..."
python3 test_all.py

# Проверка результата
if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Все тесты пройдены успешно!"
else
    echo ""
    echo "❌ Некоторые тесты не прошли"
    exit 1
fi