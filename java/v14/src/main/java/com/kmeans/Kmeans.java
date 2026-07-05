package com.kmeans;

import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;
import java.util.stream.IntStream;

public class Kmeans {
    
    private final int numClusters;
    private final Point[] points;
    private int[] assignments;
    private Point[] centroids;
    private final int numPoints;
    private final double epsilon;
    private record PartialSum(double[][] sums, int[] counts) {}
    
    public Kmeans(int numClusters, List<Point> points, long seed) {
        if (points == null || points.size() < numClusters) {
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

    public void updateCentroids(int numWorkers) {
        int dim = this.points[0].getDimension();
        int grainSize = (this.numPoints + numWorkers - 1) / numWorkers; 

        List<PartialSum> resultados = IntStream.range(0, numWorkers).parallel()
                .mapToObj(i -> {
                    final int start = i * grainSize;
                    final int end = Math.min(start + grainSize, this.numPoints);
                    
                    double[][] localSums = new double[numClusters][dim];
                    int[] localCounts = new int[numClusters];

                    if (start < this.numPoints) {
                        for (int j = start; j < end; j++) {
                            int clusterId = this.assignments[j];
                            double[] point = this.points[j].getCoordinates();

                            for (int d = 0; d < dim; d++) {
                                localSums[clusterId][d] += point[d];
                            }
                            localCounts[clusterId]++;
                        }
                    }
                    return new PartialSum(localSums, localCounts);
                }).collect(Collectors.toList());

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

    public void clustering() {
        IntStream.range(0, this.numPoints).parallel().forEach(j -> {
            this.assignments[j] = findNearestCentroid(this.points[j]);
        });
    }

    public void fit() {
        this.fit(300, Runtime.getRuntime().availableProcessors());
    }

    public void fit(int maxIterations, int numWorkers) {
        Point[] lastCentroids;
        int iteration = 0;
        boolean converged = false;

        do {
            lastCentroids = this.centroids.clone();
            this.clustering();
            this.updateCentroids(numWorkers);
            converged = centroidsConverged(lastCentroids, this.centroids);
            iteration++;
        } while (!converged && iteration < maxIterations);
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
