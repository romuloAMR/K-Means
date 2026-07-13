package main

import (
    "bufio"
    "bytes"
    "os"
    "runtime"
    "strconv"
    "sync"
    "syscall"
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

func LoadPoints(path string) ([]Point, error) {
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
    resultsChan := make(chan ChannelResult, numSegments)
    var wg sync.WaitGroup

    for i, segment := range segments {
        wg.Add(1)
        go func(segIdx int, segment Segment) {
            defer wg.Done()

            workerData := data[segment.start : segment.start+segment.size]
            reader := bytes.NewReader(workerData)
            scanner := bufio.NewScanner(reader)

            var localPoints []Point

            if segIdx == 0 {
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
                    continue
                }
                if p != nil {
                    localPoints = append(localPoints, *p)
                }
            }
            
            if len(localPoints) > 0 {
                resultsChan <- ChannelResult{segIdx: segIdx, points: localPoints}
            }
        }(i, segment)
    }

    go func() {
        wg.Wait()
        close(resultsChan)
    }()

    orderedBatches := make([][]Point, numSegments)
    totalPoints := 0

    for res := range resultsChan {
        orderedBatches[res.segIdx] = res.points
        totalPoints += len(res.points)
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
