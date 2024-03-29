# sudo apt-get install python3-tk
# pip install pytk

from turtle import *
import re
import os

file = "turtle"

if os.path.exists(file):
    with open(file, "r") as f:
        for line in f:
            match = re.search("Avance|Recule|Tourne gauche|Tourne droite", line)

            if match:
                # Remove all non-numbers from the line and convert it to int
                only_numbers = int(re.sub("[^0-9]", "", line))
                # Get the command from the line
                command = match.group()

                # Execute the command
                if command == "Avance":
                    forward(only_numbers)
                elif command == "Recule":
                    backward(only_numbers)
                elif command == "Tourne gauche":
                    left(only_numbers)
                else:
                    right(only_numbers)
            else:
                # Wait until the user presses Enter
                input("Press Enter to continue...")

                clearscreen()
                home()
else:
    print("File not found: ", file)
    exit(1)
exit(0)