package main

import (
	"testing"
)

func BenchmarkKMeansFit(b *testing.B) {
	points, err := LoadPoints("../../data/dataset_1000000x100_range_0.0_to_100.0.csv")
	if err != nil {
		b.Fatal(err)
	}

	b.ResetTimer()

	for i := 0; i < b.N; i++ {
		k, err := Kmeans(3, points, 2026)
		if err != nil {
			b.Fatal(err)
		}

		err = k.Fit()
		if err != nil {
			b.Fatal(err)
		}
	}
}

func BenchmarkUpdateCentroids_Isolated(b *testing.B) {
	points, err := LoadPoints("../../data/dataset_1000000x100_range_0.0_to_100.0.csv")
	if err != nil {
		b.Fatal(err)
	}

	k, err := Kmeans(3, points, 2026)
	if err != nil {
		b.Fatal(err)
	}

	if err := k.FitMaxIterations(1); err != nil {
		b.Fatal(err)
	}

	original := make([][]Point, len(k.clusters))
	for i := range k.clusters {
		original[i] = append([]Point(nil), k.clusters[i]...)
	}

	b.ResetTimer()

	for i := 0; i < b.N; i++ {
		for j := range k.clusters {
			k.clusters[j] = append(k.clusters[j][:0], original[j]...)
		}

		if err := k.updateCentroids(); err != nil {
			b.Fatal(err)
		}
	}
}
func BenchmarkFindNearestCentroid_NoModulo(b *testing.B) {
	points, err := LoadPoints("../../data/dataset_1000000x100_range_0.0_to_100.0.csv")
	if err != nil {
		b.Fatal(err)
	}

	k, _ := Kmeans(3, points, 2026)
	_ = k.FitMaxIterations(1)

	idx := 0

	b.ResetTimer()

	for i := 0; i < b.N; i++ {
		p := &points[idx]
		idx++
		if idx == len(points) {
			idx = 0
		}

		_, _ = k.findNearestCentroid(p)
	}
}
