package main

import (
	"testing"
)

func BenchmarkSqDistance(b *testing.B) {
	p1, _ := NewPoint([]float64{1, 2, 3, 4, 5})
	p2, _ := NewPoint([]float64{5, 4, 3, 2, 1})

	b.ResetTimer()

	for i := 0; i < b.N; i++ {
		_, _ = p1.SqDistanceTo(p2)
	}
}

func BenchmarkAccumulatedAddPointSafe(b *testing.B) {
	base1, _ := NewPoint([]float64{1, 2, 3})
	p2, _ := NewPoint([]float64{4, 5, 6})

	b.ResetTimer()

	for i := 0; i < b.N; i++ {
		p1, _ := NewPoint(base1.position)
		_ = p1.AccumulatedAddPoint(p2)
	}
}

func BenchmarkAccumulatedDivide(b *testing.B) {
	base, _ := NewPoint([]float64{10, 20, 30})

	b.ResetTimer()

	for i := 0; i < b.N; i++ {
		p, _ := NewPoint(base.position)
		_ = p.AccumulatedDivide(2)
	}
}
