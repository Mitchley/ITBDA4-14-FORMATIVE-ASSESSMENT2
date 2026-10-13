# ============================================================
# Q2 LDA Topic Modelling 
# ITBDA4 Big Data Analytics  Project 2
# ============================================================

library(tm)
library(topicmodels)
library(ggplot2)
library(dplyr)
library(tidyr)
library(wordcloud)

# ============================================================
# Q2.1 — Data frame + denoising 
# ============================================================

# Load all news_*.txt files into a data frame (col_1 = file_name, col_2 = content)
docs_path <- "C:/ITBDA4-Assignment2/q2_data"
doc_files <- list.files(docs_path, pattern = "\\.txt$", full.names = TRUE)

df <- data.frame(
  file_name = basename(doc_files),
  content   = sapply(doc_files, function(f)
    paste(readLines(f, warn = FALSE), collapse = " ")),
  stringsAsFactors = FALSE
)

cat("Q2.1 — Loaded", nrow(df), "documents\n")

df_display <- data.frame(
  file_name = df$file_name,
  content_preview = paste0(substr(df$content, 1, 80), "...")
)
print(df_display)
# Denoising pipeline using tm
corpus <- VCorpus(VectorSource(df$content))
corpus <- tm_map(corpus, content_transformer(tolower))
corpus <- tm_map(corpus, removePunctuation)
corpus <- tm_map(corpus, removeNumbers)
corpus <- tm_map(corpus, removeWords, stopwords("english"))
corpus <- tm_map(corpus, stripWhitespace)
corpus <- tm_map(corpus, stemDocument)

# Build Document-Term Matrix and remove very rare terms
dtm <- DocumentTermMatrix(corpus)
dtm <- removeSparseTerms(dtm, 0.9)
cat("Q2.1 — DTM dimensions (docs x terms):", dim(dtm), "\n\n")

# ============================================================
# Q2.2 LDA: top n topics, top k words per topic
# ============================================================

n_topics <- 3   # n — number of topics to extract
k_words  <- 6   # k — top words to show per topic

lda_model <- LDA(dtm, k = n_topics, control = list(seed = 1234))

# Top k words per topic
top_words <- terms(lda_model, k_words)
cat("Q2.2 — Top", k_words, "words in each of the", n_topics, "topics:\n")
print(top_words)

# Word distribution (probabilities) per topic
beta <- posterior(lda_model)$terms
for (t in 1:n_topics) {
  cat("\n--- Topic", t, "word distribution ---\n")
  dist <- sort(beta[t, ], decreasing = TRUE)[1:k_words]
  print(round(dist, 4))
}

# ============================================================
# Q2.3 At least two visualisations 
# ============================================================

# --- Visualisation 1: Bar chart of top words per topic ---

# Get word probabilities from the LDA model
n_topics <- 3
k_words  <- 6
beta <- posterior(lda_model)$terms

# Build a data frame with the top words and their probabilities
plot_df <- data.frame()
for (t in 1:n_topics) {
  top_idx <- order(beta[t, ], decreasing = TRUE)[1:k_words]
  plot_df <- rbind(plot_df, data.frame(
    word  = colnames(beta)[top_idx],
    topic = paste0("Topic ", t),
    prob  = as.numeric(beta[t, top_idx])
  ))
}

# Draw the bar chart
p1 <- ggplot(plot_df, aes(x = reorder(word, prob), y = prob, fill = topic)) +
  geom_col(show.legend = FALSE) +
  facet_wrap(~topic, scales = "free") +
  coord_flip() +
  labs(title = "Q2.3 Top Words per LDA Topic",
       subtitle = "Bar length = word probability",
       x = "Word", y = "Probability") +
  theme_minimal()

print(p1)
ggsave("C:/ITBDA4-Assignment2/q2_bar.png", p1, width = 10, height = 5)