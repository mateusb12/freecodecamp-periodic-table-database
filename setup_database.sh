#!/bin/bash

# PSQL command to interact with the database
PSQL="psql --username=freecodecamp --dbname=periodic_table -t --no-align -c"

# Check if the necessary columns exist before altering them
if [[ $($PSQL "\d properties" | grep -c "atomic_mass") -eq 0 ]]; then
  if [[ $($PSQL "\d properties" | grep -c "weight") -gt 0 ]]; then
    $PSQL "ALTER TABLE properties RENAME COLUMN weight TO atomic_mass;"
  fi
fi

if [[ $($PSQL "\d properties" | grep -c "melting_point_celsius") -eq 0 ]]; then
  if [[ $($PSQL "\d properties" | grep -c "melting_point") -gt 0 ]]; then
    $PSQL "ALTER TABLE properties RENAME COLUMN melting_point TO melting_point_celsius;"
  fi
fi

if [[ $($PSQL "\d properties" | grep -c "boiling_point_celsius") -eq 0 ]]; then
  if [[ $($PSQL "\d properties" | grep -c "boiling_point") -gt 0 ]]; then
    $PSQL "ALTER TABLE properties RENAME COLUMN boiling_point TO boiling_point_celsius;"
  fi
fi

# Adding NOT NULL constraints if they don't exist
if [[ $($PSQL "\d properties" | grep "melting_point_celsius" | grep -c "not null") -eq 0 ]]; then
  $PSQL "ALTER TABLE properties ALTER COLUMN melting_point_celsius SET NOT NULL;"
fi

if [[ $($PSQL "\d properties" | grep "boiling_point_celsius" | grep -c "not null") -eq 0 ]]; then
  $PSQL "ALTER TABLE properties ALTER COLUMN boiling_point_celsius SET NOT NULL;"
fi

# Adding UNIQUE constraints if they don't exist
if [[ $($PSQL "\d elements" | grep -c "unique_symbol") -eq 0 ]]; then
  $PSQL "ALTER TABLE elements ADD CONSTRAINT unique_symbol UNIQUE (symbol);"
fi

if [[ $($PSQL "\d elements" | grep -c "unique_name") -eq 0 ]]; then
  $PSQL "ALTER TABLE elements ADD CONSTRAINT unique_name UNIQUE (name);"
fi

# Adding NOT NULL constraints if they don't exist
if [[ $($PSQL "\d elements" | grep "symbol" | grep -c "not null") -eq 0 ]]; then
  $PSQL "ALTER TABLE elements ALTER COLUMN symbol SET NOT NULL;"
fi

if [[ $($PSQL "\d elements" | grep "name" | grep -c "not null") -eq 0 ]]; then
  $PSQL "ALTER TABLE elements ALTER COLUMN name SET NOT NULL;"
fi

# Adding foreign key if it doesn't exist
if [[ $($PSQL "SELECT conname FROM pg_constraint WHERE conname='fk_atomic_number';" | wc -l) -eq 0 ]]; then
  $PSQL "ALTER TABLE properties ADD CONSTRAINT fk_atomic_number FOREIGN KEY (atomic_number) REFERENCES elements (atomic_number);"
fi

# Creating types table if it doesn't exist
$PSQL "CREATE TABLE IF NOT EXISTS types (
  type_id SERIAL PRIMARY KEY,
  type VARCHAR NOT NULL
);"

# Inserting rows into types table if they don't exist
if [[ $($PSQL "SELECT COUNT(*) FROM types;" | xargs) -eq 0 ]]; then
  $PSQL "INSERT INTO types (type) VALUES ('metal'), ('nonmetal'), ('metalloid');"
fi

# Adding type_id column to properties table if it doesn't exist
if [[ $($PSQL "\d properties" | grep -c "type_id") -eq 0 ]]; then
  $PSQL "ALTER TABLE properties ADD COLUMN type_id INT NOT NULL DEFAULT 1;"
fi

# Adding foreign key constraint to properties table if it doesn't exist
if [[ $($PSQL "SELECT conname FROM pg_constraint WHERE conname='fk_type_id';" | wc -l) -eq 0 ]]; then
  $PSQL "ALTER TABLE properties ADD CONSTRAINT fk_type_id FOREIGN KEY (type_id) REFERENCES types (type_id);"
fi

# Ensuring symbol values are capitalized in elements table
$PSQL "UPDATE elements SET symbol = INITCAP(symbol);"

# Adding elements with atomic numbers 9 and 10 if they don't exist
if [[ $($PSQL "SELECT COUNT(*) FROM elements WHERE atomic_number=9;" | xargs) -eq 0 ]]; then
  $PSQL "INSERT INTO elements (atomic_number, name, symbol) VALUES (9, 'Fluorine', 'F');"
  $PSQL "INSERT INTO properties (atomic_number, atomic_mass, melting_point_celsius, boiling_point_celsius, type_id) VALUES (9, 18.998, -220, -188.1, (SELECT type_id FROM types WHERE type='nonmetal'));"
fi

if [[ $($PSQL "SELECT COUNT(*) FROM elements WHERE atomic_number=10;" | xargs) -eq 0 ]]; then
  $PSQL "INSERT INTO elements (atomic_number, name, symbol) VALUES (10, 'Neon', 'Ne');"
  $PSQL "INSERT INTO properties (atomic_number, atomic_mass, melting_point_celsius, boiling_point_celsius, type_id) VALUES (10, 20.18, -248.6, -246.1, (SELECT type_id FROM types WHERE type='nonmetal'));"
fi

# Updating atomic_mass from atomic_mass.txt
while IFS="|" read -r atomic_number atomic_mass
do
  atomic_number=$(echo $atomic_number | xargs)
  atomic_mass=$(echo $atomic_mass | xargs)
  $PSQL "UPDATE properties SET atomic_mass=$atomic_mass WHERE atomic_number=$atomic_number;"
done < atomic_mass.txt

# Debug: Print atomic masses before and after stripping trailing zeros
echo "Atomic masses before removing trailing zeros:"
$PSQL "SELECT atomic_number, atomic_mass FROM properties;" | while IFS="|" read -r atomic_number atomic_mass; do
  echo "Atomic number: $atomic_number, Atomic mass: $atomic_mass"
done

# Convert atomic_mass to DECIMAL, strip trailing zeros
$PSQL "ALTER TABLE properties ALTER COLUMN atomic_mass TYPE DECIMAL;"
$PSQL "UPDATE properties SET atomic_mass = TRIM(TRAILING '.' FROM TRIM(TRAILING '0' FROM atomic_mass::TEXT))::DECIMAL;"

# Debug: Print atomic masses after removing trailing zeros
echo "Atomic masses after removing trailing zeros:"
$PSQL "SELECT atomic_number, atomic_mass FROM properties;" | while IFS="|" read -r atomic_number atomic_mass; do
  echo "Atomic number: $atomic_number, Atomic mass: $atomic_mass"
done

# Get a list of all tables
TABLES=$($PSQL "SELECT tablename FROM pg_tables WHERE schemaname='public'")

# Loop through each table and print its contents
for TABLE in $TABLES; do
  echo "Contents of table: $TABLE"
  $PSQL "SELECT * FROM $TABLE"
  echo ""
done
