package com.kmeans;

import org.apache.spark.api.java.function.MapFunction;
import org.apache.spark.sql.Dataset;
import org.apache.spark.sql.Encoders;
import org.apache.spark.sql.Row;
import org.apache.spark.sql.SparkSession;
import org.apache.spark.sql.types.DataTypes;
import org.apache.spark.sql.types.StructField;
import org.apache.spark.sql.types.StructType;

public class CSVReader {

    public static Dataset<Point> loadPoints(SparkSession spark, String path) {

        int numColunas = 100;
        StructField[] fields = new StructField[numColunas];
        for (int i = 0; i < numColunas; i++) {
            fields[i] = DataTypes.createStructField("Col_" + (i + 1), DataTypes.FloatType, false);
        }
        StructType customSchema = DataTypes.createStructType(fields);

        Dataset<Row> df = spark.read()
                .option("header", "true")
                .schema(customSchema)
                .csv(path);

        return df.map(
                (MapFunction<Row, Point>) row -> {
                    float[] coords = new float[row.length()];
                    for (int i = 0; i < row.length(); i++) {
                        coords[i] = row.getFloat(i);
                    }
                    return new Point(coords);
                },
                Encoders.kryo(Point.class) 
        );
    }
}
