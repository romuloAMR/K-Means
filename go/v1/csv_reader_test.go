package main

import (
	"bytes"
	"os"
	"testing"
)

func BenchmarkLoadPointsFromMemory(b *testing.B) {
	data, err := os.ReadFile("../../data/dataset_1000000x100_range_0.0_to_100.0.csv")
	if err != nil {
		b.Fatal(err)
	}

	b.ResetTimer()

	for i := 0; i < b.N; i++ {
		_, err := LoadPointsFromReader(bytes.NewReader(data))
		if err != nil {
			b.Fatal(err)
		}
	}
}

func BenchmarkLineToPoint5x10(b *testing.B) {
	lines := [][]string{
		{"100.0", "20.0", "30.5", "40.3", "21.7", "100.0", "20.0", "30.5", "40.3", "21.7"},
		{"100.0", "20.0", "30.5", "40.3", "21.7", "100.0", "20.0", "30.5", "40.3", "21.7"},
		{"100.0", "20.0", "30.5", "40.3", "21.7", "100.0", "20.0", "30.5", "40.3", "21.7"},
		{"100.0", "20.0", "30.5", "40.3", "21.7", "100.0", "20.0", "30.5", "40.3", "21.7"},
		{"100.0", "20.0", "30.5", "40.3", "21.7", "100.0", "20.0", "30.5", "40.3", "21.7"},
	}

	b.ResetTimer()

	for i := 0; i < b.N; i++ {
		for _, line := range lines {
			_, err := lineToPoint(line)
			if err != nil {
				b.Fatal(err)
			}
		}
	}
}
