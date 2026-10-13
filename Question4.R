# ====================================================================================================
# Q4 — ETL with R & PostgreSQL
# Use case: Books catalogue (books.toscrape.com)
# ====================================================================================================

library(rvest)
library(stringr)
library(dplyr)
library(RPostgres)
library(DBI)


# ====================================================================================================
# Q4.1 — Scrape 100 books (5 pages x 20 books)
# ====================================================================================================

base_url <- "https://books.toscrape.com/catalogue/page-%d.html"

scrape_page <- function(p) {
  page  <- read_html(sprintf(base_url, p))
  cards <- page %>% html_elements("article.product_pod")
  
  data.frame(
    title      = cards %>% html_elements("h3 a") %>% html_attr("title"),
    price_text = cards %>% html_elements(".price_color") %>% html_text(trim = TRUE),
    rating     = cards %>% html_elements("p.star-rating") %>% html_attr("class") %>%
      str_remove("star-rating "),
    stock      = cards %>% html_elements(".instock.availability") %>%
      html_text(trim = TRUE) %>% str_squish(),
    stringsAsFactors = FALSE
  )
}

raw_df <- bind_rows(lapply(1:5, scrape_page))

# Inject messy data
raw_df$title[c(3, 12, 45)]      <- NA
raw_df$price_text[c(7, 15, 62)] <- ""
raw_df$rating[c(5, 18, 88)]     <- "Nine"
raw_df$price_text[10]           <- "£9999.99"

# ---- Clean display of raw (messy) data ----------------------------------------raw_display <- data.frame(
raw_display <- data.frame(
  title      = substr(raw_df$title, 1, 40),
  price_text = raw_df$price_text,
  rating     = raw_df$rating
)

cat("\n================================================================================\n")
cat("Q4.1 — SCRAPED DATA (with messy values)\n")
cat("================================================================================\n")
cat("Total records scraped:", nrow(raw_df), "\n\n")
print(head(raw_display, 20))
cat("\n...\n\n")


# ====================================================================================================
# Q4.2 — Clean, impute, and export to CSV
# ====================================================================================================

clean_df <- raw_df

clean_df$price <- as.numeric(str_remove(clean_df$price_text, "£"))

rating_map <- c("One"=1, "Two"=2, "Three"=3, "Four"=4, "Five"=5)
clean_df$rating_num <- as.numeric(rating_map[clean_df$rating])

clean_df <- clean_df[!is.na(clean_df$title), ]
clean_df <- clean_df[!is.na(clean_df$price), ]
clean_df <- clean_df[!is.na(clean_df$rating_num), ]
clean_df <- clean_df[clean_df$price < 1000, ]

clean_df$stock[is.na(clean_df$stock) | clean_df$stock == ""] <- "In stock"
clean_df <- clean_df[!duplicated(clean_df$title), ]

final_df <- clean_df[, c("title", "price", "rating_num", "stock")]
colnames(final_df) <- c("title", "price", "rating", "stock")

write.csv(final_df,
          "C:/ITBDA4-Assignment2/books_cleaned.csv",
          row.names = FALSE)

# ---- Clean display of cleaned data -------------------------------------------
final_display <- data.frame(
  title  = substr(final_df$title, 1, 40),
  price  = final_df$price,
  rating = final_df$rating,
  stock  = final_df$stock
)

cat("\n================================================================================\n")
cat("Q4.2 — CLEANED DATA\n")
cat("================================================================================\n")
cat("Original records :", nrow(raw_df), "\n")
cat("Cleaned records  :", nrow(final_df), "\n")
cat("Records removed  :", nrow(raw_df) - nrow(final_df), "\n\n")
print(head(final_display, 20))
cat("\n...\n")
cat("\nQ4.2 — Exported to books_cleaned.csv\n")


# ====================================================================================================
# Q4.3 — Load into PostgreSQL and run two SQL queries
# ====================================================================================================

con <- dbConnect(RPostgres::Postgres(),
                 host = "localhost",
                 port = 5432,
                 dbname = "books_etl_db",
                 user = "postgres",
                 password = "student123")

dbExecute(con, "DROP TABLE IF EXISTS books;")
dbWriteTable(con, "books", final_df, row.names = FALSE)

cat("\n================================================================================\n")
cat("Q4.3 — POSTGRESQL LOADED\n")
cat("================================================================================\n")
cat("Loaded", nrow(final_df), "rows into table 'books'\n\n")

# ---- Query 1 -----------------------------------------------------------------
cat("--- Query 1: Average price per rating level ---\n")
q1 <- dbGetQuery(con, "
  SELECT rating,
         COUNT(*) AS book_count,
         ROUND(AVG(price)::numeric, 2) AS avg_price
  FROM books
  GROUP BY rating
  ORDER BY rating;
")
print(q1)

# ---- Query 2 ----------------------------------------------------------------
cat("\n--- Query 2: Top 5 most expensive books ---\n")
q2 <- dbGetQuery(con, "
  SELECT title, price, rating
  FROM books
  ORDER BY price DESC
  LIMIT 5;
")
q2$title <- substr(q2$title, 1, 50)   # truncate long titles for display
print(q2)

dbDisconnect(con)
cat("\nQ4.3 Connection closed\n")