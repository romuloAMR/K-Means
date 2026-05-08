package main

import (
	"bytes"
	"os"
	"testing"
)

var (
	globalPoints []Point
	globalPoint  Point
)

func BenchmarkLoadPointsFromMemory(b *testing.B) {
	data, err := os.ReadFile("../../data/dataset_1000000x100_range_0.0_to_100.0.csv")
	if err != nil {
		b.Fatal(err)
	}

	b.ReportAllocs()
	b.ResetTimer()

	for i := 0; i < b.N; i++ {
		pts, err := LoadPointsFromReader(bytes.NewReader(data))
		if err != nil {
			b.Fatal(err)
		}
		globalPoints = pts
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

	b.ReportAllocs()
	b.ResetTimer()

	for i := 0; i < b.N; i++ {
		for _, line := range lines {
			p, err := lineToPoint(line)
			if err != nil {
				b.Fatal(err)
			}
			globalPoint = p
		}
	}
}
