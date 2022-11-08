#!/bin/bash
# powerball_num_gen.sh - A script to quickly generate PowerBall numbers
# Run: ./powerball_num_gen.sh [option]
# Author: Max Vuong
# Date: 11/07/2021

GENERATION_TIMES=10
MAX_REGULAR_NUMBER=5

SELECTED_NUMBERS=(61 63 20 10 16 26 17 54 41 32 8 15 42 23 40 36 39 22 45 28 27 19 69 35 60 55 34 11 14 6 2 9 7 50 38)
SELECTED_PB_NUMBERS=(8 17 21 3 12 19 2 4 9 7 1 14 22 26)

MAX_PB_NUMBER=1

echo "Generating numbers from quick pick:"

for (( i=0 ; i<$GENERATION_TIMES ; i++ ));
do
  numbers=();
  number_count=0

  while [ $number_count -lt $MAX_REGULAR_NUMBER ]
  do
    number=$(( $RANDOM % 69 + 1 ))

    if [ $((numbers[$number])) -ne $number ]; then
      numbers[$number]=$number
      ((number_count=number_count + 1))
    fi
  done

  powerball_number=$(( $RANDOM % 26 + 1 ))

  numbers+=($powerball_number)
  echo ${numbers[*]}
done


echo "Generating numbers from selected list:"


selected_numbers=()
selected_pb_numbers=()

for number in "${SELECTED_NUMBERS[@]}"
do
  selected_numbers[${number}]=${number}  
done

for number in "${SELECTED_PB_NUMBERS[@]}"
do
  selected_pb_numbers[${number}]=${number}  
done

echo "Selected number list: ${selected_numbers[*]}"
echo "Selected PB number list: ${selected_pb_numbers[*]}"

for (( i=0 ; i<$GENERATION_TIMES ; i++ ));
do
  numbers=();
  number_count=0

  while [ $number_count -lt $MAX_REGULAR_NUMBER ]
  do
    number=$(( $RANDOM % 69 + 1 ))

    if [ $((selected_numbers[$number])) -eq $number ]; then
      if [ $((numbers[$number])) -ne $number ]; then
        numbers[$number]=$number
        ((number_count=number_count + 1))
      fi
    fi
  done

  # Generate PB number
  pb_number_count=0

  while [ $pb_number_count -lt $MAX_PB_NUMBER ]
  do
    powerball_number=$(( $RANDOM % 26 + 1 ))

    if [ $((selected_pb_numbers[$powerball_number])) -eq $powerball_number ]; then
      numbers+=($powerball_number)
      ((pb_number_count=pb_number_count + 1))
    fi
  done

  # Output
  echo ${numbers[*]}
done