package main

import (
	"testing"
)

var (
	globalPoints []Point
	globalPoint  *Point
)

func BenchmarkLoadPoints(b *testing.B) {
	path := "../../data/dataset_1000000x100_range_0.0_to_100.0.csv"
	
	b.ReportAllocs()
	b.ResetTimer()

	for i := 0; i < b.N; i++ {
		pts, err := LoadPoints(path)
		if err != nil {
			b.Fatal(err)
		}
		globalPoints = pts
	}
}

func BenchmarkProcessLine(b *testing.B) {
    line := []byte("100.0, 20.0, 30.5, 40.3, 21.7")

    b.Run("Latencia_Serial", func(b *testing.B) {
        b.ReportAllocs()
        for i := 0; i < b.N; i++ {
            globalPoint, _ = processLine(line)
        }
    })

    b.Run("Escalabilidade_Paralela", func(b *testing.B) {
        b.ReportAllocs()
        b.RunParallel(func(pb *testing.PB) {
            var localPoint *Point 
            for pb.Next() {
                p, _ := processLine(line)
                localPoint = p
            }
            globalPoint = localPoint 
        })
    })
}
