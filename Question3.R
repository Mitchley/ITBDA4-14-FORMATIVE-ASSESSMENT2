# ============================================================
# Q3 — WebText API: Scrape, Preprocess, Summarise
# ITBDA4 Big Data Analytics — Project 2
# Source: https://en.wikipedia.org/wiki/Natural_language_processing
# ============================================================

library(rvest)
library(stringr)
library(tm)
library(ggplot2)
library(wordcloud)
library(RColorBrewer)
library(dplyr)

# ====================================================================================================
# Q3.1 — Web scraping: extract clean text into an R data structure
# ====================================================================================================

url <- "https://en.wikipedia.org/wiki/Natural_language_processing"
page <- read_html(url)

# Extract readable paragraphs
paragraphs <- page %>%
  html_elements("#mw-content-text p") %>%
  html_text(trim = TRUE)

# Keep only paragraphs with real text
paragraphs <- paragraphs[nchar(paragraphs) > 80]

# Store in a data frame
web_data <- data.frame(
  paragraph_id = seq_along(paragraphs),
  text         = paragraphs,
  stringsAsFactors = FALSE
)

# ---- Clean display of scraped data ----
df_display <- data.frame(
  paragraph_id = web_data$paragraph_id,
  preview      = paste0(substr(web_data$text, 1, 60), "...")
)

cat("\n================================================================================\n")
cat("Q3.1 — SCRAPED DATA FRAME\n")
cat("================================================================================\n")
cat("Total paragraphs:", nrow(web_data), "\n")
cat("Total characters:", sum(nchar(web_data$text)), "\n\n")
print(df_display)

# Combine all paragraphs
full_text <- paste(web_data$text, collapse = " ")


# ====================================================================================================
# Q3.2 — Textual preprocessing
# ====================================================================================================

clean_text <- full_text

clean_text <- str_replace_all(clean_text, "https?://\\S+", " ")
clean_text <- str_replace_all(clean_text, "\\[[0-9]+\\]", " ")
clean_text <- str_replace_all(clean_text, "&[a-z]+;", " ")
clean_text <- tolower(clean_text)
clean_text <- str_replace_all(clean_text, "[^a-z\\s]", " ")
clean_text <- str_squish(clean_text)
clean_text <- removeWords(clean_text, stopwords("english"))
clean_text <- str_squish(clean_text)

# ---- Clean display of preprocessed text ----
clean_preview <- strsplit(clean_text, "\\s+")[[1]][1:30]

cat("\n================================================================================\n")
cat("Q3.2 — PREPROCESSING RESULTS\n")
cat("================================================================================\n")
cat("Original text length : ", nchar(full_text), "characters\n")
cat("Cleaned  text length : ", nchar(clean_text), "characters\n\n")

cat("--- BEFORE (first paragraph, first 100 chars) ---\n")
cat(substr(web_data$text[1], 1, 100), "...\n\n")

cat("--- AFTER (cleaned text, first 30 words) ---\n")
cat(paste(clean_preview, collapse = " "), "...\n\n")

cat("--- STOPWORDS REMOVED ---\n")
cat(paste(head(stopwords("english"), 20), collapse = ", "), "\n")


# ====================================================================================================
# Q3.3 Summarisation (2 techniques) + Visualisations
# ====================================================================================================

# ---- Technique 1 — TF-IDF sentence scoring ----

sentences <- unlist(strsplit(full_text, "(?<=[.!?])\\s+", perl = TRUE))
sentences <- sentences[nchar(sentences) > 40]

sent_corpus <- VCorpus(VectorSource(sentences))
sent_corpus <- tm_map(sent_corpus, content_transformer(tolower))
sent_corpus <- tm_map(sent_corpus, removePunctuation)
sent_corpus <- tm_map(sent_corpus, removeNumbers)
sent_corpus <- tm_map(sent_corpus, removeWords, stopwords("english"))
sent_corpus <- tm_map(sent_corpus, stripWhitespace)

sent_dtm <- DocumentTermMatrix(sent_corpus)
tfidf <- weightTfIdf(sent_dtm)
sentence_scores <- rowSums(as.matrix(tfidf))

top_idx <- order(sentence_scores, decreasing = TRUE)[1:5]
top_sentences <- data.frame(
  sentence_id = top_idx,
  text        = sentences[top_idx],
  score       = round(sentence_scores[top_idx], 4),
  stringsAsFactors = FALSE
)

cat("\n================================================================================\n")
cat("Q3.3 — TECHNIQUE 1: TF-IDF Sentence Scoring\n")
cat("================================================================================\n")
for (i in seq_len(nrow(top_sentences))) {
  cat("\n", i, ". (score:", top_sentences$score[i], ")\n")
  cat("   ", substr(top_sentences$text[i], 1, 150), "...\n")
}


# ---- Technique 2 — Frequency-based keyword extraction ----

words <- unlist(strsplit(clean_text, "\\s+"))
words <- words[nchar(words) > 2]

word_freq <- as.data.frame(table(words), stringsAsFactors = FALSE)
colnames(word_freq) <- c("word", "frequency")
word_freq <- word_freq[order(-word_freq$frequency), ]
top_words <- head(word_freq, 20)
rownames(top_words) <- NULL   # <-- removes the messy index numbers

cat("\n================================================================================\n")
cat("Q3.3 — TECHNIQUE 2: Frequency-Based Keywords\n")
cat("================================================================================\n")
print(top_words)

# visualisations
# ----  Bar chart ----

p1 <- ggplot(top_words, aes(x = reorder(word, frequency), y = frequency)) +
  geom_col(fill = "steelblue") +
  coord_flip() +
  labs(
    title = "Q3.3 Top 20 Keywords in the NLP Wikipedia Article",
    subtitle = "Frequency-based extraction after preprocessing",
    x = "Word", y = "Frequency"
  ) +
  theme_minimal(base_size = 12)

print(p1)
ggsave("C:/ITBDA4-Assignment2/q3_bar.png", p1, width = 10, height = 6, dpi = 150)


# ----  Word cloud ----

png("C:/ITBDA4-Assignment2/q3_wordcloud.png", width = 1200, height = 800)
wordcloud(
  words        = word_freq$word,
  freq         = word_freq$frequency,
  max.words    = 60,
  scale        = c(4, 0.7),
  colors       = brewer.pal(8, "Dark2"),
  random.order = FALSE
)
title("Q3.3 Word Cloud of Top Keywords")
dev.off()


# ---- Sentence importance histogram ----

scores_df <- data.frame(score = sentence_scores)

p3 <- ggplot(scores_df, aes(x = score)) +
  geom_histogram(bins = 25, fill = "coral", alpha = 0.8) +
  labs(
    title = "Q3.3 Distribution of Sentence Importance Scores",
    x = "TF-IDF sentence score", y = "Number of sentences"
  ) +
  theme_minimal(base_size = 12)

print(p3)
ggsave("C:/ITBDA4-Assignment2/q3_sentence_hist.png", p3, width = 10, height = 5, dpi = 150)

cat("\nQ3.3 — All plots saved to C:/ITBDA4-Assignment2/\n")