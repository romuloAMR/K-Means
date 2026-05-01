package com.kmeans;

import java.util.ArrayList;
import java.util.List;

public class Kmeans {
    
    private final int numClusters;
    private final List<Point> points;
    private List<List<Point>> clusters;
    private List<Point> centroids;
    
    public Kmeans(int numClusters, List<Point> points, long seed) {
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
        int[] indices = {10, 532, 9012};
        for (int i = 0; i < this.numClusters; i++) {
            this.centroids.add(new Point(this.points.get(indices[i])));;
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
                sum.accumulatedAdd(point);
            }

            sum.accumulatedDivide(cluster.size());

            newCentroids.add(sum);
        }
        this.centroids = newCentroids;
    }

    private int findNearestCentroid(Point p) {
        double minDistance = Double.MAX_VALUE;
        int nearestIndex = -1;
        
        for (int i = 0; i < centroids.size(); i++) {
            double dist = p.sqDistanceTo(centroids.get(i));
            if (dist < minDistance) {
                minDistance = dist;
                nearestIndex = i;
            }
        }
        return nearestIndex;
    }

    private boolean centroidsConverged(List<Point> last, List<Point> now) {
        double epsilon = 1e-10;
        for (int i = 0; i < this.numClusters; i++) {
            if (last.get(i).sqDistanceTo(now.get(i)) > epsilon) {
                return false;
            }
        }
        return true;
    }

    public void fit() {
        this.fit(300);
    }

    public void fit(int maxIterations) {
        this.randCentroids();
        List<Point> lastCentroids;
        int iteration = 0;
        boolean converged = false;
        
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
            converged = centroidsConverged(lastCentroids, this.centroids);
            iteration++;
        } while (!converged && iteration < maxIterations);
    }

    public List<Point> getCentroids() {
        return centroids;
    }

    public List<List<Point>> getClusters() {
        return clusters;
    }
}
