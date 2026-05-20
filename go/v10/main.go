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
	runtime.SetMutexProfileFraction(1)
	runtime.SetBlockProfileRate(1)
	cpuFile, _ := os.Create("v10/profile/cpu.prof")
	pprof.StartCPUProfile(cpuFile)
    tf, _ := os.Create("v10/profile/trace.out")
    trace.Start(tf)
    defer trace.Stop()
    defer tf.Close()
	defer pprof.StopCPUProfile()
	defer cpuFile.Close()
    // End Profile

    points, err := LoadPoints("../data/dataset_1000000x100_range_0.0_to_100.0.csv")
    if err != nil {
        fmt.Println("Error:",err)
        return
    }

    ai, err := Kmeans(3, points, 2026)

    if err != nil {
        fmt.Println("Error:",err)
        return
    }

    ai.Fit()
    //fmt.Println("Centroids:", ai.GetCentroids())
    //fmt.Println("Clusters:", ai.GetClusters())

    // Profile
	heapFile, _ := os.Create("v10/profile/heap.prof")
	defer heapFile.Close()
	runtime.GC()
	pprof.WriteHeapProfile(heapFile)
    // End Profile
}
