import numpy as np

def matrix_multiplication(A, B):
    """
    Multiplies two matrices A and B.
    """
    if len(A[0]) != len(B):
        raise ValueError("Number of columns in A must equal number of rows in B.")
    result = [[sum(a * b for a, b in zip(A_row, B_col)) for B_col in zip(*B)] for A_row in A]
    return result

# Example 1
A1 = [[1, 2], [3, 4]]
B1 = [[5, 6], [7, 8]]
result1 = matrix_multiplication(A1, B1)
print("Example 1:")
print(np.array(result1))

# Example 2
A2 = [[2, 4, 1], [0, 1, 3]]
B2 = [[1, 2], [3, 4], [5, 6]]
result2 = matrix_multiplication(A2, B2)
print("\nExample 2:")
print(np.array(result2))

# Example 3
A3 = [[1, 0, 2], [-1, 3, 1]]
B3 = [[3, 1], [2, 1], [1, 0]]
result3 = matrix_multiplication(A3, B3)
print("\nExample 3:")
print(np.array(result3))