package com.kmeans.benchmarks;

import org.openjdk.jmh.annotations.*;

import com.kmeans.CSVReader;
import com.kmeans.Kmeans;
import com.kmeans.Point;

import java.util.concurrent.TimeUnit;
import java.util.List;
import java.util.ArrayList;

@State(Scope.Benchmark)
@Fork(1)
public class KmeansBenchmark {

    private List<Point> cachedPoints;

    @Setup(Level.Trial)
    public void setupTrial() throws Exception {
        String path = "../../data/dataset_1000000x100_range_0.0_to_100.0.csv";
        this.cachedPoints = CSVReader.loadPoints(path);
    }

    @State(Scope.Thread)
    public static class BenchmarkState {
        Kmeans kmeans;
        Point singlePoint;
        int iterationCounter = 0;

        @Setup(Level.Invocation)
        public void setupInvocation(KmeansBenchmark mainState) throws Exception {
            this.kmeans = new Kmeans(3, mainState.cachedPoints, 2026);
            this.singlePoint = mainState.cachedPoints.get(0);
        }
    }

    @Benchmark
    @BenchmarkMode(Mode.AverageTime)
    @OutputTimeUnit(TimeUnit.NANOSECONDS)
    @Warmup(iterations = 3, time = 1)
    @Measurement(iterations = 6, time = 1)
    public int benchmarkFindNearestCentroidSerial(BenchmarkState state) throws Exception {
        return state.kmeans.findNearestCentroid(state.singlePoint);
    }

    @Benchmark
    @BenchmarkMode(Mode.SingleShotTime)
    @OutputTimeUnit(TimeUnit.SECONDS)
    @Warmup(iterations = 3)
    @Measurement(iterations = 6)
    public void benchmarkKMeansFit() throws Exception {
        List<Point> iterPoints = new ArrayList<>(this.cachedPoints); 
        Kmeans k = new Kmeans(3, iterPoints, 2026);
        k.fit(); 
    }
}
