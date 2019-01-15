curl --form input_files[]=@content/page/cv/resume.pt-br.md --form from=markdown --form to=pdf --form other_files[]=@content/page/cv/css/resume.css http://c.docverter.com/convert > rafael-dutra-cv-full.pdf
curl --form input_files[]=@content/page/cv/simple.pt-br.md --form from=markdown --form to=pdf --form other_files[]=@content/page/cv/css/resume.css http://c.docverter.com/convert > rafael-dutra-cv.pdf

