package main

import (
	"errors"
	"math"
	"runtime"
	"sync"
)

type kmeans struct {
	numClusters int
	points []Point
	assignments []int
	centroids []Point
	numPoints int
	epsilon float64
}

func Kmeans(numClusters int, points []Point, seed uint64) (*kmeans, error) {
	numPoints := len(points)
	if numClusters == 0 || numClusters > numPoints {
		return nil, errors.New("number of clusters greater than the number of points or zero points")
	}

	instance := &kmeans{
		numClusters: numClusters,
		epsilon: 1e-10,
		numPoints: len(points),
		points: points,
		assignments: make([]int, numPoints),
		centroids: make([]Point, numClusters),
	}
	
	indices := []int{0, 1, 2}
	instance.initCentroids(indices)

	return instance, nil
}

func (k *kmeans) initCentroids(indices []int) {
	for i := 0; i < k.numClusters; i++ {
		k.centroids[i] = k.points[indices[i]]
	}
}

func (k *kmeans) findNearestCentroid(p *Point) (int, error) {
	minDistance := math.MaxFloat64
	nearestIndex := -1

	for i := 0; i < k.numClusters; i++ {
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
	for i := 0; i < k.numClusters; i++ {
		dist, err := last[i].SqDistanceTo(&now[i])
		if err != nil {
			return false, err
		}
		if  dist > k.epsilon {
			return false, nil
		}
	}
	return true, nil
}

func (k *kmeans) updateCentroids(numWorkers int) error {
	dim := k.points[0].Dimension()

	sumsPartial := make([][][]float64, numWorkers)
	for i := range sumsPartial {
	    sumsPartial[i] = make([][]float64, k.numClusters)
	    for j := range sumsPartial[i] {
	        sumsPartial[i][j] = make([]float64, dim)
	    }
	}
	
	countsPartial := make([][]int, numWorkers)
	for i := range countsPartial {
	    countsPartial[i] = make([]int, k.numClusters)
	}

	var wg sync.WaitGroup
	grainSize := (k.numPoints + numWorkers -1) / numWorkers

	for i := 0; i < numWorkers; i++ {
		workerId := i
		start := i * grainSize
		end := int(math.Min(float64(start + grainSize), float64(k.numPoints)))

		if start >= k.numPoints {
			break
		}

		wg.Add(1)
		go func (workerId int, start int, end int) {
			defer wg.Done()
			runtime.LockOSThread()
        	defer runtime.UnlockOSThread()
			
			for j := start; j < end; j++ {
				clusterId := k.assignments[j]
				point := k.points[j].Coordinates()

				for d := 0; d < dim; d++ {
					sumsPartial[workerId][clusterId][d] += point[d]
				}
				countsPartial[workerId][clusterId]++
			}
		}(workerId, start, end)
	}
	
	wg.Wait()

	for c := 0; c < k.numClusters; c++ {
		finalSum := make([]float64, dim)
		totalCount := 0

		for w := 0; w < numWorkers; w++ {
			totalCount += countsPartial[w][c]
			for d := 0; d < dim; d++ {
				finalSum[d] += sumsPartial[w][c][d]
			}
		}

		if totalCount > 0 {
			for d := 0; d < dim; d++ {
				finalSum[d] /= float64(totalCount)
			}

			point, err := NewPoint(finalSum)

			if err != nil {
				return err
			}

			k.centroids[c] = *point
		}
	}

	return nil
}

func (k *kmeans) clustering(numWorkers int) error {
	grainSize := (k.numPoints + numWorkers - 1) / numWorkers
	var wg sync.WaitGroup
	errChan := make(chan error, numWorkers)

	for i := 0; i < numWorkers; i++ {
		start := i * grainSize
		end := int(math.Min(float64(start+grainSize), float64(k.numPoints)))

		if start >= k.numPoints {
			break
		}

		wg.Add(1)
		go func (start int, end int) {
			defer wg.Done()
			runtime.LockOSThread()
        	defer runtime.UnlockOSThread()

			for j := start; j < end; j++ {
				idx, err := k.findNearestCentroid(&k.points[j])
                if err != nil {
                    select {
                    case errChan <- err:
                    default:
                    }
                    return
                }
                k.assignments[j] = idx
			}
		}(start, end)
	}

	wg.Wait()

	close(errChan)

	if len(errChan) > 0 {
	    return <-errChan
	}

	return nil
}

func (k *kmeans) Fit() error {
	err := k.FitWithArgs(300, runtime.NumCPU())
	
	if err != nil {
		return err
	}

	return nil
}

func (k *kmeans) FitWithArgs(maxIterations int, numWorkers int) error {
	lastCentroids := make([]Point, k.numClusters)
	iteration := 0
	copy(lastCentroids, k.centroids)
	k.clustering(numWorkers)
	k.updateCentroids(numWorkers)
	converged, err := k.centroidsConverged(lastCentroids, k.centroids)
	if err != nil {
		return err
	}
	iteration++

	for {
		if converged || iteration >= maxIterations {
			break
		}

		copy(lastCentroids, k.centroids)
		k.clustering(numWorkers)
		k.updateCentroids(numWorkers)
		converged, err = k.centroidsConverged(lastCentroids, k.centroids)
		if err != nil {
			return err
		}
		iteration++
	}
	return nil
}

func (k *kmeans) Centroids() []Point {
	return k.centroids
}

func (k *kmeans) Clusters() [][]Point {
	clusters := make([][]Point, k.numClusters)

	for i := 0; i < k.numClusters; i++ {
		clusters[i] = make([]Point, 0)
	}

	for i := 0; i < k.numPoints; i++ {
        clusterID := k.assignments[i]
        clusters[clusterID] = append(clusters[clusterID], k.points[i])
    }

	return clusters
}
