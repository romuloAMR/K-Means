package com.kmeans.benchmarks;

import org.openjdk.jmh.annotations.*;

import com.kmeans.CSVReader;
import com.kmeans.Kmeans;
import com.kmeans.Point;

import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;
import java.util.List;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;

@State(Scope.Benchmark)
@Fork(1)
public class KmeansBenchmark {

    private List<Point> cachedPoints;
    private int numWorkers;
    private ExecutorService executor;

    @Setup(Level.Trial)
    public void setupTrial() throws Exception {
        Path path = Paths.get("/workspaces/K-Means/data/dataset_1000000x100_range_0.0_to_100.0.csv");
        this.cachedPoints = CSVReader.loadPoints(path);
        this.numWorkers = Runtime.getRuntime().availableProcessors();
        this.executor = Executors.newFixedThreadPool(this.numWorkers);
    }

    @TearDown(Level.Trial)
    public void tearDownTrial() {
        if (this.executor != null) {
            this.executor.shutdownNow(); 
        }
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
    @OutputTimeUnit(TimeUnit.MILLISECONDS)
    @Warmup(iterations = 3, time = 1)
    @Measurement(iterations = 6, time = 1)
    public void benchmarkClusteringStep(BenchmarkState state) throws Exception {
        state.kmeans.getCentroids()[0].getCoordinates()[0] = state.iterationCounter++;
        state.kmeans.clustering(this.executor, this.numWorkers);
    }

    @Benchmark
    @BenchmarkMode(Mode.AverageTime)
    @OutputTimeUnit(TimeUnit.MILLISECONDS)
    @Warmup(iterations = 3, time = 1)
    @Measurement(iterations = 6, time = 1)
    public void benchmarkUpdateCentroidsStep(BenchmarkState state) throws Exception {
        state.kmeans.getAssignments()[0] = (state.iterationCounter++ % 2 == 0) ? 0 : 1;
        state.kmeans.updateCentroids(this.executor, this.numWorkers);
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
