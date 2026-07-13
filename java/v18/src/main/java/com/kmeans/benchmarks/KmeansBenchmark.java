package com.kmeans.benchmarks;

import org.openjdk.jmh.annotations.*;
import org.apache.spark.sql.SparkSession;
import org.apache.spark.sql.Dataset;
import com.kmeans.CSVReader;
import com.kmeans.Kmeans;
import com.kmeans.Point;

import java.util.concurrent.TimeUnit;
import java.util.List;

@State(Scope.Benchmark)
@Fork(1)
public class KmeansBenchmark {

    private SparkSession spark;
    private Dataset<Point> cachedDataset;
    private Point[] initialCentroids;

    @Setup(Level.Trial)
    public void setupTrial() {
        spark = SparkSession.builder()
                .appName("JMH-KMeans-Spark")
                .master("local[*]")
                .getOrCreate();

        spark.sparkContext().setLogLevel("ERROR");

        String path = "/workspaces/K-Means/data/dataset_1000000x100_range_0.0_to_100.0.csv";
        cachedDataset = CSVReader.loadPoints(spark, path);
        cachedDataset.cache();
        cachedDataset.count(); 

        List<Point> sample = cachedDataset.limit(3).collectAsList();
        initialCentroids = sample.toArray(new Point[0]);
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
    public Point[] benchmarkKMeansFitSpark() {
        Kmeans kmeans = new Kmeans(3, initialCentroids);
        kmeans.fit(cachedDataset, spark, 10);
        return kmeans.getCentroids(); 
    }
}
