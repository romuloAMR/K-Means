package com.kmeans.benchmarks;

import org.apache.jmeter.config.Arguments;
import org.apache.jmeter.protocol.java.sampler.AbstractJavaSamplerClient;
import org.apache.jmeter.protocol.java.sampler.JavaSamplerContext;
import org.apache.jmeter.samplers.SampleResult;
import java.io.Serializable;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.util.List;
import java.util.UUID;

import com.kmeans.CSVReader;
import com.kmeans.Kmeans;
import com.kmeans.Point;

public class KmeansJMeterBenchmark extends AbstractJavaSamplerClient implements Serializable {

    @Override
    public SampleResult runTest(JavaSamplerContext javaSamplerContext) {
        SampleResult result = new SampleResult();
        result.setSampleLabel("Kmeans Macrobenchmark Test");
        
        Path arquivoOriginal = Paths.get("data/dataset_1000000x100_range_0.0_to_100.0.csv");
        Path arquivoTemp = Paths.get("data/temp_" + UUID.randomUUID().toString() + ".csv");
        result.sampleStart();

        try {
            Files.copy(arquivoOriginal, arquivoTemp, StandardCopyOption.REPLACE_EXISTING);
            List<Point> points = CSVReader.loadPoints(arquivoTemp.toAbsolutePath().toString());
            Kmeans ai = new Kmeans(3, points, 2026);
            ai.fit();

            result.sampleEnd();
            result.setResponseCode("200");
            result.setResponseMessage("OK");
            result.setSuccessful(true);

        } catch (Exception e) {
            result.sampleEnd();
            result.setResponseCode("500");
            result.setResponseMessage("Erro: " + e.getMessage());
            result.setSuccessful(false);
        } finally {
            try {
                Files.deleteIfExists(arquivoTemp);
            } catch (Exception ignored) {}
        }

        return result;
    }

    @Override
    public Arguments getDefaultParameters() {
        Arguments defaultParameters = new Arguments();
        return defaultParameters;
    }
}
