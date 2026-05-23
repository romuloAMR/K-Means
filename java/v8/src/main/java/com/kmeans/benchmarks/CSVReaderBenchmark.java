package com.kmeans.benchmarks;

import org.openjdk.jmh.annotations.*;

import com.kmeans.CSVReader;
import com.kmeans.Point;

import java.util.concurrent.TimeUnit;
import java.nio.charset.StandardCharsets;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.List;

@State(Scope.Benchmark)
@Fork(1)
public class CSVReaderBenchmark {

    @State(Scope.Benchmark)
    public static class FileState {
        public Path path = Paths.get("./data/dataset_1000000x100_range_0.0_to_100.0.csv"); 
    }

    @State(Scope.Benchmark)
    public static class LineState {
        public byte[] line = "100.0, 20.0, 30.5, 40.3, 21.7".getBytes(StandardCharsets.UTF_8);
    }

    @Benchmark
    @BenchmarkMode(Mode.SingleShotTime)
    @OutputTimeUnit(TimeUnit.SECONDS)
    @Warmup(iterations = 3)
    @Measurement(iterations = 6)
    public List<Point> benchmarkLoadPoints(FileState state) throws Exception {
        return CSVReader.loadPoints(state.path);
    }

    @Benchmark
    @BenchmarkMode(Mode.AverageTime)
    @OutputTimeUnit(TimeUnit.MICROSECONDS)
    @Warmup(iterations = 3, time = 1)
    @Measurement(iterations = 6, time = 1)
    public Point benchmarkProcessLine(LineState state) throws Exception {
        return CSVReader.processLine(state.line);
    }
}
