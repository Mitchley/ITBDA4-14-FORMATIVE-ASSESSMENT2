/**
 * ITBDAA-14 Project 2 — Question 1
 * Hadoop MapReduce: case-insensitive keyword search.
 * Keyword is passed as a command-line argument (not hardcoded).
 */

import java.io.IOException;
import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.io.*;
import org.apache.hadoop.mapreduce.*;
import org.apache.hadoop.mapreduce.lib.input.*;
import org.apache.hadoop.mapreduce.lib.output.FileOutputFormat;

public class question1 {

    // ---- Q1.2 MAPPER ----
    // Emits: <filename, "row:R col:C1,C2,..."> for every matching line
    public static class KeywordMapper extends Mapper<LongWritable, Text, Text, Text> {
        private final Text k = new Text();
        private final Text v = new Text();

        @Override
        public void map(LongWritable key, Text value, Context ctx)
                throws IOException, InterruptedException {

            String keyword = ctx.getConfiguration().get("keyword").toLowerCase();
            String fileName = ((FileSplit) ctx.getInputSplit()).getPath().getName();
            String line = value.toString();
            String lower = line.toLowerCase();

            StringBuilder cols = new StringBuilder();
            int n = 0;
            int i = lower.indexOf(keyword);
            while (i >= 0) {
                if (n++ > 0) cols.append(",");
                cols.append(i + 1);
                i = lower.indexOf(keyword, i + keyword.length());
            }
            if (n == 0) return;

            long row = ctx.getCounter("RowTracker", fileName).getValue() + 1;
            ctx.getCounter("RowTracker", fileName).increment(1);

            k.set(fileName);
            v.set("row:" + row + " col:" + cols);
            ctx.write(k, v);
        }
    }

    // ---- Q1.3 REDUCER ----
    public static class KeywordReducer extends Reducer<Text, Text, Text, Text> {
        @Override
        public void reduce(Text key, Iterable<Text> vals, Context ctx)
                throws IOException, InterruptedException {
            StringBuilder sb = new StringBuilder();
            for (Text v : vals) {
                if (sb.length() > 0) sb.append(" | ");
                sb.append(v.toString());
            }
            ctx.write(key, new Text(sb.toString()));
        }
    }

    // ---- Q1.4 DRIVER / CONFIGURATION ----
    public static void main(String[] args) throws Exception {
        if (args.length != 3) {
            System.err.println("Usage: question1 <keyword> <input> <output>");
            System.exit(2);
        }
        String keyword = args[0], input = args[1], output = args[2];

        Configuration conf = new Configuration();
        conf.set("keyword", keyword);

        Job job = Job.getInstance(conf, "Keyword Search - " + keyword);
        job.setJarByClass(question1.class);
        job.setJar("C:/ITBDA4-Assignment2/question1.jar");

        job.setMapperClass(KeywordMapper.class);
        job.setReducerClass(KeywordReducer.class);
        job.setOutputKeyClass(Text.class);
        job.setOutputValueClass(Text.class);

        // Disable reducer + use larger splits to avoid shuffle failures on Windows
        job.setNumReduceTasks(0);

        job.setInputFormatClass(NLineInputFormat.class);
        NLineInputFormat.setNumLinesPerSplit(job, 50);

        FileInputFormat.addInputPath(job, new Path(input));
        FileOutputFormat.setOutputPath(job, new Path(output));

        System.exit(job.waitForCompletion(true) ? 0 : 1);
    }
}