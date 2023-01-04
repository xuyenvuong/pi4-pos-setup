#!/bin/bash
# powerball_num_gen.sh - A script to quickly generate PowerBall numbers
# Run: bash powerball_num_gen.sh [option]
# Author: Max Vuong
# Date: 11/07/2021

# How many rows?
echo -n "Enter the number of quick-picks (1-100): "
read userinput

if [[ $userinput -lt 0 || $userinput -gt 100 ]]; then
  echo "Input outside acceptable range. Terminate script."
  exit 1
fi

# How many rows for selected numbers?
echo -n "Enter the number of quick-picks from the SELECTED NUMBERS (1-100): "
read userinputselected

if [[ $userinputselected -lt 0 || $userinputselected -gt 100 ]]; then
  echo "Input outside acceptable range. Terminate script."
  exit 1
fi

# Power ball number format
MAX_REGULAR_NUMBER=5
SELECTED_NUMBERS=(61 63 20 10 16 26 17 54 41 32 8 15 42 23 40 36 39 22 45 28 27 19 69 35 60 55 34 11 14 6 2 9 7 50 38)
SELECTED_SPECIAL_NUMBERS=(8 17 21 3 12 19 2 4 9 7 1 14 22 26)

MAX_SPECIAL_NUMBER=1

# Row count
row_num=1

# Output format
bold=`tput bold`
normal=`tput sgr0`

echo "----------------------------------------------------------------"
echo "Generating PowerBall numbers from quick pick:"
echo "----------------------------------------------------------------"

for (( i=0 ; i<$userinput ; i++ ));
do
  numbers=();
  number_count=0

  while [ $number_count -lt $MAX_REGULAR_NUMBER ]
  do
    number=$(( $RANDOM % 69 + 1 ))

    if [ $((numbers[$number])) -ne $number ]; then
      if [ $number -lt 10 ]; then
        numbers[$number]=" $number"
      else
        numbers[$number]="$number"
      fi
      
      ((number_count=number_count + 1))
    fi
  done

  special_number=$(( $RANDOM % 26 + 1 ))

  if [ $special_number -lt 10 ]; then
    numbers+=("PB:  ${bold}$special_number${normal}")
  else
    numbers+=("PB: ${bold}$special_number${normal}")
  fi

  if [ $row_num -lt 10 ]; then
    echo "$row_num)  ${numbers[*]}"
  else
    echo "$row_num) ${numbers[*]}"
  fi

  ((row_num=row_num + 1))
done

# ----------------------------------------------------------------
echo "----------------------------------------------------------------"

echo "Generating PowerBall numbers from selected list:"
# ----------------------------------------------------------------
selected_numbers=()
selected_special_numbers=()

row_num=1

for number in "${SELECTED_NUMBERS[@]}"
do
  selected_numbers[${number}]=${number}  
done

for number in "${SELECTED_SPECIAL_NUMBERS[@]}"
do
  selected_special_numbers[${number}]=${number}  
done

# ----------------------------------------------------------------
echo "----------------------------------------------------------------"
echo "Selected number list: ${selected_numbers[*]}"
echo "Selected PB number list: ${selected_special_numbers[*]}"

echo "Generating PowerBall numbers from selected list:"
echo "----------------------------------------------------------------"

for (( i=0 ; i<$userinputselected ; i++ ));
do
  numbers=();
  number_count=0

  while [ $number_count -lt $MAX_REGULAR_NUMBER ]
  do
    number=$(( $RANDOM % 69 + 1 ))

    if [ $((selected_numbers[$number])) -eq $number ]; then
      if [ $((numbers[$number])) -ne $number ]; then
        if [ $number -lt 10 ]; then
          numbers[$number]=" $number"
        else
          numbers[$number]="$number"
        fi

        ((number_count=number_count + 1))
      fi
    fi
  done

  # Generate special number
  special_number_count=0

  while [ $special_number_count -lt $MAX_SPECIAL_NUMBER ]
  do
    special_number=$(( $RANDOM % 26 + 1 ))

    if [ $((selected_special_numbers[$special_number])) -eq $special_number ]; then
      if [ $special_number -lt 10 ]; then
        numbers+=("PB:  ${bold}$special_number${normal}")
      else
        numbers+=("PB: ${bold}$special_number${normal}")
      fi
      ((special_number_count=special_number_count + 1))
    fi
  done

  # Output
  if [ $row_num -lt 10 ]; then
    echo "$row_num)  ${numbers[*]}"
  else
    echo "$row_num) ${numbers[*]}"
  fi

  ((row_num=row_num + 1))
done