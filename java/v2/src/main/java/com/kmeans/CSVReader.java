package com.kmeans;

import java.io.IOException;
import java.io.RandomAccessFile;
import java.nio.ByteBuffer;
import java.nio.channels.FileChannel;
import java.nio.file.Path;
import java.nio.file.StandardOpenOption;
import java.util.ArrayList;
import java.util.List;

public class CSVReader {

    private static final int SCALAR_FOR_WORKERS_READ = 1;
    private static final int ONE_MB = 1048576;
    private record Segment(long start, long size) {}

    private static List<Segment> getSegments(Path path) throws IOException {
        List<Segment> segments = new ArrayList<>();
        try (RandomAccessFile raf = new RandomAccessFile(path.toFile(), "r")) {
            long totalSize = raf.length();
            int cores = Runtime.getRuntime().availableProcessors() * SCALAR_FOR_WORKERS_READ;
            long targetSize = Math.max(totalSize / cores, ONE_MB);
            long currentPos = 0;

            while (currentPos < totalSize) {
                long start = currentPos;
                long endCandidate = currentPos + targetSize;

                if (endCandidate >= totalSize) {
                    segments.add(new Segment(start, totalSize - start));
                    break;
                }

                raf.seek(endCandidate);
                while (raf.getFilePointer() < totalSize && raf.read() != '\n');
                
                long actualEnd = raf.getFilePointer();
                segments.add(new Segment(start, actualEnd - start));
                currentPos = actualEnd;
            }
        }
        return segments;
    }

    public static List<Point> loadPoints(Path path) throws Exception {
        List<Segment> segments = getSegments(path);
        int numSegments = segments.size();
        @SuppressWarnings("unchecked")
        List<Point>[] partialResults = new List[numSegments];
        Thread[] threads = new Thread[numSegments];

        for (int i = 0; i < numSegments; i++) {
            final int index = i;
            Segment segment = segments.get(i);

            threads[i] = Thread.ofPlatform().start(() -> {
                List<Point> pointsPartition = new ArrayList<Point>();
                try (FileChannel ch = FileChannel.open(path, StandardOpenOption.READ)) {
                    ByteBuffer buffer = ch.map(FileChannel.MapMode.READ_ONLY, segment.start(), segment.size());

                    if (segment.start() == 0) {
                        while (buffer.hasRemaining() && buffer.get() != '\n');
                    }

                    StringBuilder lineBuilder = new StringBuilder();
                    while (buffer.hasRemaining()) {
                        byte b = buffer.get();
                        if (b == '\n') {
                            processLine(lineBuilder.toString(), pointsPartition);
                            lineBuilder.setLength(0);
                        } else if (b != '\r') {
                            lineBuilder.append((char) b);
                        }
                    }
                    if (lineBuilder.length() > 0) {
                        processLine(lineBuilder.toString(), pointsPartition);
                    }
                    partialResults[index] = pointsPartition;
                } catch (Exception e) {
                    e.printStackTrace();
                }
            });
        }

        List<Point> points = new ArrayList<>();
        for (int i = 0; i < threads.length; i++) {
            threads[i].join();
            if (partialResults[i] != null) {
                points.addAll(partialResults[i]);
            }
        }

        return points;
    }

    private static void processLine(String currentLine, List<Point> points) {
        if (currentLine.isEmpty()) return;
        try {
            String[] parts = currentLine.split(",");
            double[] coords = new double[parts.length];
            for (int i = 0; i < parts.length; i++) {
                coords[i] = Double.parseDouble(parts[i].trim());
            }
            points.add(new Point(coords));
        } catch (NumberFormatException e) {
        }
    }
}
