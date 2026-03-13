package com.kmeans;

public class Point {
    private final double[] position;
    private final int dimension;

    public Point(double[] position) {
        if (position == null || position.length == 0) {
            throw new IllegalArgumentException("Position can't be null or empty.");
        }
        this.position = position.clone();
        this.dimension = position.length;
    }

    public double distanceTo(Point other) {
        if (this.dimension != other.getDimension()) {
            throw new IllegalArgumentException("The points must have the same dimension.");
        }
        double sum = 0;
        for (int i = 0; i < dimension; i++) {
            double diff = this.position[i] - other.getOnePosition(i);
            sum += diff * diff;
        }
        return Math.sqrt(sum);
    }

    public Point add(Point other) {
        if (this.dimension != other.getDimension()) {
            throw new IllegalArgumentException("Dimensions must match for addition.");
        }
        double[] newCoords = new double[dimension];
        for (int i = 0; i < dimension; i++) {
            newCoords[i] = this.position[i] + other.getOnePosition(i);
        }
        return new Point(newCoords);
    }

    public Point subtract(Point other) {
        if (this.dimension != other.getDimension()) {
            throw new IllegalArgumentException("Dimensions must match for subtraction.");
        }
        double[] newCoords = new double[dimension];
        for (int i = 0; i < dimension; i++) {
            newCoords[i] = this.position[i] - other.getOnePosition(i);
        }
        return new Point(newCoords);
    }

    public Point add(double scalar) {        
        double[] newCoords = new double[dimension];
        for (int i = 0; i < dimension; i++) {
            newCoords[i] = this.position[i] + scalar;
        }
        return new Point(newCoords);
    }

    public Point multiply(double scalar) {        
        double[] newCoords = new double[dimension];
        for (int i = 0; i < dimension; i++) {
            newCoords[i] = this.position[i] * scalar;
        }
        return new Point(newCoords);
    }

    public Point divide(double scalar) {
        if (scalar == 0) {
            throw new ArithmeticException("Division by zero.");
        }
        double[] newCoords = new double[dimension];
        for (int i = 0; i < dimension; i++) {
            newCoords[i] = this.position[i] / scalar;
        }
        return new Point(newCoords);
    }

    public double getOnePosition(int i) {
        if (i < 0 || i >= this.dimension) {
            throw new IllegalArgumentException("Index out of bounds.");
        }
        return position[i];
    }

    public int getDimension() {
        return dimension;
    }

    @Override
    public String toString() {
        return java.util.Arrays.toString(this.position);
    }
}
