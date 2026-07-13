package com.kmeans.benchmarks;

import org.openjdk.jmh.annotations.*;

import com.kmeans.Point;

import java.util.concurrent.TimeUnit;

@BenchmarkMode(Mode.AverageTime)
@OutputTimeUnit(TimeUnit.NANOSECONDS)
@State(Scope.Thread)
@Warmup(iterations = 3, time = 1)
@Measurement(iterations = 6, time = 1)
@Fork(1)
public class PointBenchmark {

    private Point p1;
    private Point p2;
    private Point base1;
    private Point baseDivide;

    @Setup(Level.Invocation)
    public void setup() throws Exception {
        p1 = new Point(new float[]{1, 2, 3, 4, 5});
        p2 = new Point(new float[]{5, 4, 3, 2, 1});
        base1 = new Point(new float[]{1, 2, 3, 4, 5}); 
        baseDivide = new Point(new float[]{10, 20, 30});
    }

    @Benchmark
    public double benchmarkSqDistance() throws Exception {
        return p1.sqDistanceTo(p2);
    }

    @Benchmark
    public Point benchmarkAccumulatedAddPointSafe() throws Exception {
        base1.accumulatedAdd(p2);
        return base1;
    }

    @Benchmark
    public Point benchmarkAccumulatedDivide() throws Exception {
        baseDivide.accumulatedDivide(2.0f);
        return baseDivide;
    }
}
