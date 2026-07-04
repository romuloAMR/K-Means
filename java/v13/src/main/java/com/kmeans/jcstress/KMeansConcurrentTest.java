package com.kmeans.jcstress;

import com.kmeans.Kmeans;
import com.kmeans.Point;
import org.openjdk.jcstress.annotations.*;
import org.openjdk.jcstress.infra.results.I_Result;
import org.openjdk.jcstress.infra.results.Z_Result;

import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.ForkJoinPool;

public class KMeansConcurrentTest {
    @JCStressTest
    @Outcome(id = "2", expect = Expect.ACCEPTABLE, desc = "Sucesso: As atualizações foram isoladas perfeitamente.")
    @Outcome(id = "0", expect = Expect.FORBIDDEN, desc = "ERRO: Ambas as atualizações foram perdidas.")
    @Outcome(id = "1", expect = Expect.FORBIDDEN, desc = "ERRO: Uma atualização sobrescreveu a outra.")
    @State
    public static class ArrayIndependenceTest {
        final int[] assignments = new int[2];

        @Actor
        public void worker1() {
            assignments[0] = 1; 
        }

        @Actor
        public void worker2() {
            assignments[1] = 1;
        }

        @Arbiter
        public void arbiter(I_Result r) {
            r.r1 = assignments[0] + assignments[1];
        }
    }

    @JCStressTest
    @Outcome(id = "true", expect = Expect.ACCEPTABLE, desc = "Sucesso: O array e os centroids foram atualizados e estão visíveis.")
    @Outcome(id = "false", expect = Expect.FORBIDDEN, desc = "ERRO: O Arbiter não enxergou as atualizações do ForkJoin.")
    @State
    public static class ForkJoinConcurrencyTest {
        final Kmeans kmeans;
        final ForkJoinPool pool;

        public ForkJoinConcurrencyTest() {
            List<Point> points = new ArrayList<>();
            points.add(new Point(new double[]{1.0}));
            points.add(new Point(new double[]{2.0}));
            points.add(new Point(new double[]{10.0}));
            points.add(new Point(new double[]{12.0}));
            kmeans = new Kmeans(2, points, 42);
            pool = new ForkJoinPool(4);
        }

        @Actor
        public void worker() {
            kmeans.clustering(pool, 1);
            kmeans.updateCentroids(pool, 1);
        }

        @Arbiter
        public void arbiter(Z_Result r) {
            int[] assignments = kmeans.getAssignments();
            Point[] centroids = kmeans.getCentroids();
            
            boolean assignmentsEstaveis = (assignments.length == 4);
            boolean centroidsVisiveis = (centroids[0] != null && centroids[1] != null);
            r.r1 = assignmentsEstaveis && centroidsVisiveis;
        }
    }
}
