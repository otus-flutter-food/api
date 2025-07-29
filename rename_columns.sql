-- Rename camelCase columns to snake_case
ALTER TABLE _comment RENAME COLUMN "dateTime" TO date_time;
ALTER TABLE _ingredient RENAME COLUMN "caloriesForUnit" TO calories_for_unit;
ALTER TABLE _ingredient RENAME COLUMN "measureUnit_id" TO measure_unit_id;
ALTER TABLE _user RENAME COLUMN "avatarUrl" TO avatar_url;
ALTER TABLE _user RENAME COLUMN "firstName" TO first_name;
ALTER TABLE _user RENAME COLUMN "lastName" TO last_name;