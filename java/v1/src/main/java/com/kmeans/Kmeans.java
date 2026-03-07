package com.kmeans;

import java.util.ArrayList;
import java.util.List;
import java.util.Random;

public class Kmeans {
    
    private final int numClusters;
    private final List<Point> points;
    private List<List<Point>> clusters;
    private List<Point> centroids;
    
    public Kmeans(int numClusters, List<Point> points) {
        if(points == null || points.size() < numClusters){
            throw new IllegalArgumentException("Number of clusters greater than the number of points");
        }

        this.points = points;
        this.numClusters = numClusters;
        this.createClusters();
    }

    private void createClusters() {
        this.clusters = new ArrayList<>();
        for(int i = 0; i < this.numClusters; i++){
            this.clusters.add(new ArrayList<>());
        }
    }

    private void randCentroids() {
        this.centroids = new ArrayList<>();
        List<Point> pointsCopy = new ArrayList<>(this.points);
        Random random = new Random();
        for (int i = 0; i < this.numClusters; i++){
            int num = random.nextInt(pointsCopy.size());
            this.centroids.add(pointsCopy.get(num));
            pointsCopy.remove(num);
        }
    }

    private void updateCentroids() {
        List<Point> newCentroids = new ArrayList<>();

        for (int i = 0; i < this.numClusters; i++) {
            List<Point> cluster = this.clusters.get(i);
            
            if (cluster.isEmpty()) {
                newCentroids.add(this.centroids.get(i));
                continue;
            }

            int dim = cluster.get(0).getDimension();
            Point sum = new Point(new double[dim]); 

            for (Point point : cluster) {
                sum = sum.add(point);
            }

            newCentroids.add(sum.divide(cluster.size()));
        }
        this.centroids = newCentroids;
    }

    private int findNearestCentroid(Point p) {
        double minDistance = Double.MAX_VALUE;
        int nearestIndex = -1;
        
        for (int i = 0; i < centroids.size(); i++) {
            double dist = p.distanceTo(centroids.get(i));
            if (dist < minDistance) {
                minDistance = dist;
                nearestIndex = i;
            }
        }
        return nearestIndex;
    }

    private boolean centroidsConverged(List<Point> last, List<Point> now) {
        double epsilon = 0.00001;
        for (int i = 0; i < this.numClusters; i++) {
            if (last.get(i).distanceTo(now.get(i)) > epsilon) {
                return false;
            }
        }
        return true;
    }

    public void fit() {
        this.randCentroids();
        List<Point> lastCentroids;
        
        do {
            lastCentroids = new ArrayList<>(this.centroids);

            for (List<Point> cluster : this.clusters) {
                cluster.clear();
            }

            for (Point point : this.points) {
                int indexCluster = this.findNearestCentroid(point);
                this.clusters.get(indexCluster).add(point);
            }

            this.updateCentroids();
        } while (!centroidsConverged(lastCentroids, this.centroids));
    }

    public List<Point> getCentroids() {
        return centroids;
    }

    public List<List<Point>> getClusters() {
        return clusters;
    }
}
