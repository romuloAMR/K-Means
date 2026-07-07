//go:build saturation
package main

import (
	"context"
	"flag"
	"fmt"
	"runtime"
	"sync"
	"testing"
	"time"
)

var (
	numThreads = flag.Int(
		"threads",
		runtime.NumCPU(),
		"Quantidade de workers",
	)

	numExecs = flag.Int(
		"execs",
		runtime.NumCPU(),
		"Quantidade total de execuções",
	)
)

func TestMacroBenchmarkSaturation(t *testing.T) {
	path := "/workspaces/K-Means/data/dataset_1000000x100_range_0.0_to_100.0.csv"

	fmt.Println("========================================")
	fmt.Printf("Threads:      %d\n", *numThreads)
	fmt.Printf("Executions:   %d\n", *numExecs)
	fmt.Printf("CPUs:         %d\n", runtime.NumCPU())
	fmt.Println("========================================")

	jobQueue := make(chan int, *numExecs)

	for i := 0; i < *numExecs; i++ {
		jobQueue <- i
	}
	close(jobQueue)

	var wg sync.WaitGroup

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Minute)
	defer cancel()

	start := time.Now()

	for w := 0; w < *numThreads; w++ {
		wg.Add(1)

		go func(workerID int) {
			defer wg.Done()

			for range jobQueue {
				if ctx.Err() != nil {
					return 
				}

				points, err := LoadPoints(ctx, path)
				if err != nil {
					t.Errorf("worker %d load error: %v", workerID, err)
					return
				}

				k, err := Kmeans(3, points, 2026)
				if err != nil {
					t.Errorf("worker %d kmeans error: %v", workerID, err)
					return
				}

				if err := k.Fit(ctx); err != nil {
					if err != context.DeadlineExceeded && err != context.Canceled {
						t.Errorf("worker %d fit error: %v", workerID, err)
					}
					return
				}
			}
		}(w)
	}

	wg.Wait()

	total := time.Since(start)
	
	var throughput float64
	if total.Seconds() > 0 {
	    throughput = float64(*numExecs) / total.Seconds()
	}
	avgLatency := total / time.Duration(*numExecs)

	fmt.Println("========================================")
	fmt.Printf("Total Time:   %.4fs\n", total.Seconds())
	fmt.Printf("Throughput:   %.2f exec/s\n", throughput)
	fmt.Printf("Avg Latency:  %.4f ms\n", avgLatency.Seconds()*1000)
	fmt.Println("========================================")

	fmt.Printf(
		"CSV_RESULT,%d,%.4f,%.2f,%.4f\n",
		*numThreads,
		total.Seconds(),
		throughput,
		avgLatency.Seconds()*1000,
	)
}
