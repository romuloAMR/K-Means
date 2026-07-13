package main

import (
	"testing"
)

var (
	globalKmeans *kmeans
	globalCentroid int
	globalErrK     error
)

func BenchmarkKMeansFit(b *testing.B) {
	points, err := LoadPoints("../../data/dataset_1000000x100_range_0.0_to_100.0.csv")
	if err != nil {
		b.Fatal(err)
	}

	b.ReportAllocs()
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
		globalKmeans = k
	}
}

func BenchmarkUpdateCentroids_Isolated(b *testing.B) {
	points, err := LoadPoints("../../data/dataset_1000000x100_range_0.0_to_100.0.csv")
	if err != nil {
		b.Fatal(err)
	}

	k, _ := Kmeans(3, points, 2026)
	_ = k.FitMaxIterations(1)
	original := make([][]Point, len(k.clusters))
	for i := range k.clusters {
		original[i] = append([]Point(nil), k.clusters[i]...)
	}

	b.ReportAllocs()
	b.ResetTimer()

	for i := 0; i < b.N; i++ {
		for j := range k.clusters {
			k.clusters[j] = append(k.clusters[j][:0], original[j]...)
		}

		globalErrK = k.updateCentroids()
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
	numPoints := len(points)

	b.ResetTimer()

	for i := 0; i < b.N; i++ {
		p := &points[idx]
		
		c, _ := k.findNearestCentroid(p)
		globalCentroid = c

		idx++
		if idx >= numPoints {
			idx = 0
		}
	}
}
