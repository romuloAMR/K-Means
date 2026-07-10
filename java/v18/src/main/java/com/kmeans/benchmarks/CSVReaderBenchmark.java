package com.kmeans.benchmarks;

import org.openjdk.jmh.annotations.*;
import org.apache.spark.sql.SparkSession;
import org.apache.spark.sql.Dataset;
import com.kmeans.CSVReader;
import com.kmeans.Point;

import java.util.concurrent.TimeUnit;

@State(Scope.Benchmark)
@Fork(1)
public class CSVReaderBenchmark {

    private SparkSession spark;
    private final String PATH = "/workspaces/K-Means/data/dataset_1000000x100_range_0.0_to_100.0.csv";

    @Setup(Level.Trial)
    public void setupTrial() {
        spark = SparkSession.builder()
                .appName("JMH-CSV-Reader")
                .master("local[*]")
                .getOrCreate();
        spark.sparkContext().setLogLevel("ERROR");
    }

    @TearDown(Level.Trial)
    public void tearDownTrial() {
        if (spark != null) {
            spark.stop();
        }
    }

    @Benchmark
    @BenchmarkMode(Mode.SingleShotTime)
    @OutputTimeUnit(TimeUnit.SECONDS)
    @Warmup(iterations = 3)
    @Measurement(iterations = 6)
    public long benchmarkLoadPoints() {
        Dataset<Point> ds = CSVReader.loadPoints(spark, PATH);
        return ds.count();
    }
}
