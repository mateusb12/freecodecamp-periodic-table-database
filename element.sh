#!/bin/bash

# PSQL command to interact with the database
PSQL="psql --username=freecodecamp --dbname=periodic_table -t --no-align -c"

# Function to fetch and display element information
fetch_element_info() {
  local INPUT=$1
  local QUERY

  # Check if the input is a number (atomic number) or a string (symbol or name)
  if [[ $INPUT =~ ^[0-9]+$ ]]; then
    QUERY="SELECT elements.atomic_number, elements.name, elements.symbol, types.type, properties.atomic_mass, properties.melting_point_celsius, properties.boiling_point_celsius
           FROM elements
           INNER JOIN properties USING(atomic_number)
           INNER JOIN types ON properties.type_id = types.type_id
           WHERE elements.atomic_number=$INPUT"
  else
    QUERY="SELECT elements.atomic_number, elements.name, elements.symbol, types.type, properties.atomic_mass, properties.melting_point_celsius, properties.boiling_point_celsius
           FROM elements
           INNER JOIN properties USING(atomic_number)
           INNER JOIN types ON properties.type_id = types.type_id
           WHERE elements.symbol='$INPUT' OR elements.name='$INPUT'"
  fi

  local QUERY_RESULT=$($PSQL "$QUERY")

  if [[ -z $QUERY_RESULT ]]; then
    echo "I could not find that element in the database."
  else
    echo "$QUERY_RESULT" | while IFS="|" read ATOMIC_NUMBER NAME SYMBOL TYPE ATOMIC_MASS MELTING_POINT BOILING_POINT; do
      echo "The element with atomic number $ATOMIC_NUMBER is $NAME ($SYMBOL). It's a $TYPE, with a mass of $ATOMIC_MASS amu. $NAME has a melting point of $MELTING_POINT celsius and a boiling point of $BOILING_POINT celsius."
    done
  fi
}

# Check if argument is provided
if [[ -z $1 ]]; then
  echo "Please provide an element as an argument."
  exit 0
fi

# Fetch element information based on the input
fetch_element_info "$1"
