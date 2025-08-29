#!/bin/bash
# Генерация документации API

echo "📚 Генерация документации Food API..."
echo "====================================="

# Генерация OpenAPI JSON
echo "Генерация OpenAPI JSON..."
dart pub run conduit:conduit document --host https://foodapi.dzolotov.pro

if [ $? -eq 0 ]; then
    echo "✅ openapi.json создан успешно"
else
    echo "❌ Ошибка при генерации OpenAPI"
    exit 1
fi

# Генерация HTML документации
echo ""
echo "Генерация HTML документации..."
dart pub run conduit:conduit document --host https://foodapi.dzolotov.pro --format html --output api_docs.html

if [ $? -eq 0 ]; then
    echo "✅ api_docs.html создан успешно"
    echo ""
    echo "Документация доступна:"
    echo "  - OpenAPI JSON: openapi.json"
    echo "  - HTML: api_docs.html"
else
    echo "❌ Ошибка при генерации HTML"
fi