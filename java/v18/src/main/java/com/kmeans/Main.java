package com.kmeans;

import org.apache.spark.sql.Dataset;
import org.apache.spark.sql.SparkSession;

import java.util.List;

public class Main {
    public static void main(String[] args) {
        SparkSession spark = SparkSession.builder()
                .appName("KMeans-Distribuido")
                .master("local[*]") 
                .getOrCreate();

        try {
            String path = "/workspaces/K-Means/data/dataset_1000000x100_range_0.0_to_100.0.csv";            
            Dataset<Point> dataset = CSVReader.loadPoints(spark, path);
            dataset.cache();

            List<Point> pontosIniciaisLista = dataset.limit(3).collectAsList();
            Point[] initialCentroids = pontosIniciaisLista.toArray(new Point[0]);

            int numClusters = 3;
            Kmeans ai = new Kmeans(numClusters, initialCentroids);
            int maxIterations = 300;
            ai.fit(dataset, spark, maxIterations);

        } catch (Exception e){
            e.printStackTrace();
        } finally {
            spark.stop();
        }
    }
}
