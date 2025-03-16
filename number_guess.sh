#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

# Create database and table if they don't exist
psql --username=freecodecamp --dbname=postgres <<EOSQL
CREATE DATABASE number_guess;
EOSQL

psql --username=freecodecamp --dbname=number_guess <<EOSQL
CREATE TABLE IF NOT EXISTS users (
  user_id SERIAL PRIMARY KEY,
  username VARCHAR(22) UNIQUE NOT NULL,
  games_played INT DEFAULT 0,
  best_game INT DEFAULT NULL
);
EOSQL

# Ask for username
echo "Enter your username:"
read USERNAME

# Check if user exists
USER_DATA=$($PSQL "SELECT user_id, games_played, best_game FROM users WHERE username='$USERNAME'")

if [[ -z "$USER_DATA" ]]; then
  echo "Welcome, $USERNAME! It looks like this is your first time here."
  $PSQL "INSERT INTO users(username) VALUES('$USERNAME')"
  USER_ID=$($PSQL "SELECT user_id FROM users WHERE username='$USERNAME'")
  GAMES_PLAYED=0
  BEST_GAME=NULL
else
  IFS='|' read USER_ID GAMES_PLAYED BEST_GAME <<< "$USER_DATA"
  echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
fi

# Generate random number
SECRET_NUMBER=$(( RANDOM % 1000 + 1 ))
TRIES=0

# Start game
echo "Guess the secret number between 1 and 1000:"
while true; do
  read GUESS
  ((TRIES++))

  # Validate input
  if ! [[ "$GUESS" =~ ^[0-9]+$ ]]; then
    echo "That is not an integer, guess again:"
    continue
  fi

  # Compare guess with secret number
  if (( GUESS < SECRET_NUMBER )); then
    echo "It's higher than that, guess again:"
  elif (( GUESS > SECRET_NUMBER )); then
    echo "It's lower than that, guess again:"
  else
    echo "You guessed it in $TRIES tries. The secret number was $SECRET_NUMBER. Nice job!"
    break
  fi
done

# Update database
NEW_GAMES_PLAYED=$((GAMES_PLAYED + 1))
$PSQL "UPDATE users SET games_played=$NEW_GAMES_PLAYED WHERE user_id=$USER_ID"

if [[ -z "$BEST_GAME" || TRIES -lt BEST_GAME ]]; then
  $PSQL "UPDATE users SET best_game=$TRIES WHERE user_id=$USER_ID"
fi
