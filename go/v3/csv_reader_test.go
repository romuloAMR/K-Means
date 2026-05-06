package main

import (
    "testing"
)

func BenchmarkLoadPointsParallel(b *testing.B) {
    path := "../../data/dataset_1000000x100_range_0.0_to_100.0.csv"

    b.ResetTimer()
    b.RunParallel(func(pb *testing.PB) {
        for pb.Next() {
            _, err := LoadPoints(path)
            if err != nil {
                b.Fatal(err)
            }
        }
    })
}

func BenchmarkProcessLineParallel(b *testing.B) {
    line := []byte("100.0, 20.0, 30.5, 40.3, 21.7, 100.0, 20.0, 30.5, 40.3, 21.7")

    b.ResetTimer()
    b.RunParallel(func(pb *testing.PB) {
        for pb.Next() {
            _, err := processLine(line)
            if err != nil {
                b.Fatal(err)
            }
        }
    })
}
