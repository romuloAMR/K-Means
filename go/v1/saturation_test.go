//go:build saturation
package main

import (
    "flag"
    "fmt"
    "sync"
    "testing"
    "time"
)

var (
    numThreads = flag.Int("threads", 4, "Número de threads paralelas (Atores)")
    numExecs   = flag.Int("execs", 20, "Quantidade total de execuções a realizar")
)

func TestMacroBenchmarkSaturation(t *testing.T) {
    fmt.Println("[Macro] Carregando dataset para a RAM...")
    pts, err := LoadPoints("../../data/dataset_1000000x100_range_0.0_to_100.0.csv")
    if err != nil {
        t.Fatalf("Falha ao carregar dados: %v", err)
    }
    fmt.Printf("[Macro] Iniciando teste V1: %d execuções divididas em %d threads...\n", *numExecs, *numThreads)

    jobQueue := make(chan int, *numExecs)
    for i := 1; i <= *numExecs; i++ {
        jobQueue <- i
    }
    close(jobQueue)

    var wg sync.WaitGroup
    startTime := time.Now()

    for w := 0; w < *numThreads; w++ {
        wg.Add(1)
        go func(workerID int) {
            defer wg.Done()
            for range jobQueue {
                localPoints := make([]Point, len(pts))
                copy(localPoints, pts)

                k, _ := Kmeans(3, localPoints, 2026)
                _ = k.Fit()
            }
        }(w)
    }

    wg.Wait()
    duration := time.Since(startTime)

    throughput := float64(*numExecs) / duration.Seconds()
    fmt.Println("\n========================================")
	fmt.Printf("Versão:                  V1\n")
    fmt.Printf("Tempo Total:             %v\n", duration)
    fmt.Printf("Vazão (Throughput):      %.2f execuções/seg\n", throughput)
    fmt.Printf("Latência Média/Instância: %v\n", time.Duration(int64(duration)/int64(*numExecs)))
    fmt.Println("========================================")
}