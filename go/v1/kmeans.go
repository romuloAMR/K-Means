package main

import (
	"errors"
	"math"
)

type kmeans struct {
	numClusters int
	points []Point
	clusters [][]Point
	centroids []Point
}

func Kmeans(numClusters int, points []Point, seed uint64) (*kmeans, error) {
	numPoints := len(points)
	if numClusters == 0 || numClusters > numPoints {
		return nil, errors.New("number of clusters greater than the number of points or zero points")
	}

	instance := &kmeans{
		numClusters: numClusters,
		points: points,
		clusters: make([][]Point, numClusters),
		centroids: make([]Point, numClusters),
	}

	indices := []int{10, 532, 9012}
	instance.initCentroids(indices)

	return instance, nil
}

func (k *kmeans) initCentroids(indices []int) {
	for i := 0; i < k.numClusters; i++ {
		k.centroids[i] = k.points[indices[i]]
	}
}

func (k *kmeans) updateCentroids() error {
	newCentroids := make([]Point, k.numClusters)

	for i := range k.numClusters {
		cluster := k.clusters[i]

		if len(cluster) == 0 {
			newCentroids[i] = k.centroids[i]
			continue
		}

		dim := len(cluster[0].position)
		sum, err := NewPoint(make([]float64, dim))

		if err != nil {
			return err
		}

		for _, point := range cluster {
			sum.AccumulatedAddPoint(&point)
		}

		sum.AccumulatedDivide(float64(len(cluster)))

		newCentroids[i] = *sum
	}

	copy(k.centroids, newCentroids)
	return nil
}

func (k *kmeans) findNearestCentroid(p *Point) (int, error) {
	minDistance := math.MaxFloat64
	nearestIndex := -1

	for i := range k.numClusters {
		dist, err := p.SqDistanceTo(&k.centroids[i])

		if err != nil {
			return -1, err
		}

		if dist < minDistance {
			minDistance = dist
			nearestIndex = i
		}
	}

	return nearestIndex, nil
}

func (k *kmeans) centroidsConverged(last []Point, now []Point) (bool, error) {
	epsilon := 1e-10
	for i := range k.numClusters {
		dist, err := last[i].SqDistanceTo(&now[i])

		if err != nil {
			return false, err
		}

		if  dist> epsilon {
			return false, nil
		}
	}
	return true, nil
}

func (k *kmeans) Fit() error {
	err := k.FitMaxIterations(300)
	
	if err != nil {
		return err
	}

	return nil
}

func (k *kmeans) FitMaxIterations(maxIterations int) error {
	iteration := 0
	lastCentroids := make([]Point, k.numClusters)

	for {
		copy(lastCentroids, k.centroids)

		for i := range k.clusters {
		    k.clusters[i] = k.clusters[i][:0]
		}

		for _, point := range k.points {
			indexCluster, err := k.findNearestCentroid(&point)

			if err != nil {
				return err
			}

			k.clusters[indexCluster] = append(k.clusters[indexCluster], point)
		}

		k.updateCentroids()
		converged, err := k.centroidsConverged(lastCentroids, k.centroids)

		if err != nil {
			return err
		}

		iteration++

		if converged || iteration >= maxIterations {
			break
		}
	}
	return nil
}

func (k *kmeans) GetCentroids() []Point {
	return k.centroids
}

func (k *kmeans) GetClusters() [][]Point {
	return k.clusters
}
