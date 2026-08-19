# a:/JA_PROJECT/Project _Dart/JA_PyToCy/scratch/run_test_compilation.py
import os
import sys
import time
import subprocess
import shutil

def run_benchmarks(limit):
    # Benchmark pure python
    import math_test
    
    t0 = time.perf_counter()
    res_py = math_test.run_heavy_loop(limit)
    t1 = time.perf_counter()
    py_time = t1 - t0
    print(f"Pure Python result: {res_py} in {py_time:.6f}s")
    
    # 2. Setup compile configurations
    setup_content = """
from setuptools import setup
from Cython.Build import cythonize

directives = {
    'language_level': "3",
    'boundscheck': False,
    'wraparound': False,
}

setup(
    ext_modules=cythonize("math_test.py", compiler_directives=directives)
)
"""
    with open("setup_temp.py", "w") as f:
        f.write(setup_content)
        
    print("Running Cython compilation...")
    
    # 3. Compile
    res = subprocess.run([sys.executable, "setup_temp.py", "build_ext", "--inplace"], 
                         capture_output=True, text=True)
    
    # Clean up setup script and build directories
    if os.path.exists("setup_temp.py"):
        os.remove("setup_temp.py")
    if os.path.exists("build"):
        shutil.rmtree("build")
        
    if res.returncode != 0:
        print("Compilation failed!")
        print("Stdout:", res.stdout)
        print("Stderr:", res.stderr)
        return
        
    print("Compilation succeeded!")
    
    # Clean up intermediate C file
    if os.path.exists("math_test.c"):
        os.remove("math_test.c")
        
    # Reload and import the compiled module
    # We must unload the cached pure-python module first
    if 'math_test' in sys.modules:
        del sys.modules['math_test']
        
    import math_test
    
    t2 = time.perf_counter()
    res_cy = math_test.run_heavy_loop(limit)
    t3 = time.perf_counter()
    cy_time = t3 - t2
    print(f"Cython Compiled result: {res_cy} in {cy_time:.6f}s")
    
    speedup = py_time / cy_time if cy_time > 0 else 0
    print(f"Speedup factor: {speedup:.2f}x faster!")

if __name__ == "__main__":
    os.chdir(os.path.dirname(os.path.abspath(__file__)))
    # Use a large limit to measure performance difference
    run_benchmarks(10_000_000)
