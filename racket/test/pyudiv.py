from z3 import *

def pyudiv(x, y):
    if y == BitVecVal(0, 32):
        return y
    return UDiv(x, y)
