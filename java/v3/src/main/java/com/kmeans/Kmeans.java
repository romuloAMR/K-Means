package com.kmeans;

import java.util.ArrayList;
import java.util.List;

public class Kmeans {
    
    private final int numClusters;
    private final Point[] points;
    private int[] assignments;
    private Point[] centroids;
    private final int numPoints;
    private final double epsilon;
    
    public Kmeans(int numClusters, List<Point> points, long seed) {
        if(points == null || points.size() < numClusters){
            throw new IllegalArgumentException("Number of clusters greater than the number of points");
        }

        this.numClusters = numClusters;
        this.epsilon = 1e-10;
        this.numPoints = points.size();
        this.points = new Point[this.numPoints];
        for (int i = 0; i < this.numPoints; i++) {
            this.points[i] = points.get(i);
        }
        this.assignments = new int[this.numPoints];
        this.centroids = new Point[this.numClusters];
        
        int[] indices = {10, 532, 9012};
        for (int i = 0; i < this.numClusters; i++) {
            this.centroids[i] = new Point(this.points[indices[i]]);
        }
    }

    private int findNearestCentroid(Point p) {
        double minDistance = Double.MAX_VALUE;
        int nearestIndex = -1;
        
        for (int i = 0; i < centroids.length; i++) {
            double dist = p.sqDistanceTo(centroids[i]);
            if (dist < minDistance) {
                minDistance = dist;
                nearestIndex = i;
            }
        }
        return nearestIndex;
    }

    private boolean centroidsConverged(Point[] last, Point[] now) {
        for (int i = 0; i < this.numClusters; i++) {
            if (last[i].sqDistanceTo(now[i]) > this.epsilon) {
                return false;
            }
        }
        return true;
    }

    private void updateCentroids(int numWorkers)  throws InterruptedException {
        int dim = this.points[0].getDimension();
        double[][][] sumsPartial = new double[numWorkers][numClusters][dim];
        int[][] countsPartial = new int[numWorkers][numClusters];
        Thread[] threads = new Thread[numWorkers];
        int grainSize = (this.numPoints + numWorkers - 1) / numWorkers; 

        for (int i = 0; i < numWorkers; i++) {
            final int workerId = i; 
            final int start = i * grainSize;
            final int end = Math.min(start + grainSize, this.numPoints);

            if (start >= this.numPoints) break;

            threads[i] = Thread.ofVirtual().start(() -> {
                for (int j = start; j < end; j++) {
                    int clusterId = this.assignments[j];
                    double[] point = this.points[j].getCoordinates();

                    for (int d = 0; d < dim; d++) {
                        sumsPartial[workerId][clusterId][d] += point[d];
                    }
                    countsPartial[workerId][clusterId]++;
                }
            });
        }

        for (Thread t : threads) {
            while (t.isAlive()){}
        }

        for (int c = 0; c < numClusters; c++) {
            double[] finalSum = new double[dim];
            int totalCount = 0;
            
            for (int w = 0; w < numWorkers; w++) {
                totalCount += countsPartial[w][c];
                for (int d = 0; d < dim; d++) {
                    finalSum[d] += sumsPartial[w][c][d];
                }
            }

            if (totalCount > 0) {
                for (int d = 0; d < dim; d++) {
                    finalSum[d] /= totalCount;
                }
                this.centroids[c] = new Point(finalSum);
            }
        }
    }

    private void clustering(int numWorkers) throws InterruptedException {
        Thread[] threads = new Thread[numWorkers];
        int grainSize = (this.numPoints + numWorkers - 1) / numWorkers; 

        for (int i = 0; i < numWorkers; i++) {
            final int start = i * grainSize;
            final int end = Math.min(start + grainSize, this.numPoints);

            if (start >= this.numPoints) break;

            threads[i] = Thread.ofVirtual().start(() -> {
                for (int j = start; j < end; j++) {
                    this.assignments[j] = findNearestCentroid(this.points[j]);
                }
            });
        }

        for (Thread t : threads) while (t.isAlive()){}
    }

    public void fit() {
        this.fit(300, Runtime.getRuntime().availableProcessors());
    }

    public void fit(int maxIterations, int numWorkers) {
        try {
            Point[] lastCentroids;
            int iteration = 0;
            boolean converged = false;

            do {
                lastCentroids = this.centroids.clone();
                this.clustering(numWorkers);
                this.updateCentroids(numWorkers);
                converged = centroidsConverged(lastCentroids, this.centroids);
                iteration++;
            } while (!converged && iteration < maxIterations);
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
    }

    public Point[] getCentroids() {
        return centroids;
    }

    public List<Point>[] getClusters() {
        @SuppressWarnings("unchecked")
        List<Point>[] clusters = (List<Point>[]) new List[this.numClusters];

        for (int i = 0; i < this.numClusters; i++) {
            clusters[i] = new ArrayList<Point>();
        }

        for (int i = 0; i < this.numPoints; i++) {
            clusters[this.assignments[i]].add(this.points[i]);
        }

        return clusters;
    }
}
