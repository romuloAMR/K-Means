package main

import (
	"encoding/csv"
	"fmt"
	"io"
	"os"
	"strconv"
)

func LoadPoints(path string) ([]Point, error) {
	file, err := os.Open(path)
	if err != nil {
		return nil, fmt.Errorf("problem opening the file: %w", err)
	}
	defer file.Close()

	return LoadPointsFromReader(file)
}

func LoadPointsFromReader(r io.Reader) ([]Point, error) {
	reader := csv.NewReader(r)

	_, err := reader.Read()
	if err != nil {
		if err == io.EOF {
			return []Point{}, nil
		}
		return nil, fmt.Errorf("error skipping the header: %w", err)
	}

	var points []Point

	for {
		line, err := reader.Read()
        if err == io.EOF {
			break
		}
        if err != nil {
			return nil, fmt.Errorf("problem reading a line: %w", err)
		}
		if len(line) == 0 || (len(line) == 1 && line[0] == ""){
			continue
		}

        point, err := lineToPoint(line)
        if err != nil {
			return nil, err
		}
        
        points = append(points, point)
    }

    return points, nil
}

func lineToPoint(line []string) (Point, error) {
    rowFloats := make([]float64, len(line))

    for i, value := range line {
        f, err := strconv.ParseFloat(value, 64)
        if err != nil {
			return Point{}, fmt.Errorf("error converting value '%s': %w", value, err)
		}
        rowFloats[i] = f
    }

    return Point{position: rowFloats}, nil
}
