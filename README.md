# ITBDAA-14 Project 2 — Big Data Analytics Techniques

**Student:** Mitchley  
**Module:** ITBDAA-14  
**Institution:** Eduvos

## Overview

This repository contains the complete solution for Project 2 of ITBDAA-14, demonstrating four Big Data Analytics techniques using Hadoop MapReduce, R, and PostgreSQL.

## Repository Structure

| File / Folder | Description |
|---------------|-------------|
| `question1.java` `question1.jar` | Q1 Java Hadoop MapReduce keyword search |
| `corpus/` `q1_output/` `q1_result.txt` | Q1 Input corpus and job output |
| `Question2.R` `q2_data/` | Q2 LDA topic modelling script and data |
| `q2_bar.png` `q2_wordclouds.png` | Q2 Visualisations |
| `Question3.R` | Q3 Web scraping and text summarisation |
| `q3_bar.png` `q3_wordcloud.png` `q3_sentence_hist.png` | Q3  Visualisations |
| `Question4.R` `books_cleaned.csv` | Q4  ETL pipeline and cleaned dataset |

## Notes

- Q1 is written in Java and must be compiled before running.
- Q2, Q3, and Q4 are written in R and require the relevant packages.
- Q4 requires a running PostgreSQL instance with the database `books_etl_db`.
- Detailed explanations, screenshots, and results are provided in the project report.
