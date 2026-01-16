import time
from typing import List

Matrix = List[List[int]]


def task_1(exp: int):
    def power_factory(num: int) -> int:
        return num ** exp
    return power_factory


def task_2(*args, **kwags):
    for value in args:
        print(value)
    for value in kwags.values():
        print(value)


def helper(func):
    def wrapper(name):
        print("Hi, friend! What's your name?")
        result = func(name)
        print("See you soon!")
        return result
    return wrapper


@helper
def task_3(name: str):
    print(f"Hello! My name is {name}.")


def timer(func):
    def wrapper(*args, **kwargs):
        start_time = time.time()
        result = func(*args, **kwargs)
        end_time = time.time()
        run_time = end_time - start_time
        print(f"Finished {func.__name__} in {run_time:.4f} secs")
        return result
    return wrapper

@timer
def task_4():
    return len([1 for _ in range(0, 10**8)])


def task_5(matrix: Matrix) -> Matrix:
    rows = len(matrix)
    columns = len(matrix[0])

    result = []
    for j in range(columns):
        new_row = []
        for i in range(rows):
            new_row.append(matrix[i][j])
        result.append(new_row)

    return result

def task_6(queue: str):
    balance = 0
    for item in queue:
        if item == '(':
            balance += 1
        elif item == ')':
            balance -= 1

        if balance < 0:
            return False
    return balance == 0

