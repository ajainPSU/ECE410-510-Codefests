import dis
import py_compile
from collections import Counter
import time
import psutil  # Install with `pip install psutil`
import subprocess  # To execute the MatrixTest.py script
import cProfile
import pstats

# Step 1: Compile the file into Python bytecode
print("Compiling MatrixTest.py into bytecode...")
py_compile.compile(r"c:\Users\jaina\Documents\MatrixTest.py")
print("Compilation complete.\n")

# Step 2: Disassemble the bytecode
from MatrixTest import matrix_multiplication  # Import the function for disassembly
print("Disassembling the bytecode of matrix_multiplication function...")
instruction_counts = Counter(instr.opname for instr in dis.get_instructions(matrix_multiplication))
dis.dis(matrix_multiplication)

# Step 3: Count the number of each instruction
print("\nInstruction Counts:")
for instruction, count in instruction_counts.items():
    print(f"{instruction}: {count}")

# Step 4: Profile the execution time and resource usage of the entire MatrixTest program
def profile_program(script_path):
    process = psutil.Process()  # Get current process
    start_time = time.time()  # Start time
    start_memory = process.memory_info().rss  # Start memory in bytes

    # Run the MatrixTest.py script
    print("\nRunning MatrixTest.py...")
    subprocess.run(["python", script_path], check=True)

    end_time = time.time()  # End time
    end_memory = process.memory_info().rss  # End memory in bytes

    print("\nProfiling Results for MatrixTest.py:")
    print(f"Execution Time: {end_time - start_time:.6f} seconds")
    print(f"Memory Usage: {end_memory - start_memory} bytes")

# Profile the entire MatrixTest.py program
profile_program(r"c:\Users\jaina\Documents\MatrixTest.py")

# Step 5: Generate a .prof file using cProfile
def generate_prof_file(script_path, output_file):
    print(f"\nGenerating profiling data for {script_path}...")
    # Use raw strings to avoid issues with backslashes
    cProfile.run(f"subprocess.run([r'python', r'{script_path}'], check=True)", output_file)
    print(f"Profiling data saved to {output_file}")

# Generate the .prof file
prof_file = r"c:\Users\jaina\Documents\MatrixTest.prof"
generate_prof_file(r"c:\Users\jaina\Documents\MatrixTest.py", prof_file)

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

# Analyze the algorithmic structure and data dependencies
def analyze_matrix_dependencies(A, B):
    print("\nAnalyzing Algorithmic Structure and Data Dependencies...")
    num_rows_A = len(A)
    num_cols_A = len(A[0])
    num_rows_B = len(B)
    num_cols_B = len(B[0])

    if num_cols_A != num_rows_B:
        print("Matrix multiplication is not possible due to incompatible dimensions.")
        return

    dependencies = []
    for i in range(num_rows_A):
        for j in range(num_cols_B):
            # Each element in the result depends on the i-th row of A and j-th column of B
            dependencies.append((f"Row {i} of A", f"Column {j} of B"))

    print(f"Matrix A Dimensions: {num_rows_A}x{num_cols_A}")
    print(f"Matrix B Dimensions: {num_rows_B}x{num_cols_B}")
    print("Dependencies:")
    for dep in dependencies:
        print(f"  {dep[0]} depends on {dep[1]}")

    print("Potential Parallelism: Each row of the result matrix can be computed independently.")

# Example usage for all matrix multiplications in MatrixTest
from MatrixTest import A1, B1, A2, B2, A3, B3
analyze_matrix_dependencies(A1, B1)
analyze_matrix_dependencies(A2, B2)
analyze_matrix_dependencies(A3, B3)