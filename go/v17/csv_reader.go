package main

import (
	"bufio"
	"bytes"
	"context"
	"fmt"
	"os"
	"runtime"
	"strconv"
	"syscall"
	"golang.org/x/sync/errgroup"
)

type Job struct {
    segIdx  int
    segment Segment
}

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
        extraBytes := int64(0)
        for {
            _, err := file.Read(buffer)
            if err != nil {
                break
            }
            extraBytes++
            if buffer[0] == '\n' {
                break
            }
        }

        actualEnd := endCandidate + extraBytes
        segments = append(segments, Segment{start: start, size: actualEnd - start})
        currentPos = actualEnd
    }

    return segments, nil
}

type ChannelResult struct {
    segIdx int
    points []Point
}

func LoadPoints(parentCtx context.Context, path string) ([]Point, error) {
	segments, err := Segments(path)
	if err != nil {
		return nil, err
	}

	file, err := os.Open(path)
	if err != nil {
		return nil, err
	}
	defer file.Close()

	info, err := file.Stat()
	if err != nil {
		return nil, err
	}
	totalSize := info.Size()

	data, err := syscall.Mmap(int(file.Fd()), 0, int(totalSize), syscall.PROT_READ, syscall.MAP_SHARED)
	if err != nil {
		return nil, err
	}
	defer syscall.Munmap(data)

	numSegments := len(segments)
	jobsChan := make(chan Job, numSegments)
	resultsChan := make(chan ChannelResult, numSegments)
	g, ctx := errgroup.WithContext(parentCtx)

	numWorkers := runtime.NumCPU()
	for w := 0; w < numWorkers; w++ {
		g.Go(func() error {
			for {
				select {
				case <-ctx.Done():
					return ctx.Err()

				case job, ok := <-jobsChan:
					if !ok {
						return nil
					}

					workerData := data[job.segment.start : job.segment.start+job.segment.size]
					reader := bytes.NewReader(workerData)
					scanner := bufio.NewScanner(reader)

					var localPoints []Point

					if job.segIdx == 0 {
						if scanner.Scan() {
						}
					}

					for scanner.Scan() {
						line := bytes.TrimSpace(scanner.Bytes())
						if len(line) == 0 {
							continue
						}

						p, err := processLine(line)
						if err != nil {
							return fmt.Errorf("falha crítica no segmento %d: %w", job.segIdx, err)
						}
						if p != nil {
							localPoints = append(localPoints, *p)
						}
					}

					if len(localPoints) > 0 {
						resultsChan <- ChannelResult{segIdx: job.segIdx, points: localPoints}
					}
				}
			}
		})
	}

	for i, segment := range segments {
		jobsChan <- Job{segIdx: i, segment: segment}
	}
	close(jobsChan)

	go func() {
		_ = g.Wait()
		close(resultsChan)
	}()

	orderedBatches := make([][]Point, numSegments)
	totalPoints := 0

	for res := range resultsChan {
		orderedBatches[res.segIdx] = res.points
		totalPoints += len(res.points)
	}

	if err := g.Wait(); err != nil {
		return nil, err
	}

	allPoints := make([]Point, 0, totalPoints)
	for i := 0; i < numSegments; i++ {
		if orderedBatches[i] != nil {
			allPoints = append(allPoints, orderedBatches[i]...)
		}
	}

	return allPoints, nil
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
