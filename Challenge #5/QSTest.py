def quicksort(arr):
    """
    Sorts an array using the quicksort algorithm (functional implementation).
    """
    if len(arr) <= 1:
        return arr
    pivot = arr[len(arr) // 2]
    left = [x for x in arr if x < pivot]
    middle = [x for x in arr if x == pivot]
    right = [x for x in arr if x > pivot]
    return quicksort(left) + middle + quicksort(right)

def partition(arr, low, high):
    """
    Helper function to partition the array for in-place quicksort.
    """
    pivot = arr[high]
    i = low - 1
    for j in range(low, high):
        if arr[j] <= pivot:
            i += 1
            arr[i], arr[j] = arr[j], arr[i]
    arr[i + 1], arr[high] = arr[high], arr[i + 1]
    return i + 1

def quicksort_inplace(arr, low, high):
    """
    Sorts an array in-place using the quicksort algorithm.
    """
    if low < high:
        pi = partition(arr, low, high)
        quicksort_inplace(arr, low, pi - 1)
        quicksort_inplace(arr, pi + 1, high)

# Example usage for functional quicksort
arr1 = [10, 7, 8, 9, 1, 5]
print("Original array (functional):", arr1)
sorted_arr1 = quicksort(arr1)
print("Sorted array (functional):", sorted_arr1)

# Example usage for in-place quicksort
arr2 = [4, 2, 6, 9, 3]
print("\nOriginal array (in-place):", arr2)
quicksort_inplace(arr2, 0, len(arr2) - 1)
print("Sorted array (in-place):", arr2)