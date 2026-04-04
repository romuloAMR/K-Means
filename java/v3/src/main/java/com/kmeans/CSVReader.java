package com.kmeans;

import java.io.BufferedReader;
import java.io.FileReader;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

public class CSVReader {
    static public List<Point> loadPoints(String path) throws Exception {
        return loadPoints(path, 512);
    }

    static public List<Point> loadPoints(String path, int chunkSize) throws Exception {
        try (BufferedReader reader = new BufferedReader(new FileReader(path))) {
            String line;
            List<Point> points = new ArrayList<Point>();
            List<Thread> threads = new ArrayList<Thread>();
            List<String> buffer = new ArrayList<>();

            reader.readLine();

            // Batch logic
            while ((line = reader.readLine()) != null) {
                buffer.add(line);
                if (buffer.size() >= chunkSize) {
                    List<String> chunk = new ArrayList<>(buffer);
                
                    Thread t = Thread.ofVirtual().start(() -> {
                        for (String l : chunk) {
                            processLine(l, points);
                        }
                    });
                
                    threads.add(t);
                    buffer.clear();
                }
            }

            // Processes remaining lines non process and wait until the pending ones are completed
            if (!buffer.isEmpty()) {
                for (String l : buffer) {
                    processLine(l, points);
                }
            }
            for (Thread th : threads) {
                th.join();
            }

            // End
            return points;
        } catch (IOException e) {
            throw new RuntimeException(e);
        }
    }

    private static void processLine(String currentLine, List<Point> points) {
        double[] coords = Arrays.stream(currentLine.split(","))
                                .map(String::trim)
                                .mapToDouble(Double::parseDouble)
                                .toArray();
        points.add(new Point(coords));
    }
}
