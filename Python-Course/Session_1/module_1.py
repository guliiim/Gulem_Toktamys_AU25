from typing import List


def task_1(array: List[int], target: int) -> List[int]:
    """
    Write your code below
    """
    seen = set()

    for num in array:
        need = target - num
        if need in seen:
            return [need, num]
        seen.add(num)

    return []


def task_2(number: int) -> int:
    """
    Write your code below
    """
    result = 0

    while number > 0:
        digit = number % 10
        result = result * 10 + digit
        number //= 10

    return result


def task_3(array: List[int]) -> int:
    """
    Write your code below
    """
    for num in array:
        index = abs(num) - 1
        if array[index] < 0:
            return abs(num)
        array[index] *= -1
    return -1


def task_4(string: str) -> int:
    """
    Write your code below
    """
    roman_values = {'I': 1, 'V': 5, 'X': 10, 'L': 50, 'C': 100, 'D': 500, 'M': 1000}

    total = 0
    n = len(string)
    for i in range(n - 1):
        current = roman_values[string[i]]
        next_value = roman_values[string[i + 1]]

        if current < next_value:
            total -= current
        else:
            total += current

    total += roman_values[string[-1]]
    return total


def task_5(array: List[int]) -> int:
    """
    Write your code below
    """
    min_val = array[0]

    for num in array[1:]:
        if num < min_val:
            min_val = num

    return min_val
