package com.kmeans.benchmarks;

import org.openjdk.jmh.annotations.*;
import org.apache.spark.sql.Dataset;
import org.apache.spark.sql.SparkSession;

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
                .appName("JMH-Spark-Benchmark")
                .master("local[*]")
                .config("spark.ui.enabled", "false") 
                .getOrCreate();

        String path = "/workspaces/K-Means/data/dataset_1000000x100_range_0.0_to_100.0.csv";
        cachedDataset = CSVReader.loadPoints(spark, path);
        cachedDataset.cache();
        cachedDataset.count(); 

        List<Point> pontosIniciaisLista = cachedDataset.limit(3).collectAsList();
        initialCentroids = pontosIniciaisLista.toArray(new Point[0]);
    }

    @TearDown(Level.Trial)
    public void tearDownTrial() {
        if (spark != null) {
            spark.stop();
        }
    }

    @Benchmark
    @BenchmarkMode(Mode.AverageTime)
    @OutputTimeUnit(TimeUnit.SECONDS)
    @Warmup(iterations = 2, time = 1)
    @Measurement(iterations = 5, time = 1)
    public void benchmarkKMeans_UmaIteracao() {
        Kmeans k = new Kmeans(3, initialCentroids);
        k.fit(cachedDataset, spark, 1);
    }

    @Benchmark
    @BenchmarkMode(Mode.SingleShotTime)
    @OutputTimeUnit(TimeUnit.SECONDS)
    @Warmup(iterations = 1)
    @Measurement(iterations = 3)
    public void benchmarkKMeansFit_Completo() {
        Kmeans k = new Kmeans(3, initialCentroids);
        k.fit(cachedDataset, spark, 10);
    }
}
