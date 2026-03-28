package com.kmeans;

import java.util.List;

public class Main {
    public static void main(String[] args) {
        
        try {
            List<Point> points = CSVReader.loadPoints("../data/dataset_1000000x100_range_0.0_to_100.0.csv");
            Kmeans ai = new Kmeans(3, points, 2026);
            ai.fit();
            System.err.printf("Centroids: %s%n", ai.getCentroids());
            System.err.printf("Clusters: %s%n", ai.getClusters());
        } catch (Exception e){
            e.printStackTrace();
        }
    }
}
