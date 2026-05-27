package com.kmeans.jcstress;

import com.kmeans.Point;

import org.openjdk.jcstress.annotations.Actor;
import org.openjdk.jcstress.annotations.Arbiter;
import org.openjdk.jcstress.annotations.Expect;
import org.openjdk.jcstress.annotations.JCStressTest;
import org.openjdk.jcstress.annotations.Outcome;
import org.openjdk.jcstress.annotations.State;
import org.openjdk.jcstress.infra.results.I_Result;
import java.util.ArrayList;
import java.util.List;

public class CSVReaderConcurrencyTest {

    @JCStressTest
    @Outcome(id = "1", expect = Expect.ACCEPTABLE, desc = "Visibilidade garantida: Lista publicada com sucesso pós-execução.")
    @Outcome(id = "-1", expect = Expect.FORBIDDEN, desc = "Erro de visibilidade: Referência nula ou inconsistente.")
    @State
    public static class RealisticVisibilitySpec {
        private List<Point> finalPoints = null;
        private final Object mutex = new Object();

        @Actor
        public void threadProcessamento() {
            List<Point> localList = new ArrayList<>();
            localList.add(new Point(new double[]{1.0, 2.0}));
            
            synchronized (mutex) {
                finalPoints = localList; 
            }
        }

        @Arbiter
        public void inspectFinalState(I_Result r) {
            try {
                List<Point> local = finalPoints; 
                if (local != null && !local.isEmpty()) {
                    Point p = local.get(0);
                    if (p != null && p.getCoordinates() != null && p.getCoordinates()[0] == 1.0) {
                        r.r1 = 1;
                        return;
                    }
                }
                r.r1 = -1;
            } catch (Exception e) {
                r.r1 = -1;
            }
        }
    }

    @JCStressTest
    @Outcome(id = "1", expect = Expect.ACCEPTABLE, desc = "Sem problemas de reordenamento.")
    @Outcome(id = "-1", expect = Expect.FORBIDDEN, desc = "Erro: Dados inconsistentes ou vazios pós-execução.")
    @State
    public static class ReorderingSpec {
        private final List<Point> sharedPoints = new ArrayList<>();
        private final Object mutex = new Object();

        @Actor
        public void threadProcessamento() {
            synchronized (mutex) {
                sharedPoints.add(new Point(new double[]{1.0, 2.0})); 
            }
        }

        @Arbiter
        public void inspectFinalState(I_Result r) {
            try {
                if (!sharedPoints.isEmpty()) {
                    Point p = sharedPoints.get(0);
                    if (p != null && p.getCoordinates() != null && p.getCoordinates()[0] == 1.0) {
                        r.r1 = 1;
                        return;
                    }
                }
                r.r1 = -1;
            } catch (Exception e) {
                r.r1 = -1;
            }
        }
    }

    @JCStressTest
    @Outcome(id = "2", expect = Expect.ACCEPTABLE, desc = "Sem corrida de dados: O mutex protegeu a lista com sucesso.")
    @Outcome(id = "-1", expect = Expect.FORBIDDEN, desc = "Corrida de dados: Lista corrompida ou tamanho incorreto.")
    @State
    public static class SharedCollectionRaceSpec {
        private final List<Point> sharedPoints = new ArrayList<>();
        private final Object mutex = new Object();

        @Actor
        public void threadProcessamento1() {
            synchronized (mutex) {
                sharedPoints.add(new Point(new double[]{1.0}));
            }
        }

        @Actor
        public void threadProcessamento2() {
            synchronized (mutex) {
                sharedPoints.add(new Point(new double[]{2.0}));
            }
        }

        @Arbiter
        public void inspectFinalState(I_Result r) {
            try {
                int finalSize = sharedPoints.size();
                if (finalSize == 2) {
                    r.r1 = 2;
                } else {
                    r.r1 = -1;
                }
            } catch (Exception e) {
                r.r1 = -1;
            }
        }
    }
}
