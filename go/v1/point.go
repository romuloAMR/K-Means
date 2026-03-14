package main

import (
	"errors"
	"fmt"
)

type Point struct {
	position []float64
}

func NewPoint(pos []float64) (*Point, error) {
	if len(pos) == 0 {
		return nil, errors.New("position can't be empty")
	}
	dest := make([]float64, len(pos))
	copy(dest, pos)
	return &Point{position: dest}, nil
}

func (p *Point) Dimension() int {
	return len(p.position)
}

func (p *Point) SqDistanceTo(other *Point) (float64, error) {
	if p.Dimension() == 0 || other.Dimension() == 0 {
		return 0, errors.New("position can't be empty")
	}
	if p.Dimension() != other.Dimension() {
		return 0, errors.New("dimensions must match")
	}

	var sum float64
	for i := range p.position {
		diff := p.position[i] - other.position[i]
		sum += diff * diff
	}
	return sum, nil
}

func (p *Point) AccumulatedAddPoint(other *Point) error {
	if p.Dimension() != other.Dimension() {
		return errors.New("dimensions must match")
	}
	for i := range p.position {
		p.position[i] += other.position[i]
	}
	return nil
}

func (p *Point) AccumulatedDivide(scalar float64) error {
	if scalar == 0 {
		return errors.New("division by zero")
	}
	for i := range p.position {
		p.position[i] /= scalar
	}
	return nil
}

func (p *Point) GetOnePosition(i int) (float64, error) {
	if i < 0 || i >= p.Dimension() {
		return 0, errors.New("index out of bounds")
	}
	return p.position[i], nil
}

func (p *Point) String() string {
	return fmt.Sprintf("%v", p.position)
}
