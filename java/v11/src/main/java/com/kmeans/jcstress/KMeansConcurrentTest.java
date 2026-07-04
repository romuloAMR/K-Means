package com.kmeans.jcstress;

import org.openjdk.jcstress.annotations.*;
import org.openjdk.jcstress.infra.results.I_Result;

public class KMeansConcurrentTest {

    @JCStressTest
    @Outcome(id = "2", expect = Expect.ACCEPTABLE, desc = "Sucesso: Todas as atribuições foram escritas e estão visíveis.")
    @Outcome(id = "0", expect = Expect.ACCEPTABLE_INTERESTING, desc = "ERRO: Ambas as atualizações foram perdidas.")
    @Outcome(id = "1", expect = Expect.ACCEPTABLE_INTERESTING, desc = "ERRO: Uma atualização foi perdida (sobrescrita).")
    @State
    public static class AssignmentIndependenceTest {
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
    @Outcome(id = "10", expect = Expect.ACCEPTABLE, desc = "Sucesso: Agregação mesclada corretamente graças ao 'synchronized'.")
    @Outcome(id = "3", expect = Expect.ACCEPTABLE_INTERESTING, desc = "ERRO DE CORRIDA! A atualização do Worker 2 foi perdida.")
    @Outcome(id = "7", expect = Expect.ACCEPTABLE_INTERESTING, desc = "ERRO DE CORRIDA! A atualização do Worker 1 foi perdida.")
    @State
    public static class CentroidUpdateSyncTest {

        static class State {
            final double[][] centroidsSum = new double[1][1];
            final int[] counts = new int[1];
            final Object mutex = new Object();
        }

        private final State s = new State();

        @Actor
        public void worker1() {
            double[][] local = new double[1][1];
            int[] localCount = new int[1];

            local[0][0] = 3.0;
            localCount[0] = 1;

            synchronized (s.mutex) {
                s.counts[0] += localCount[0];
                s.centroidsSum[0][0] += local[0][0];
            }
        }

        @Actor
        public void worker2() {
            double[][] local = new double[1][1];
            int[] localCount = new int[1];

            local[0][0] = 7.0;
            localCount[0] = 2;

            synchronized (s.mutex) {
                s.counts[0] += localCount[0];
                s.centroidsSum[0][0] += local[0][0];
            }
        }

        @Arbiter
        public void arbiter(I_Result r) {
            r.r1 = (int) s.centroidsSum[0][0]; 
        }
    }
}
