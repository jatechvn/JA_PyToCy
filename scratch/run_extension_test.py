# a:/JA_PROJECT/Project _Dart/JA_PyToCy/scratch/run_extension_test.py
import os
import sys
import shutil
import subprocess

def test_compilation_modes():
    # 1. Setup mock package structure
    base_dir = os.path.dirname(os.path.abspath(__file__))
    pkg_dir = os.path.join(base_dir, "package_test")
    os.makedirs(pkg_dir, exist_ok=True)
    
    # Create __init__.py and submodule.py
    with open(os.path.join(pkg_dir, "__init__.py"), "w") as f:
        f.write("# package init")
        
    with open(os.path.join(pkg_dir, "submodule.py"), "w") as f:
        f.write("def test_func(): return 'hello'")
        
    # Change dir to package_test
    os.chdir(pkg_dir)
    
    # Mode A: Standard auto-detect cythonize("submodule.py")
    setup_a = """
from setuptools import setup
from Cython.Build import cythonize
setup(
    ext_modules = cythonize("submodule.py")
)
"""
    with open("setup_temp_a.py", "w") as f:
        f.write(setup_a)
        
    print("Testing Mode A (Auto-detect):")
    res_a = subprocess.run([sys.executable, "setup_temp_a.py", "build_ext", "--inplace"], 
                           capture_output=True, text=True)
    
    print(f"Mode A exit code: {res_a.exitCode if hasattr(res_a, 'exitCode') else res_a.returncode}")
    if res_a.returncode != 0:
        print("Mode A failed as expected (No such file or directory package bug)")
    
    # Clean up A
    if os.path.exists("setup_temp_a.py"): os.remove("setup_temp_a.py")
    if os.path.exists("build"): shutil.rmtree("build")
    if os.path.exists("submodule.c"): os.remove("submodule.c")
    
    # Mode B: Explicit Extension("submodule", ["submodule.py"])
    setup_b = """
from setuptools import setup, Extension
from Cython.Build import cythonize
setup(
    ext_modules = cythonize(
        Extension("submodule", sources=["submodule.py"]),
        compiler_directives={'language_level': "3"}
    )
)
"""
    with open("setup_temp_b.py", "w") as f:
        f.write(setup_b)
        
    print("\nTesting Mode B (Explicit Extension):")
    res_b = subprocess.run([sys.executable, "setup_temp_b.py", "build_ext", "--inplace"], 
                           capture_output=True, text=True)
    
    print(f"Mode B exit code: {res_b.returncode}")
    if res_b.returncode == 0:
        print("Mode B succeeded! Flat naming works perfectly!")
        
    # Clean up B
    if os.path.exists("setup_temp_b.py"): os.remove("setup_temp_b.py")
    if os.path.exists("build"): shutil.rmtree("build")
    if os.path.exists("submodule.c"): os.remove("submodule.c")
    
    # Clean up package folder
    os.chdir(base_dir)
    shutil.rmtree(pkg_dir)

if __name__ == "__main__":
    test_compilation_modes()
