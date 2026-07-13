package com.kmeans;

import org.apache.spark.api.java.function.MapFunction;
import org.apache.spark.api.java.function.ReduceFunction;
import org.apache.spark.broadcast.Broadcast;
import org.apache.spark.sql.Dataset;
import org.apache.spark.sql.Encoders;
import org.apache.spark.sql.SparkSession;
import scala.Tuple2;

import java.io.Serializable;
import java.util.Map;
import java.util.stream.Collectors;

public class Kmeans implements Serializable {

    private final int numClusters;
    private Point[] centroids;
    private final float epsilon;

    public Kmeans(int numClusters, Point[] initialCentroids) {
        this.numClusters = numClusters;
        this.epsilon = 1e-10f;
        this.centroids = initialCentroids;
    }

    public static class ClusterSum implements Serializable {
        public int count;
        public float[] sumCoords;

        public ClusterSum(int count, float[] sumCoords) {
            this.count = count;
            this.sumCoords = sumCoords.clone();
        }
    }

    public void fit(Dataset<Point> dataset, SparkSession spark, int maxIterations) {
        int iteration = 0;
        boolean converged = false;

        while (!converged && iteration < maxIterations) {
            Point[] lastCentroids = this.centroids.clone();
            Broadcast<Point[]> broadcastCentroids = spark.sparkContext().broadcast(this.centroids, scala.reflect.ClassTag$.MODULE$.apply(Point[].class));
            MapFunction<Point, Tuple2<Integer, ClusterSum>> mapFunc = point -> {
                Point[] locaisCentroids = broadcastCentroids.value();
                int nearestIndex = -1;
                float minDistance = Float.MAX_VALUE;

                for (int i = 0; i < locaisCentroids.length; i++) {
                    float dist = point.sqDistanceTo(locaisCentroids[i]);
                    if (dist < minDistance) {
                        minDistance = dist;
                        nearestIndex = i;
                    }
                }
                return new Tuple2<>(nearestIndex, new ClusterSum(1, point.getCoordinates()));
            };

            MapFunction<Tuple2<Integer, ClusterSum>, Integer> keyFunc = tuple -> tuple._1();

            ReduceFunction<Tuple2<Integer, ClusterSum>> reduceFunc = (t1, t2) -> {
                int newCount = t1._2().count + t2._2().count;
                float[] newCoords = new float[t1._2().sumCoords.length];
                for (int i = 0; i < newCoords.length; i++) {
                    newCoords[i] = t1._2().sumCoords[i] + t2._2().sumCoords[i];
                }
                return new Tuple2<>(t1._1(), new ClusterSum(newCount, newCoords));
            };

            MapFunction<Tuple2<Integer, Tuple2<Integer, ClusterSum>>, Tuple2<Integer, ClusterSum>> extractFunc = tuple -> tuple._2();

            Map<Integer, ClusterSum> novasSomas = dataset
                    .map(mapFunc, Encoders.tuple(Encoders.INT(), Encoders.kryo(ClusterSum.class)))
                    .groupByKey(keyFunc, Encoders.INT())
                    .reduceGroups(reduceFunc)
                    .map(extractFunc, Encoders.tuple(Encoders.INT(), Encoders.kryo(ClusterSum.class)))
                    .collectAsList()
                    .stream()
                    .collect(Collectors.toMap(Tuple2::_1, Tuple2::_2));

            broadcastCentroids.unpersist();

            for (int c = 0; c < this.numClusters; c++) {
                ClusterSum clusterSum = novasSomas.get(c);
                if (clusterSum != null && clusterSum.count > 0) {
                    float[] medias = new float[clusterSum.sumCoords.length];
                    for (int d = 0; d < medias.length; d++) {
                        medias[d] = clusterSum.sumCoords[d] / clusterSum.count;
                    }
                    this.centroids[c] = new Point(medias);
                }
            }

            converged = centroidsConverged(lastCentroids, this.centroids);
            iteration++;
        }
    }

    private boolean centroidsConverged(Point[] last, Point[] now) {
        for (int i = 0; i < this.numClusters; i++) {
            if (last[i].sqDistanceTo(now[i]) > this.epsilon) {
                return false;
            }
        }
        return true;
    }

    public Point[] getCentroids() {
        return this.centroids.clone();
    }
}
