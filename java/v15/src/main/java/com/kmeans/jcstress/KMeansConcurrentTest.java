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
}
