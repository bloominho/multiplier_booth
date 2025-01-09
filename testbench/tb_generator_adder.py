import random

# --- Number of Simulations ---
number_of_tests = 1000
width = 17
span = 2**width

# --- Convert Integer -> Binary
def integer2binaryString (binary, length=1):
    return str(bin(binary)[2:].zfill(length))

def main():
    with (
        open("MultiplierTestVectorA", "w") as fA,
        open("MultiplierTestVectorB", "w") as fB,
        open("MultiplierTestVectorR", "w") as fR,
    ):  
        number_of_target_tests = 0
        # Case 1-------------------
        A = 2**width-1
        B = 2**width-1
        R = A * B
        print(A, B, R)

        # Write
        fA.write(integer2binaryString(A, width))
        fB.write(integer2binaryString(B, width))
        fR.write(integer2binaryString(R, 2*width))

        fA.write("\n")
        fB.write("\n")
        fR.write("\n")
        number_of_target_tests += 1

        # Case 2 --------------------
        A = 0
        B = 0
        R = A * B
        print(A, B, R)

        # Write
        fA.write(integer2binaryString(A, width))
        fB.write(integer2binaryString(B, width))
        fR.write(integer2binaryString(R, 2*width))

        fA.write("\n")
        fB.write("\n")
        fR.write("\n")
        number_of_target_tests += 1

        # Case 3 --------------------
        A = 0
        B = 1000
        R = A * B
        print(A, B, R)

        # Write
        fA.write(integer2binaryString(A, width))
        fB.write(integer2binaryString(B, width))
        fR.write(integer2binaryString(R, 2*width))

        fA.write("\n")
        fB.write("\n")
        fR.write("\n")
        number_of_target_tests += 1

        # Case 4 --------------------
        A = 1000
        B = 0
        R = A * B
        print(A, B, R)

        # Write
        fA.write(integer2binaryString(A, width))
        fB.write(integer2binaryString(B, width))
        fR.write(integer2binaryString(R, 2*width))

        fA.write("\n")
        fB.write("\n")
        fR.write("\n")
        number_of_target_tests += 1

        # Case 5 --------------------
        A = 1
        B = 1
        R = A * B
        print(A, B, R)

        # Write
        fA.write(integer2binaryString(A, width))
        fB.write(integer2binaryString(B, width))
        fR.write(integer2binaryString(R, 2*width))

        fA.write("\n")
        fB.write("\n")
        fR.write("\n")
        number_of_target_tests += 1

        # Random Tests
        for _ in range(number_of_tests-number_of_target_tests):
            # Generate Test Vectors
            A = random.randint(0, span-1)
            B = random.randint(0, span-1)
            R = A * B
            print(A, B, R)

            # Write
            fA.write(integer2binaryString(A, width))
            fB.write(integer2binaryString(B, width))
            fR.write(integer2binaryString(R, 2*width))

            fA.write("\n")
            fB.write("\n")
            fR.write("\n")


if __name__ == "__main__":
    main()