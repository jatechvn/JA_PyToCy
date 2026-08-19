# a:/JA_PROJECT/Project _Dart/JA_PyToCy/scratch/math_test.py
# Simple mathematical function to test Cython speedup

def run_heavy_loop(limit):
    total = 0
    for i in range(limit):
        total += (i * 3) % 7
    return total
