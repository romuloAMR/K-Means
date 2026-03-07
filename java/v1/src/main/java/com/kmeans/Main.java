package com.kmeans;

import java.util.List;

public class Main {
    public static void main(String[] args) {
        
        try {
            List<Point> points = CSVReader.loadPoints("");
            Kmeans ai = new Kmeans(3, points);
            ai.fit();
            System.err.printf("Centroids: {}", ai.getCentroids());
            System.err.printf("Clusters: {}", ai.getClusters());
        } catch (Exception e){
            e.printStackTrace();
        }
        System.err.println("Love, Faith, and Hope - V1");
    }
}
