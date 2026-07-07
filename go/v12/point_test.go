package main

import (
    "testing"
)

var resultDist float64

func BenchmarkSqDistance(b *testing.B) {
    p1, _ := NewPoint([]float64{1, 2, 3, 4, 5})
    p2, _ := NewPoint([]float64{5, 4, 3, 2, 1})
    
    var d float64
    b.ResetTimer()

    for i := 0; i < b.N; i++ {
        d, _ = p1.SqDistanceTo(p2)
    }
    resultDist = d
}

func BenchmarkAccumulatedAddPointSafe(b *testing.B) {
    base1, _ := NewPoint([]float64{1, 2, 3})
    p2, _ := NewPoint([]float64{4, 5, 6})

    b.ReportAllocs()
    b.ResetTimer()

    for i := 0; i < b.N; i++ {
        _ = base1.AccumulatedAddPoint(p2)
    }
}

func BenchmarkAccumulatedDivide(b *testing.B) {
    base, _ := NewPoint([]float64{10, 20, 30})
    
    b.ReportAllocs()
    b.ResetTimer()

    for i := 0; i < b.N; i++ {
        _ = base.AccumulatedDivide(2)
    }
}
