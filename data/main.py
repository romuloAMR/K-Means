import csv
import random

m = int(input("Set the number of rows (m): "))
n = int(input("Set the number of columns (n): "))
x = float(input("Lowest value: "))
y = float(input("Highest value: "))

file_name = f"dataset_{m}x{n}_range_{x}_to_{y}.csv"

with open(file_name, 'w', newline='') as f:
    writer = csv.writer(f)
    writer.writerow([f'Col_{col+1}' for col in range(n)])
    for _ in range(m):
        linha = [random.uniform(x, y) for _ in range(n)]
        writer.writerow(linha)

print(f"{file_name} finished!")
