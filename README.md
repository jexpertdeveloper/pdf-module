Make a gem that takes a PDF file object as a parameter and returns a hash with the following information about the pdf:

- Does the PDF have a title? (return title or nil)
- Does the PDF contain tags (return array of tags or empty array)
- Does the PDF have a language definition? (return language definition or nil)
- Does the PDF contain one or more headings? (return array of headings or empty array)
- Does the PDF contain any bookmarks? (return array of bookmarks or empty array)
- Does the PDF contain untagged content? (return array of page numbers with the issue or empty array)
- Is the first heading in the PDF a Heading 1? (return boolean)
- Does the PDF contain an image without an alternative presentation? (return array of page numbers with the issue or empty array)
- Does the PDF contain tables without table headings? (return array of page numbers with the issue or empty array)

