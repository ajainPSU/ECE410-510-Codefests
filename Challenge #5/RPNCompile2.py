import dis
import py_compile
from collections import Counter
import time
import psutil  # Install with `pip install psutil`
import subprocess  # To execute the RPNExample.py script
import cProfile
import pstats

# Step 1: Compile the file into Python bytecode
print("Compiling RPNExample.py into bytecode...")
py_compile.compile(r"c:\Users\jaina\Documents\RPNExample.py")
print("Compilation complete.\n")

# Step 2: Disassemble the bytecode
from RPNExample import rpn_calculate  # Import the function for disassembly
print("Disassembling the bytecode of rpn_calculate function...")
instruction_counts = Counter(instr.opname for instr in dis.get_instructions(rpn_calculate))
dis.dis(rpn_calculate)

# Step 3: Count the number of each instruction
print("\nInstruction Counts:")
for instruction, count in instruction_counts.items():
    print(f"{instruction}: {count}")

# Step 4: Profile the execution time and resource usage of the entire RPNExample program
def profile_program(script_path):
    process = psutil.Process()  # Get current process
    start_time = time.time()  # Start time
    start_memory = process.memory_info().rss  # Start memory in bytes

    # Run the RPNExample.py script
    print("\nRunning RPNExample.py...")
    subprocess.run(["python", script_path], check=True)

    end_time = time.time()  # End time
    end_memory = process.memory_info().rss  # End memory in bytes

    print("\nProfiling Results for RPNExample.py:")
    print(f"Execution Time: {end_time - start_time:.6f} seconds")
    print(f"Memory Usage: {end_memory - start_memory} bytes")

# Profile the entire RPNExample.py program
profile_program(r"c:\Users\jaina\Documents\RPNExample.py")

# Step 5: Generate a .prof file using cProfile
def generate_prof_file(script_path, output_file):
    print(f"\nGenerating profiling data for {script_path}...")
    # Use raw strings to avoid issues with backslashes
    cProfile.run(f"subprocess.run([r'python', r'{script_path}'], check=True)", output_file)
    print(f"Profiling data saved to {output_file}")

# Generate the .prof file
prof_file = r"c:\Users\jaina\Documents\RPNExample.prof"
generate_prof_file(r"c:\Users\jaina\Documents\RPNExample.py", prof_file)

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
def analyze_parallelism(expression):
    print("\nAnalyzing Algorithmic Structure and Data Dependencies...")
    tokens = expression.split()
    dependencies = []
    stack_depth = 0

    for token in tokens:
        if token in {'+', '-', '*', '/'}:
            # Each operator depends on the last two items in the stack
            dependencies.append((stack_depth - 2, stack_depth - 1))
            stack_depth -= 1  # Two items are consumed, one result is pushed
        else:
            stack_depth += 1  # A number is pushed onto the stack

    print(f"Expression: {expression}")
    print(f"Dependencies: {dependencies}")
    print(f"Maximum Stack Depth: {stack_depth}")
    if len(dependencies) > 1:
        print("Potential Parallelism: Independent operations can be executed concurrently.")
    else:
        print("No significant parallelism detected.")

# Example analysis for all expressions in RPNExample
from RPNExample import expressions
for expression in expressions:
    analyze_parallelism(expression)