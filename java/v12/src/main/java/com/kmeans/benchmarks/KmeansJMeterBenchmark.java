package com.kmeans.benchmarks;

import org.apache.jmeter.config.Arguments;
import org.apache.jmeter.protocol.java.sampler.AbstractJavaSamplerClient;
import org.apache.jmeter.protocol.java.sampler.JavaSamplerContext;
import org.apache.jmeter.samplers.SampleResult;

import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.List;
import java.util.Random;

import com.kmeans.CSVReader;
import com.kmeans.Kmeans;
import com.kmeans.Point;

public class KmeansJMeterBenchmark extends AbstractJavaSamplerClient {

    private static final Path arquivoOriginal = Paths.get("/workspaces/K-Means/data/dataset_1000000x100_range_0.0_to_100.0.csv");
    private static boolean warmedUp = false;

    @Override
    public void setupTest(JavaSamplerContext context) {
        synchronized (KmeansJMeterBenchmark.class) {
            if (!warmedUp) {
                System.out.println("Iniciando Warmup do JIT Compiler (Java)...");
                try {
                    List<Point> warmupData = new ArrayList<>(10000);
                    Random r = new Random(42);
                    for (int i = 0; i < 10000; i++) {
                        double[] coords = new double[100];
                        for (int d = 0; d < 100; d++) coords[d] = r.nextDouble() * 100;
                        warmupData.add(new Point(coords));
                    }
                    for (int i = 0; i < 15; i++) {
                        Kmeans ai = new Kmeans(3, warmupData, 2026);
                        ai.fit();
                    }
                    System.out.println("Warmup concluído! JIT Otimizado.");
                } catch (Exception e) {
                    System.err.println("Erro no warmup: " + e.getMessage());
                }
                warmedUp = true;
            }
        }
    }

    @Override
    public SampleResult runTest(JavaSamplerContext javaSamplerContext) {
        SampleResult result = new SampleResult();
        result.setSampleLabel("Kmeans Macrobenchmark Test");
        
        result.sampleStart();

        long maxMemoryMB = Runtime.getRuntime().maxMemory() / (1024 * 1024);
        long t1 = System.currentTimeMillis();

        try {
            List<Point> points = CSVReader.loadPoints(arquivoOriginal);
            long t2 = System.currentTimeMillis();
            long tempoLeituraCSV = t2 - t1;

            Kmeans ai = new Kmeans(3, points, 2026);
            ai.fit();
            long t3 = System.currentTimeMillis();
            long tempoKMeans = t3 - t2;

            result.sampleEnd();
            result.setResponseCode("200");
            String metricas = String.format("MEM: %d MB | LerCSV: %d ms | KMeans: %d ms", maxMemoryMB, tempoLeituraCSV, tempoKMeans);
            result.setResponseMessage(metricas);
            result.setSuccessful(true);
            
            System.out.println("\n[DIAGNOSTICO-TERMINAL] " + metricas);

        } catch (Exception e) {
            result.sampleEnd();
            result.setResponseCode("500");
            result.setResponseMessage("Erro: " + e.getMessage());
            result.setSuccessful(false);
        }

        return result;
    }

    @Override
    public Arguments getDefaultParameters() {
        return new Arguments();
    }
}
