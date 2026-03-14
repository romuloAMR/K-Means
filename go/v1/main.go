package main

import (
    "fmt"
)

func main() {
    points, err := LoadPoints("../data/dataset_10x3_range_0.0_to_100.0.csv")
    if err != nil {
        fmt.Println("Error:",err)
        return
    }

    model, err := Kmeans(4, points, 2026)

    if err != nil {
        fmt.Println("Error:",err)
        return
    }

    model.Fit()
    fmt.Println("Centroids:", model.GetCentroids())
    fmt.Println("Clusters:", model.GetClusters())

}
