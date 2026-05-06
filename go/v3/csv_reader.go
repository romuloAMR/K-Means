package main

import (
	"bytes"
	"os"
	"runtime"
	"strconv"
	"sync"
)

type Segment struct {
	start int64
	size  int64
}

func Segments(filePath string) ([]Segment, error) {
	const oneMB = 1048576
	const scalarForWorkers = 1

	file, err := os.Open(filePath)
	if err != nil {
		return nil, err
	}
	defer file.Close()

	info, err := file.Stat()
	if err != nil {
		return nil, err
	}
	totalSize := info.Size() 
	cores := runtime.NumCPU() * scalarForWorkers

	targetSize := totalSize / int64(cores)
	if targetSize < oneMB {
		targetSize = oneMB
	}

	var segments []Segment
	var currentPos int64 = 0

	for currentPos < totalSize {
		start := currentPos
		endCandidate := currentPos + targetSize

		if endCandidate >= totalSize {
			segments = append(segments, Segment{start: start, size: totalSize - start})
			break
		}

		_, err := file.Seek(endCandidate, 0)
		if err != nil {
			return nil, err
		}

		buffer := make([]byte, 1)
		for {
			_, err := file.Read(buffer)
			if err != nil {
				break
			}
			if buffer[0] == '\n' {
				break
			}
		}

		actualEnd, _ := file.Seek(0, 1)
		segments = append(segments, Segment{start: start, size: actualEnd - start})
		currentPos = actualEnd
	}

	return segments, nil
}

func LoadPoints(path string) ([]Point, error) {
    segments, err := Segments(path)
    if err != nil {
        return nil, err
    }
    numSegments := len(segments)
    partialResults := make ([][]Point, numSegments)
    var wg sync.WaitGroup

    file, err := os.Open(path)
	if err != nil {
		return nil, err
	}
	defer file.Close()

    for i := 0; i < numSegments; i++ {
        wg.Add(1)
        go func (index int, segment Segment)  {
            defer wg.Done()
            
            var pointsPartition []Point
			buffer := make([]byte, segment.size)

			_, err := file.ReadAt(buffer, segment.start)
			if err != nil {
				return
			}

			remaining := buffer
			if segment.start == 0 {
				if idx := bytes.IndexByte(remaining, '\n'); idx != -1 {
					remaining = remaining[idx+1:]
				}
			}

			lines := bytes.Split(remaining, []byte("\n"))
			for _, line := range lines {
				line = bytes.TrimSpace(line)
				if len(line) > 0 {
					p, err := processLine(line)
                    if err != nil {
                        return
                    }
					if p != nil {
						pointsPartition = append(pointsPartition, *p)
					}
				}
			}
			partialResults[index] = pointsPartition
            
        }(i, segments[i])
    }

    wg.Wait()

    totalPoints := 0
    for _, partition := range partialResults {
        totalPoints += len(partition)
    }

    points := make([]Point, 0, totalPoints)
    for _, partition := range partialResults {
        if partition != nil {
            points = append(points, partition...)
        }
    }

    return points, nil
}

func processLine(line []byte) (*Point, error) {
	parts := bytes.Split(line, []byte(","))
	coords := make([]float64, len(parts))
	
	for i, part := range parts {
		val, err := strconv.ParseFloat(string(bytes.TrimSpace(part)), 64)
		if err != nil {
			return nil, err
		}
		coords[i] = val
	}

    point, err := NewPoint(coords)
    if err != nil {
        return nil, err
    }

	return point, nil
}
