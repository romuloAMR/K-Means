package com.kmeans;

import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.Arrays;
import java.util.List;
import java.util.stream.Collectors;
import java.util.stream.Stream;

public class CSVReader {
    static public List<Point> loadPoints(String path) throws Exception {
        try (Stream<String> lines = Files.lines(Paths.get(path))) {
            return lines
                    .skip(1)
                    .filter(line -> !line.trim().isEmpty())
                    .map(line -> {
                        double[] coords = Arrays.stream(line.split(","))
                                .map(String::trim)
                                .mapToDouble(Double::parseDouble)
                                .toArray();
                        
                        return new Point(coords);
                    })
                    .collect(Collectors.toList());
        }
    }
}
