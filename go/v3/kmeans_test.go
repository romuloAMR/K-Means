package main

import (
    "runtime"
    "testing"
)

func BenchmarkKMeansFit(b *testing.B) {
    points, _ := LoadPoints("../../data/dataset_1000000x100_range_0.0_to_100.0.csv")

    b.ResetTimer()

    for i := 0; i < b.N; i++ {
        k, _ := Kmeans(3, points, 2026) 
        _ = k.Fit()
    }
}

func BenchmarkUpdateCentroids_Isolated(b *testing.B) {
    points, err := LoadPoints("../../data/dataset_1000000x100_range_0.0_to_100.0.csv")
    if err != nil {
        b.Fatal("Falha ao carregar pontos:", err)
    }

    numWorkers := runtime.NumCPU()
    
    k, err := Kmeans(3, points, 2026)
    if err != nil || k == nil {
        b.Fatal("Falha ao inicializar Kmeans:", err)
    }

    if err := k.clustering(numWorkers); err != nil {
        b.Fatal(err)
    }

    b.ResetTimer()
    for i := 0; i < b.N; i++ {
        err := k.updateCentroids(numWorkers)
        if err != nil {
            b.Fatal(err)
        }
    }
}

func BenchmarkFindNearestCentroid_Isolated(b *testing.B) {
    points, _ := LoadPoints("../../data/dataset_1000000x100_range_0.0_to_100.0.csv")
    k, _ := Kmeans(3, points, 2026)
    testPoint := points[0]
    
    b.ResetTimer()
    for i := 0; i < b.N; i++ {
        _, err := k.findNearestCentroid(&testPoint)
        if err != nil {
            b.Fatal(err)
        }
    }
}

func BenchmarkClustering(b *testing.B) {
    points, err := LoadPoints("../../data/dataset_1000000x100_range_0.0_to_100.0.csv")
    if err != nil {
        b.Fatal(err)
    }
    numWorkers := runtime.NumCPU()
    k, _ := Kmeans(3, points, 2026)
    backupCoords := make([][]float64, len(k.centroids))
    for i, c := range k.centroids {
        backupCoords[i] = make([]float64, len(c.Coordinates()))
        copy(backupCoords[i], c.Coordinates())
    }

    b.ResetTimer()
    for i := 0; i < b.N; i++ {
        b.StopTimer()
        for c := range k.centroids {
            copy(k.centroids[c].Coordinates(), backupCoords[c])
            coords := k.centroids[c].Coordinates()
            if i%2 == 0 {
                coords[0] += 0.5
            } else {
                coords[0] -= 0.5
            }
        }
        b.StartTimer()

        err := k.clustering(numWorkers)
        if err != nil {
            b.Fatal(err)
        }
    }
}
