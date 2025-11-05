# -------------------------------------------------------------------------
# -- Matthew C. Vanderbilt, MSBA                                         --
# -- SOME CODE MAY BE ADAPTED FROM MICROSOFT COPILOT PROMTS              --
# -------------------------------------------------------------------------

# INSTALL & LOAD NECESSARY PACKAGES ---------------------------------------

libraries <- c(                  # -- CREATE A VECTOR OF DESIRED LIBRARIES
  "rvest",                       # -- WEB SCRAPING: reads and parses HTML
  "httr",                        # -- HTTP REQUESTS: downloads files from URLs
  "stringr"                      # -- STRING MANIPULATION: filters and formats URLs
)



for (
  package in libraries
) {
  if (
    !require(                    # checks if library is already installed
      package,
      character.only = TRUE,     # has R treat the vector as text not an object
      quietly = TRUE             # suppresses installation messages
    )
  ) {
    suppressMessages(
      install.packages(
        package
      )
    )
    supressMessages(
      library(                  # loads each library
        package,
        character.only = TRUE
      )
    )
  }
}

rm(                            # Clean up environment
  libraries,
  package
)

gc()                           # Frees up memory that is no longer needed





library(rvest)
library(httr)
library(stringr)

# Target URL
base_url <- "https://policy.ucop.edu/advanced-search.php?action=welcome&op=browse&subject=2&all=1"

# Destination folder: Downloads/UCSD Policies
downloads_dir <- file.path(Sys.getenv("USERPROFILE"), "Downloads", "tmpPolicies")
dir.create(downloads_dir, showWarnings = FALSE)

# Scrape the page
page <- read_html(base_url)

# Extract relative PDF links
pdf_links <- page %>%
  html_nodes("a") %>%
  html_attr("href") %>%
  na.omit() %>%
  str_subset("\\.pdf$") %>%
  str_subset("^/") %>%
  paste0("https://policy.ucop.edu", .)

# Download each PDF
for (link in pdf_links) {
  file_name <- basename(link)
  dest_path <- file.path(downloads_dir, file_name)
  tryCatch({
    GET(link, write_disk(dest_path, overwrite = TRUE))
    cat("✅ Downloaded:", file_name, "\n")
  }, error = function(e) {
    cat("❌ Failed to download:", link, "\n")
  })
}