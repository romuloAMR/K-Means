package main

import (
	"context"
	"errors"
	"math"
	"runtime"
	"golang.org/x/sync/errgroup"
)

type PartialSum struct {
	sums [][]float64
	counts []int
}

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

	indices := make([]int, numClusters)
	for i := 0; i < numClusters; i++ {
		indices[i] = i
	}
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
		if dist > k.epsilon {
			return false, nil
		}
	}
	return true, nil
}

func (k *kmeans) updateCentroids(ctx context.Context, numWorkers int) error {
	dim := k.points[0].Dimension()
	
	jobs := make(chan PartialSum, numWorkers)
	g, workerCtx := errgroup.WithContext(ctx)
	grainSize := (k.numPoints + numWorkers - 1) / numWorkers

	for i := 0; i < numWorkers; i++ {
		start := i * grainSize
		end := int(math.Min(float64(start+grainSize), float64(k.numPoints)))

		if start >= k.numPoints {
			break
		}

		g.Go(func() error {
			localSums := make([][]float64, k.numClusters)
			for c := 0; c < k.numClusters; c++ {
				localSums[c] = make([]float64, dim)
			}
			localCounts := make([]int, k.numClusters)

			for j := start; j < end; j++ {
				if workerCtx.Err() != nil {
					return workerCtx.Err()
				}

				clusterId := k.assignments[j]
				point := k.points[j].Coordinates()

				for d := 0; d < dim; d++ {
					localSums[clusterId][d] += point[d]
				}
				localCounts[clusterId]++
			}
			jobs <- PartialSum{sums: localSums, counts: localCounts}
			return nil
		})
	}

	go func() {
		_ = g.Wait()
		close(jobs)
	}()

	resultados := make([]PartialSum, 0, numWorkers)
	for partial := range jobs {
		resultados = append(resultados, partial)
	}

	if err := g.Wait(); err != nil {
		return err
	}

	for c := 0; c < k.numClusters; c++ {
		totalCount := 0
		sum := make([]float64, dim)

		for _, partial := range resultados {
			totalCount += partial.counts[c]
			for d := 0; d < dim; d++ {
				sum[d] += partial.sums[c][d]
			}
		}

		if totalCount > 0 {
			for d := 0; d < dim; d++ {
				sum[d] /= float64(totalCount)
			}

			point, err := NewPoint(sum)
			if err != nil {
				return err
			}

			k.centroids[c] = *point
		}
	}

	return nil
}

func (k *kmeans) clustering(ctx context.Context, numWorkers int) error {
	grainSize := (k.numPoints + numWorkers - 1) / numWorkers
	g, workerCtx := errgroup.WithContext(ctx)

	for i := 0; i < numWorkers; i++ {
		start := i * grainSize
		end := start + grainSize
		if end > k.numPoints {
			end = k.numPoints
		}

		if start >= k.numPoints {
			continue
		}

		g.Go(func() error {
			for j := start; j < end; j++ {
				if workerCtx.Err() != nil {
					return workerCtx.Err()
				}

				idx, err := k.findNearestCentroid(&k.points[j])
				if err != nil {
					return err
				}
				k.assignments[j] = idx
			}
			return nil
		})
	}

	return g.Wait()
}

func (k *kmeans) Fit(ctx context.Context) error {
	return k.FitWithArgs(ctx, 300, runtime.NumCPU())
}

func (k *kmeans) FitWithArgs(ctx context.Context, maxIterations int, numWorkers int) error {
	lastCentroids := make([]Point, k.numClusters)
	iteration := 0
	copy(lastCentroids, k.centroids)

	err := k.clustering(ctx, numWorkers)
	if err != nil {
		return err
	}

	err = k.updateCentroids(ctx, numWorkers)
	if err != nil {
		return err
	}

	converged, err := k.centroidsConverged(lastCentroids, k.centroids)
	if err != nil {
		return err
	}
	iteration++

	for {
		if ctx.Err() != nil {
			return ctx.Err()
		}

		if converged || iteration >= maxIterations {
			break
		}

		copy(lastCentroids, k.centroids)
		
		err := k.clustering(ctx, numWorkers)
		if err != nil {
			return err
		}

		err = k.updateCentroids(ctx, numWorkers)
		if err != nil {
			return err
		}
		
		converged, err = k.centroidsConverged(lastCentroids, k.centroids)
		if err != nil {
			return err
		}
		iteration++
	}
	return nil
}

func (k *kmeans) Assignments() []int {
	cloned := make([]int, len(k.assignments))
	copy(cloned, k.assignments)
	return cloned
}

func (k *kmeans) Centroids() []Point {
	cloned := make([]Point, len(k.centroids))
	copy(cloned, k.centroids)
	return cloned
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
