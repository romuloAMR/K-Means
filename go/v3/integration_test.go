package main

import "testing"

func BenchmarkFullPipeline(b *testing.B) {
	path := "/workspaces/K-Means/data/dataset_1000000x100_range_0.0_to_100.0.csv"

	b.ReportAllocs()

	for i := 0; i < b.N; i++ {
		points, err := LoadPoints(path)
		if err != nil {
			b.Fatal(err)
		}

		k, err := Kmeans(3, points, 2026)
		if err != nil {
			b.Fatal(err)
		}

		if err := k.Fit(); err != nil {
			b.Fatal(err)
		}
	}
}
