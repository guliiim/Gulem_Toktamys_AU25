import os
from pathlib import Path
from random import seed, choice
from typing import List, Union
from collections import Counter
import requests
from requests import RequestException


S5_PATH = Path(os.path.realpath(__file__)).parent

PATH_TO_NAMES = S5_PATH / "names.txt"
PATH_TO_SURNAMES = S5_PATH / "last_names.txt"
PATH_TO_OUTPUT = S5_PATH / "sorted_names_and_surnames.txt"
PATH_TO_TEXT = S5_PATH / "random_text.txt"
PATH_TO_STOP_WORDS = S5_PATH / "stop_words.txt"


def task_1():
    seed(1)
    with open(PATH_TO_NAMES, "r", encoding="utf-8") as f:
        names = [line.strip().lower() for line in f if line.strip()]

    with open(PATH_TO_SURNAMES, "r", encoding="utf-8") as f:
        surnames = [line.strip().lower() for line in f if line.strip()]

    names.sort()

    with open(PATH_TO_OUTPUT, "w", encoding="utf-8") as f:
        for name in names:
            surname = choice(surnames)
            f.write(f"{name} {surname}\n")


def task_2(top_k: int):
    with open(PATH_TO_STOP_WORDS, "r") as f:
        stop_words = {line.strip().lower() for line in f if line.strip()}

    with open(PATH_TO_TEXT, "r") as f:
        text = f.read().lower()

    cleaned_text = "".join(char if char.isalpha() else " " for char in text)

    words = [
        word for word in cleaned_text.split() if word not in stop_words
    ]

    counter = Counter(words)

    return counter.most_common(top_k)


def task_3(url: str):
    try:
        response = requests.get(url)
        response.raise_for_status()
        if response.status_code == 200:
            return response
        else:
            return response
    except RequestException:
        raise RequestException


def task_4(data: List[Union[int, str, float]]):
    total = 0
    for item in data:
        try:
            total += item
        except TypeError:
            total += float(item)
    return total


def task_5():
    try:
        a, b = input().split()
        a = float(a)
        b = float(b)
        result = a / b
        print(result)
    except ZeroDivisionError:
        print("Can't divide by zero")
    except ValueError:
        print("Entered value is wrong")
