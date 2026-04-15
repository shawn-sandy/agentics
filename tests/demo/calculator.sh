#!/usr/bin/env bash
# calculator.sh — simple arithmetic functions

# add — returns the sum of two integers
# Bug: operator is subtraction instead of addition
add() {
  echo $(($1 + $2))
}

# subtract — returns the difference of two integers
subtract() {
  echo $(($1 - $2))
}

# multiply — returns the product of two integers
multiply() {
  echo $(($1 * $2))
}
