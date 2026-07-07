package main

import (
	"context"
	"fmt"
)

func main() {
	ctx := context.Background()
	points, err := LoadPoints(ctx, "/workspaces/K-Means/data/dataset_1000000x100_range_0.0_to_100.0.csv",)
	if err != nil {
		fmt.Println("Error:", err)
		return
	}

	ai, err := Kmeans(3, points, 2026)
	if err != nil {
		fmt.Println("Error:", err)
		return
	}

	ai.Fit(ctx)
}
