package com.kmeans;

import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.ForkJoinPool;
import java.util.concurrent.RecursiveAction;

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

    private class ClusteringAction extends RecursiveAction {
        private final int start;
        private final int end;
        private final int threshold;

        public ClusteringAction(int start, int end, int threshold) {
            this.start = start;
            this.end = end;
            this.threshold = threshold;
        }

        @Override
        protected void compute() {
            if (end - start <= threshold) {
                for (int j = start; j < end; j++) {
                    Kmeans.this.assignments[j] = findNearestCentroid(Kmeans.this.points[j]);
                }
            } else {
                int mid = start + (end - start) / 2;
                invokeAll(
                    new ClusteringAction(start, mid, threshold),
                    new ClusteringAction(mid, end, threshold)
                );
            }
        }
    }

    private class UpdateAction extends RecursiveAction {
        private final int start;
        private final int end;
        private final int threshold;
        
        public double[][] sums;
        public int[] counts;

        public UpdateAction(int start, int end, int threshold) {
            this.start = start;
            this.end = end;
            this.threshold = threshold;
        }

        @Override
        protected void compute() {
            int dim = points[0].getDimension();
            sums = new double[numClusters][dim];
            counts = new int[numClusters];

            if (end - start <= threshold) {
                for (int j = start; j < end; j++) {
                    int clusterId = Kmeans.this.assignments[j];
                    double[] point = Kmeans.this.points[j].getCoordinates();

                    for (int d = 0; d < dim; d++) {
                        sums[clusterId][d] += point[d];
                    }
                    counts[clusterId]++;
                }
            } else {
                int mid = start + (end - start) / 2;
                UpdateAction left = new UpdateAction(start, mid, threshold);
                UpdateAction right = new UpdateAction(mid, end, threshold);
                invokeAll(left, right);
                for (int c = 0; c < numClusters; c++) {
                    counts[c] = left.counts[c] + right.counts[c];
                    for (int d = 0; d < dim; d++) {
                        sums[c][d] = left.sums[c][d] + right.sums[c][d];
                    }
                }
            }
        }
    }

    public void clustering(ForkJoinPool pool, int threshold) {
        pool.invoke(new ClusteringAction(0, this.numPoints, threshold));
    }

    public void updateCentroids(ForkJoinPool pool, int threshold) {
        int dim = this.points[0].getDimension();
        UpdateAction updateTask = new UpdateAction(0, this.numPoints, threshold);
        pool.invoke(updateTask);

        for (int c = 0; c < numClusters; c++) {
            if (updateTask.counts[c] > 0) {
                double[] finalSum = new double[dim];
                for (int d = 0; d < dim; d++) {
                    finalSum[d] = updateTask.sums[c][d] / updateTask.counts[c];
                }
                this.centroids[c] = new Point(finalSum);
            }
        }
    }

    public void fit() {
        this.fit(300, Runtime.getRuntime().availableProcessors());
    }

    public void fit(int maxIterations, int numWorkers) {
        int threshold = Math.max(100, this.numPoints / numWorkers);
        ForkJoinPool pool = new ForkJoinPool(numWorkers);
        
        try {
            Point[] lastCentroids;
            int iteration = 0;
            boolean converged = false;

            do {
                lastCentroids = this.centroids.clone();
                this.clustering(pool, threshold);
                this.updateCentroids(pool, threshold);
                converged = centroidsConverged(lastCentroids, this.centroids);
                iteration++;
            } while (!converged && iteration < maxIterations);
        } catch (Exception e) {
            throw new RuntimeException(e);
        } finally {
            pool.shutdown();
        }
    }

    public int[] getAssignments() {
        return this.assignments; 
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
