package main

import (
	"runtime"
	"sync"
	"testing"
)

var (
	globalCentroidIdx int
	globalErr         error
	cachedPoints      []Point
	loadOnce          sync.Once
)

func getPointsOrFatal(b *testing.B) []Point {
	loadOnce.Do(func() {
		pts, err := LoadPoints("../../data/dataset_1000000x100_range_0.0_to_100.0.csv")
		if err != nil {
			b.Fatalf("Erro carregando pontos: %v", err)
		}
		cachedPoints = pts
	})
	return cachedPoints
}

func BenchmarkClustering_Step(b *testing.B) {
	points := getPointsOrFatal(b)
	numWorkers := runtime.NumCPU()
	k, _ := Kmeans(3, points, 2026)

	b.ReportAllocs()
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		k.centroids[0].Coordinates()[0] = float64(i)
		
		err := k.clustering(numWorkers)
		if err != nil {
			b.Fatal(err)
		}
	}
}

func BenchmarkUpdateCentroids_Step(b *testing.B) {
	points := getPointsOrFatal(b)
	numWorkers := runtime.NumCPU()
	k, _ := Kmeans(3, points, 2026)
	_ = k.clustering(numWorkers)

	b.ReportAllocs()
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
        if i % 2 == 0 {
            k.assignments[0] = 0
        } else {
            k.assignments[0] = 1
        }
		err := k.updateCentroids(numWorkers)
		if err != nil {
			b.Fatal(err)
		}
	}
}

func BenchmarkFindNearestCentroid(b *testing.B) {
	points := getPointsOrFatal(b)
	k, _ := Kmeans(3, points, 2026)
	p := &points[0]

	b.Run("Serial", func(b *testing.B) {
		var localIdx int
		for i := 0; i < b.N; i++ {
			localIdx, _ = k.findNearestCentroid(p)
		}
		globalCentroidIdx = localIdx
	})

	b.Run("Parallel", func(b *testing.B) {
		b.RunParallel(func(pb *testing.PB) {
			var localIdx int
			for pb.Next() {
				idx, _ := k.findNearestCentroid(p)
				localIdx = idx
			}
			globalCentroidIdx = localIdx
		})
	})
}

func BenchmarkKMeansFit(b *testing.B) {
    points := getPointsOrFatal(b)

    b.ReportAllocs()
    b.ResetTimer()
    for i := 0; i < b.N; i++ {
        iterPoints := make([]Point, len(points))
        copy(iterPoints, points)

        k, _ := Kmeans(3, iterPoints, 2026)
        globalErr = k.Fit()
    }
}
