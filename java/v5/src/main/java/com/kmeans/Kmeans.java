package com.kmeans;

import java.util.ArrayList;
import java.util.List;
import java.util.Random;

public class Kmeans {
    
    private final int numClusters;
    private final Point[] points;
    private volatile int[] assignments;
    private volatile Point[] centroids;
    private final int numPoints;
    private final double epsilon;
    private final Random rand;
    private volatile double[][][] sumsPartial;
    private volatile int[][] countsPartial;
    
    public Kmeans(int numClusters, List<Point> points, long seed) {
        if(points == null || points.size() < numClusters){
            throw new IllegalArgumentException("Number of clusters greater than the number of points");
        }

        this.numClusters = numClusters;
        this.epsilon = 1e-10;
        this.rand = new Random(seed);
        this.numPoints = points.size();
        this.points = new Point[this.numPoints];
        for (int i = 0; i < this.numPoints; i++) {
            this.points[i] = points.get(i);
        }
        this.assignments = new int[this.numPoints];
        this.centroids = new Point[this.numClusters];
        
        points = new ArrayList<>(points);
        for (int i = 0; i < this.numClusters; i++){
            int num = this.rand.nextInt(points.size());
            this.centroids[i] = new Point(points.get(num));
            points.remove(num);
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
        final int dim = this.points[0].getDimension();
        sumsPartial = new double[numWorkers][numClusters][dim];
        countsPartial = new int[numWorkers][numClusters];
        Thread[] threads = new Thread[numWorkers];
        int grainSize = (this.numPoints + numWorkers - 1) / numWorkers; 

        for (int i = 0; i < numWorkers; i++) {
            final int workerId = i; 
            final int start = i * grainSize;
            final int end = Math.min(start + grainSize, this.numPoints);

            if (start >= this.numPoints) break;

            threads[i] = Thread.ofPlatform().start(() -> {
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

        for (Thread t : threads) while (t.isAlive()){}

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

            threads[i] = Thread.ofPlatform().start(() -> {
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
