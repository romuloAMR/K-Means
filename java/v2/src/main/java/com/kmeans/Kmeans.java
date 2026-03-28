package com.kmeans;

import java.util.ArrayList;
import java.util.List;
import java.util.Random;

public class Kmeans {
    
    private final int numClusters;
    private final List<Point> points;
    private List<List<Point>> clusters;
    private List<Point> centroids;
    private Random rand;
    
    public Kmeans(int numClusters, List<Point> points, long seed) {
        if(points == null || points.size() < numClusters){
            throw new IllegalArgumentException("Number of clusters greater than the number of points");
        }

        this.points = points;
        this.numClusters = numClusters;
        this.rand = new Random(seed);
        this.createClusters();
    }

    private void createClusters() {
        this.clusters = new ArrayList<>();
        for(int i = 0; i < this.numClusters; i++){
            this.clusters.add(new ArrayList<>());
        }
    }

    private void clearClusters() {
        for (List<Point> cluster : this.clusters) {
            cluster.clear();
        }
    }

    private void randCentroids() {
        this.centroids = new ArrayList<>();
        List<Point> pointsCopy = new ArrayList<>(this.points);
        for (int i = 0; i < this.numClusters; i++){
            int num = this.rand.nextInt(pointsCopy.size());
            this.centroids.add(new Point(pointsCopy.get(num)));
            pointsCopy.remove(num);
        }
    }

    private void updateCentroids() throws Exception {
        try{
            List<Thread> threads = new ArrayList<Thread>();
            List<Point> newCentroids = new ArrayList<Point>(this.centroids);

            for (int i = 0; i < this.numClusters; i++) {
                int numCluster = i;
                Thread t = Thread.ofPlatform().start(() -> {
                    List<Point> cluster = this.clusters.get(numCluster);

                    if (cluster.isEmpty()) {
                        return;
                    }

                    int dim = cluster.get(0).getDimension();
                    Point sum = new Point(new double[dim]); 

                    for (Point point : cluster) {
                        sum.accumulatedAdd(point);
                    }

                    sum.accumulatedDivide(cluster.size());

                    newCentroids.set(numCluster, sum);
                });

                threads.add(t);
            }

            for (Thread th : threads) {
                th.join();
            }

            this.centroids = newCentroids;
        }
        catch (Exception e) {
            throw new RuntimeException(e);
        }   
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

    private void clustering() throws Exception {
        clustering(512, Runtime.getRuntime().availableProcessors()*4);
    }

    private void clustering(int chunkSize, int numWorkers) throws Exception {
        try {
            List<Thread> threads = new ArrayList<Thread>();
            List<List<List<Point>>> partialResults = new ArrayList<>();
        
            List<Point> buffer = new ArrayList<>();
        
            // Batch logic
            for (Point point : this.points) {
                buffer.add(point);
            
                if (buffer.size() >= chunkSize) {
                    List<Point> chunk = new ArrayList<>(buffer);

                    List<List<Point>> localClusters = new ArrayList<>();
                    for (int i = 0; i < numClusters; i++) {
                        localClusters.add(new ArrayList<>());
                    }
                
                    partialResults.add(localClusters);
                
                    Thread t = Thread.ofPlatform().start(() -> {
                        for (Point p : chunk) {
                            int idx = findNearestCentroid(p);
                            localClusters.get(idx).add(p);
                        }
                    });
                
                    threads.add(t);
                    buffer.clear();
                
                    if (threads.size() >= numWorkers) {
                        for (Thread th : threads) {
                            th.join();
                        }
                        threads.clear();
                    }
                }
            }
        
            // Processes remaining points and wait until the pending ones are completed
            if (!buffer.isEmpty()) {
                List<List<Point>> localClusters = new ArrayList<>();
                for (int i = 0; i < numClusters; i++) {
                    localClusters.add(new ArrayList<>());
                }
            
                for (Point p : buffer) {
                    int idx = findNearestCentroid(p);
                    localClusters.get(idx).add(p);
                }
            
                partialResults.add(localClusters);
            }
            for (Thread th : threads) {
                th.join();
            }
        
            // Merge partial clusters in cluster and end process
            for (List<List<Point>> local : partialResults) {
                for (int i = 0; i < numClusters; i++) {
                    this.clusters.get(i).addAll(local.get(i));
                }
            }
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
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
        try {
            this.randCentroids();
            List<Point> lastCentroids;
            int iteration = 0;
            boolean converged = false;

            do {
                lastCentroids = new ArrayList<>(this.centroids);
                this.clearClusters();
                this.clustering();
                this.updateCentroids();
                converged = centroidsConverged(lastCentroids, this.centroids);
                iteration++;
            } while (!converged && iteration < maxIterations);
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
    }

    public List<Point> getCentroids() {
        return centroids;
    }

    public List<List<Point>> getClusters() {
        return clusters;
    }
}
