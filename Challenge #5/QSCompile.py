import dis
import py_compile
from collections import Counter
import time
import psutil  # Install with `pip install psutil`
import subprocess  # To execute the QSTest.py script
import cProfile
import pstats

# Step 1: Compile the file into Python bytecode
print("Compiling QSTest.py into bytecode...")
py_compile.compile(r"c:\Users\jaina\Documents\QSTest.py")
print("Compilation complete.\n")

# Step 2: Disassemble the bytecode
from QSTest import quicksort, quicksort_inplace  # Import the functions for disassembly
print("Disassembling the bytecode of quicksort function...")
instruction_counts_quicksort = Counter(instr.opname for instr in dis.get_instructions(quicksort))
dis.dis(quicksort)

print("\nDisassembling the bytecode of quicksort_inplace function...")
instruction_counts_quicksort_inplace = Counter(instr.opname for instr in dis.get_instructions(quicksort_inplace))
dis.dis(quicksort_inplace)

# Step 3: Count the number of each instruction
print("\nInstruction Counts for quicksort:")
for instruction, count in instruction_counts_quicksort.items():
    print(f"{instruction}: {count}")

print("\nInstruction Counts for quicksort_inplace:")
for instruction, count in instruction_counts_quicksort_inplace.items():
    print(f"{instruction}: {count}")

# Step 4: Profile the execution time and resource usage of the entire QSTest program
def profile_program(script_path):
    process = psutil.Process()  # Get current process
    start_time = time.time()  # Start time
    start_memory = process.memory_info().rss  # Start memory in bytes

    # Run the QSTest.py script
    print("\nRunning QSTest.py...")
    subprocess.run(["python", script_path], check=True)

    end_time = time.time()  # End time
    end_memory = process.memory_info().rss  # End memory in bytes

    print("\nProfiling Results for QSTest.py:")
    print(f"Execution Time: {end_time - start_time:.6f} seconds")
    print(f"Memory Usage: {end_memory - start_memory} bytes")

# Profile the entire QSTest.py program
profile_program(r"c:\Users\jaina\Documents\QSTest.py")

# Step 5: Generate a .prof file using cProfile
def generate_prof_file(script_path, output_file):
    print(f"\nGenerating profiling data for {script_path}...")
    # Use raw strings to avoid issues with backslashes
    cProfile.run(f"subprocess.run([r'python', r'{script_path}'], check=True)", output_file)
    print(f"Profiling data saved to {output_file}")

# Generate the .prof file
prof_file = r"c:\Users\jaina\Documents\QSTest.prof"
generate_prof_file(r"c:\Users\jaina\Documents\QSTest.py", prof_file)

# Step 6: Analyze the .prof file with pstats
def analyze_prof_file(prof_file):
    print(f"\nAnalyzing profiling data from {prof_file}...")
    stats = pstats.Stats(prof_file)
    stats.strip_dirs()
    stats.sort_stats("cumulative")
    stats.print_stats(10)  # Print the top 10 cumulative time functions

analyze_prof_file(prof_file)

# Step 7: Use snakeviz to visualize the .prof file
print("\nTo visualize the profiling data, run the following command in your terminal:")
print(f"snakeviz {prof_file}")

def analyze_quicksort_dependencies(arr):
    print("\nAnalyzing Algorithmic Structure and Data Dependencies for quicksort...")
    dependencies = []
    stack_depth = 0

    def quicksort_analysis(arr, depth):
        nonlocal stack_depth
        if len(arr) <= 1:
            return
        pivot = arr[len(arr) // 2]
        left = [x for x in arr if x < pivot]
        right = [x for x in arr if x > pivot]
        dependencies.append((f"Partition at depth {depth}", f"Left: {left}, Right: {right}"))
        stack_depth = max(stack_depth, depth + 1)
        quicksort_analysis(left, depth + 1)
        quicksort_analysis(right, depth + 1)

    quicksort_analysis(arr, 0)

    print(f"Input Array: {arr}")
    print("Dependencies:")
    for dep in dependencies:
        print(f"  {dep[0]} -> {dep[1]}")
    print(f"Maximum Recursion Depth: {stack_depth}")
    if len(dependencies) > 1:
        print("Potential Parallelism: Independent partitions can be sorted concurrently.")
    else:
        print("No significant parallelism detected.")

# Example usage
arr1 = [10, 7, 8, 9, 1, 5]
analyze_quicksort_dependencies(arr1)

arr2 = [4, 2, 6, 9, 3]
analyze_quicksort_dependencies(arr2)