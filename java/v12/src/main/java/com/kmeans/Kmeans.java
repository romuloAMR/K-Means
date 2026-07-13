package com.kmeans;

import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.ExecutionException;

public class Kmeans {
    
    private final int numClusters;
    private final Point[] points;
    private int[] assignments;
    private Point[] centroids;
    private final int numPoints;
    private final double epsilon;
    private record PartialSum(double[][] sums, int[] counts) {}
    
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
    
        for (int i = 0; i < this.numClusters; i++) {
            this.centroids[i] = new Point(this.points[i]);
        }
    }

    public int findNearestCentroid(Point p) {
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

    public void updateCentroids(ExecutorService executor, int numWorkers) throws InterruptedException, ExecutionException {
        int dim = this.points[0].getDimension();
        int grainSize = (this.numPoints + numWorkers - 1) / numWorkers; 
        List<Future<PartialSum>> futures = new ArrayList<>();

        for (int i = 0; i < numWorkers; i++) {
            final int start = i * grainSize;
            final int end = Math.min(start + grainSize, this.numPoints);

            if (start >= this.numPoints) continue;

            futures.add(executor.submit(() -> {
                double[][] localSums = new double[numClusters][dim];
                int[] localCounts = new int[numClusters];
                for (int j = start; j < end; j++) {
                    int clusterId = this.assignments[j];
                    double[] point = this.points[j].getCoordinates();

                    for (int d = 0; d < dim; d++) {
                        localSums[clusterId][d] += point[d];
                    }
                    localCounts[clusterId]++;
                }

                return new PartialSum(localSums, localCounts);
            }));
        }

        List<PartialSum> resultados = new ArrayList<>();
        for (Future<PartialSum> future : futures) {
            resultados.add(future.get());
        }

        for (int c = 0; c < numClusters; c++) {
            int totalCount = 0;
            double[] sum = new double[dim];

            for (PartialSum partial : resultados) {
                totalCount += partial.counts()[c];
                for (int d = 0; d < dim; d++) {
                    sum[d] += partial.sums()[c][d];
                }
            }

            if (totalCount > 0) {
                for (int d = 0; d < dim; d++) {
                    sum[d] /= totalCount;
                }
                this.centroids[c] = new Point(sum);
            }
        }
    }

    public void clustering(ExecutorService executor, int numWorkers) throws InterruptedException {
        int grainSize = (this.numPoints + numWorkers - 1) / numWorkers; 
        CountDownLatch latch = new CountDownLatch(numWorkers);

        for (int i = 0; i < numWorkers; i++) {
            final int start = i * grainSize;
            final int end = Math.min(start + grainSize, this.numPoints);

            if (start >= this.numPoints) {
                latch.countDown();
                continue;
            }

            executor.execute(() -> {
                try {
                    for (int j = start; j < end; j++) {
                        this.assignments[j] = findNearestCentroid(this.points[j]);
                    }
                } finally {
                    latch.countDown();
                }
            });
        }

        latch.await(); 
    }

    public void fit() {
        this.fit(300, Runtime.getRuntime().availableProcessors());
    }

    public void fit(int maxIterations, int numWorkers) {
        try (ExecutorService executor = Executors.newFixedThreadPool(numWorkers)) {
            Point[] lastCentroids;
            int iteration = 0;
            boolean converged = false;

            do {
                lastCentroids = this.centroids.clone();
                this.clustering(executor, numWorkers);
                this.updateCentroids(executor, numWorkers);
                converged = centroidsConverged(lastCentroids, this.centroids);
                iteration++;
            } while (!converged && iteration < maxIterations);
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
    }

    public int[] getAssignments() {
        return this.assignments.clone();
    }

    public Point[] getCentroids() {
        return centroids.clone();
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
