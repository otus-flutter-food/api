#!/usr/bin/env bash
set -euo pipefail

# Demo script: creates a recipe, a new ingredient, links them,
# adds several steps and comments, then swaps steps 1 and 2.
#
# Usage:
#   scripts/demo_recipe_flow.sh [BASE_URL] [USER_ID]
#
# Defaults:
#   BASE_URL: http://localhost:8888
#   USER_ID: 1 (must exist in DB for comments)

BASE_URL=${1:-http://localhost:8888}
USER_ID=${2:-1}

require_tool() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Error: $1 is required. Please install it and retry." >&2
    exit 1
  }
}

require_tool curl
require_tool jq

post() {
  local path="$1"; shift
  local data="$1"; shift || true
  curl -sS -H 'Content-Type: application/json' -d "$data" "$BASE_URL$path"
}

get() {
  local path="$1"; shift
  curl -sS "$BASE_URL$path"
}

echo "Using BASE_URL=$BASE_URL, USER_ID=$USER_ID"

ts=$(date +%s)

echo "== Create recipe"
recipe_json=$(post "/recipe" "{\
  \"name\": \"Demo Recipe $ts\",\
  \"duration\": 1800,\
  \"photo\": \"https://example.com/recipe.jpg\"\
}")
echo "$recipe_json" | jq . >/dev/null
RECIPE_ID=$(echo "$recipe_json" | jq -r .id)
echo "Recipe ID: $RECIPE_ID"

echo "== Create ingredient"
ing_json=$(post "/ingredient" "{\
  \"name\": \"Demo Ingredient $ts\",\
  \"caloriesForUnit\": 1.5\
}")
echo "$ing_json" | jq . >/dev/null
INGREDIENT_ID=$(echo "$ing_json" | jq -r .id)
echo "Ingredient ID: $INGREDIENT_ID"

echo "== Link ingredient to recipe"
ri_json=$(post "/recipe-ingredients" "{\
  \"recipe\": {\"id\": $RECIPE_ID},\
  \"ingredient\": {\"id\": $INGREDIENT_ID},\
  \"count\": 500\
}")
echo "$ri_json" | jq . >/dev/null
RI_ID=$(echo "$ri_json" | jq -r .id)
echo "RecipeIngredient ID: $RI_ID"

echo "== Create steps"
step1_json=$(post "/steps" "{\"name\": \"Подготовка ингредиентов\", \"duration\": 300}")
STEP1_ID=$(echo "$step1_json" | jq -r .id)
echo "Step1 ID: $STEP1_ID"

step2_json=$(post "/steps" "{\"name\": \"Смешать и замесить\", \"duration\": 240}")
STEP2_ID=$(echo "$step2_json" | jq -r .id)
echo "Step2 ID: $STEP2_ID"

step3_json=$(post "/steps" "{\"name\": \"Готовка\", \"duration\": 600}")
STEP3_ID=$(echo "$step3_json" | jq -r .id)
echo "Step3 ID: $STEP3_ID"

echo "== Link steps to recipe (numbers 1,2,3)"
link1_json=$(post "/recipe-step-links" "{\
  \"recipe\": {\"id\": $RECIPE_ID},\
  \"step\": {\"id\": $STEP1_ID},\
  \"number\": 1\
}")
LINK1_ID=$(echo "$link1_json" | jq -r .id)
echo "Link1 ID: $LINK1_ID"

link2_json=$(post "/recipe-step-links" "{\
  \"recipe\": {\"id\": $RECIPE_ID},\
  \"step\": {\"id\": $STEP2_ID},\
  \"number\": 2\
}")
LINK2_ID=$(echo "$link2_json" | jq -r .id)
echo "Link2 ID: $LINK2_ID"

link3_json=$(post "/recipe-step-links" "{\
  \"recipe\": {\"id\": $RECIPE_ID},\
  \"step\": {\"id\": $STEP3_ID},\
  \"number\": 3\
}")
LINK3_ID=$(echo "$link3_json" | jq -r .id)
echo "Link3 ID: $LINK3_ID"

echo "== Add comments"
comment1_json=$(post "/comment" "{\
  \"userId\": $USER_ID,\
  \"recipeId\": $RECIPE_ID,\
  \"text\": \"Первый комментарий\"\
}")
COMMENT1_ID=$(echo "$comment1_json" | jq -r .id)
echo "Comment1 ID: $COMMENT1_ID"

comment2_json=$(post "/comment" "{\
  \"userId\": $USER_ID,\
  \"recipeId\": $RECIPE_ID,\
  \"text\": \"Второй комментарий\"\
}")
COMMENT2_ID=$(echo "$comment2_json" | jq -r .id)
echo "Comment2 ID: $COMMENT2_ID"

echo "== Reorder steps: swap numbers of links $LINK1_ID and $LINK2_ID"
reorder_payload=$(cat <<JSON
{\
  "recipeId": $RECIPE_ID,\
  "stepOrders": [\
    {"linkId": $LINK2_ID, "number": 1},\
    {"linkId": $LINK1_ID, "number": 2}\
  ]\
}
JSON
)
post "/recipe-step-links/reorder" "$reorder_payload" >/dev/null

echo "== Final recipe (with steps in order)"
get "/recipe/$RECIPE_ID" | jq '{id, name, steps: (.recipeStepLinks // []) | sort_by(.number) | map({id, number, step: {id: .step.id, name: .step.name}})}'

echo "Done. Created RECIPE_ID=$RECIPE_ID"

