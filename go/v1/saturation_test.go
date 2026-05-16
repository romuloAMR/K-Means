//go:build saturation

package main

import (
	"testing"
)

func BenchmarkMultipleFullInstances(b *testing.B) {
    warmupOnce.Do(func() {
		pts, _ := LoadPoints("../../data/dataset_1000000x100_range_0.0_to_100.0.csv")
		cachedPoints = pts
	})

	b.ResetTimer()

    b.RunParallel(func(pb *testing.PB) {
        for pb.Next() {
			points, _ := LoadPoints("../../data/dataset_1000000x100_range_0.0_to_100.0.csv")
            k, _ := Kmeans(3, points, 2026)
            _ = k.Fit()
        }
    })
}
