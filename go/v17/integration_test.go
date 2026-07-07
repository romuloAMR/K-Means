package main

import (
	"context"
	"testing"
)

func BenchmarkFullPipeline(b *testing.B) {
	path := "/workspaces/K-Means/data/dataset_1000000x100_range_0.0_to_100.0.csv"
	ctx := context.Background()

	b.ReportAllocs()
	b.ResetTimer()

	for i := 0; i < b.N; i++ {
		points, err := LoadPoints(ctx, path)
		if err != nil {
			b.Fatal(err)
		}

		k, err := Kmeans(3, points, 2026)
		if err != nil {
			b.Fatal(err)
		}

		if err := k.Fit(ctx); err != nil {
			b.Fatal(err)
		}
	}
}
