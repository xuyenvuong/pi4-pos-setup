#!/bin/bash
# mega_num_gen.sh - A script to quickly generate Mega numbers
# Run: bash mega_num_gen.sh
# Author: Max Vuong
# Date: 11/08/2021

# How many rows?
echo -n "Enter the number of quick-picks (1-100): "
read userinput

if [[ $userinput -lt 1 || $userinput -gt 100 ]]; then
  echo "Input outside acceptable range. Terminate script."
  exit 1
fi

# Mega pick: 5 regular number 1-70, and a Mega number 1-25
MAX_REGULAR_NUMBER=5
REGULAR_NUMBER_RANGE=70
SPECIAL_NUMBER_RANGE=25

# Row count
row_num=1

# Output format
bold=`tput bold`
normal=`tput sgr0`

echo "Generating MEGA numbers from quick pick:"

for (( i=0 ; i<$userinput ; i++ ));
do
  numbers=();
  number_count=0

  while [ $number_count -lt $MAX_REGULAR_NUMBER ]
  do
    number=$(( $RANDOM % $REGULAR_NUMBER_RANGE + 1 ))

    if [ $((numbers[$number])) -ne $number ]; then
      if [ $number -lt 10 ]; then
        numbers[$number]=" $number"
      else
        numbers[$number]="$number"
      fi

      ((number_count=number_count + 1))
    fi
  done

  mega_number=$(( $RANDOM % $SPECIAL_NUMBER_RANGE + 1 ))

  if [ $mega_number -lt 10 ]; then
    numbers+=("MEGA:  ${bold}$mega_number${normal}")
  else
    numbers+=("MEGA: ${bold}$mega_number${normal}")
  fi

  if [ $row_num -lt 10 ]; then
    echo "$row_num)  ${numbers[*]}"
  else
    echo "$row_num) ${numbers[*]}"
  fi

  ((row_num=row_num + 1))
done