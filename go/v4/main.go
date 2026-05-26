package main

import (
	"fmt"
	"os"
	"runtime"
	"runtime/pprof"
    "runtime/trace"
)

func main() {
    // Profile
	cpuFile, _ := os.Create("v4/profile/cpu.prof")
    defer cpuFile.Close()
    pprof.StartCPUProfile(cpuFile)
    defer pprof.StopCPUProfile()
    tf, _ := os.Create("v4/profile/trace.out")
    defer tf.Close()
    trace.Start(tf)
    defer trace.Stop()
    // End Profile

	points, err := LoadPoints("../data/dataset_1000000x100_range_0.0_to_100.0.csv")
	if err != nil {
		fmt.Println("Error:", err)
		return
	}

	ai, err := Kmeans(3, points, 2026)
	if err != nil {
		fmt.Println("Error:", err)
		return
	}

	ai.Fit()
    //fmt.Println("Centroids:", ai.GetCentroids())
    //fmt.Println("Clusters:", ai.GetClusters())

    // Profile
	heapFile, _ := os.Create("v4/profile/heap.prof")
	runtime.GC()
	pprof.WriteHeapProfile(heapFile)
	defer heapFile.Close()
    // End Profile
}
