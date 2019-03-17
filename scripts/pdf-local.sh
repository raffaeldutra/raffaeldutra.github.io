curl --form input_files[]=@content/cv/me.md --form from=markdown --form to=pdf --form other_files[]=@content/cv/css/resume.css http://c.docverter.com/convert > rafael-dutra-cv-full.pdf
curl --form input_files[]=@content/cv/simple.md --form from=markdown --form to=pdf --form other_files[]=@content/cv/css/resume.css http://c.docverter.com/convert > rafael-dutra-cv.pdf

