usage:
	@echo 'Welcome to the build system for discrete-math-for-cs!'
	@echo 'You are seeing this message because you ran plain `make` or `make usage`'
	@echo 'The most common use of this Makefile is `make index; make website`'
	@echo 'This will populate the site, which you can navigate through `generated/website/index.html`'
	@echo 'You can read more about how to edit and build in README.md'

# This is named "index" because it does the aggregation and creation of files
# that don't have a one-to-one corresponding source file. This includes all the
# topic and app files. Since getting `make` to understand intermediate generated
# files adds significant complexity, it's more straightforward to run two make
# commands in a row. The `website` rule relies on files created from *data* in
# the json files that index uses, so it needs to run in a totally separate step.
# The `index` rule sets this up.
index: generated/last-index.txt

# The files that drive website changes are the tex files for lessons.
# To build the website, first create PDFs and static elements in generated directory, then
# translate tex to htmls and then dynamically create additional html pages
# and finally remove auxiliary files from typesetting steps
website: static-pages latex dynamic-pages tex-html clean-tex 

# run compile python scripts to generated compiled .tex files of applications
# and topics. The target is a text file, and the trick of using touch makes the
# file update its modified time when this is run. BUT, if these files haven't
# changed since the last run, they will all be older than last-index.txt
generated/last-index.txt: *.json *.py notes/lessons/*.tex notes/assignments/*.tex notes/activity-snippets/*.tex resources/*.tex
	mkdir -p generated/notes
	mkdir -p generated/notes/app
	mkdir -p generated/notes/topic
	python3 weeklyCompileApp.py
	python3 weeklyCompileTopic.py
	touch generated/last-index.txt


# Iterate over all changed .tex files in notes and run target for them in new folder, then generate flat versions if needed
latex: lessonsLatex appLatex topicLatex assignmentsLatex app-latexpand topic-latexpand lessons-latexpand assignments-latexpand
lessonsLatex: $(patsubst notes/lessons/%.tex,generated/output/lessons/%.pdf,$(wildcard notes/lessons/*.tex))
appLatex: $(patsubst generated/notes/app/%.tex,generated/output/app/%.pdf,$(wildcard generated/notes/app/*.tex))
topicLatex: $(patsubst generated/notes/topic/%.tex,generated/output/topic/%.pdf,$(wildcard generated/notes/topic/*.tex))
assignmentsLatex: $(patsubst notes/assignments/%.tex,generated/output/assignments/%.pdf,$(wildcard notes/assignments/*.tex))
topic-latexpand: $(patsubst generated/notes/topic/%.tex,generated/notes/topic-flat/%.tex,$(wildcard generated/notes/topic/*.tex))
app-latexpand: $(patsubst generated/notes/app/%.tex,generated/notes/app-flat/%.tex,$(wildcard generated/notes/app/*.tex))
lessons-latexpand: $(patsubst generated/notes/lessons/%.tex,generated/notes/lessons-flat/%.tex,$(wildcard generated/notes/lessons/*.tex))
assignments-latexpand: $(patsubst notes/assignments/%.tex,generated/notes/assignments-flat/%.tex,$(wildcard notes/assignments/*.tex))

# Typesetting all .tex files in notes/lessons directory MIA:added dependency on activity-snippets
generated/output/lessons/%.pdf: notes/lessons/%.tex notes/activity-snippets/*.tex resources/lesson-head.tex resources/discrete-math-packages.tex
	mkdir -p generated/output/lessons; cd notes/lessons; pdflatex -output-directory ../../generated/output/lessons $(<F) 

#since all of the app and topic files are generated through a python script, they are in the generated directory 
# Typesetting all .tex files in generated/notes/app directory
generated/output/app/%.pdf: generated/notes/app/%.tex resources/lesson-head.tex resources/discrete-math-packages.tex
	mkdir -p generated/output/app; cd generated/notes/app; pdflatex -output-directory ../../output/app $(<F) 

# Typesetting all .tex files in generated/notes/app directory
generated/output/topic/%.pdf: generated/notes/topic/%.tex resources/lesson-head.tex resources/discrete-math-packages.tex
	mkdir -p generated/output/topic; cd generated/notes/topic; pdflatex -output-directory ../../output/topic $(<F) 

# Typesetting all .tex files in notes/assignments directory
generated/output/assignments/%.pdf: notes/assignments/%.tex resources/assignment-head.tex resources/discrete-math-packages.tex
	mkdir -p generated/output/assignments; cd notes/assignments; pdflatex -output-directory ../../generated/output/assignments $(<F) 

# generate expanded/flat version of assignments compiled tex files
generated/notes/assignments-flat/%.tex: notes/assignments/%.tex resources/assignment-head.tex resources/discrete-math-packages.tex
	mkdir -p generated/notes/assignments-flat; cd notes/assignments; latexpand $(<F) > ../../generated/notes/assignments-flat/$(<F)

# generate expanded/flat version of topic compiled tex files
generated/notes/topic-flat/%.tex: generated/notes/topic/%.tex resources/lesson-head.tex resources/discrete-math-packages.tex
	mkdir -p generated/notes/topic-flat; cd generated/notes/topic; latexpand $(<F) > ../topic-flat/$(<F)

# generate expanded/flat version of app compiled tex files
generated/notes/app-flat/%.tex: generated/notes/app/%.tex resources/lesson-head.tex resources/discrete-math-packages.tex
	mkdir -p generated/notes/app-flat; cd generated/notes/app; latexpand $(<F) > ../app-flat/$(<F)

# generate expanded/flat version of lessons compiled tex files
generated/notes/lessons-flat/%.tex: generated/notes/lessons/%.tex resources/lesson-head.tex resources/discrete-math-packages.tex
	mkdir -p generated/notes/lessons-flat; cd generated/notes/lessons; latexpand $(<F) > ../lessons-flat/$(<F)

# Build website by copying over files, notes, resources, html, and style files to generated directory
static-pages: generated-files generated-resources generated-notes  generated-notes-activity-snippets generated-website generated-website-css

# Directory files has instructor-added content, e.g. annotated pdfs and slides
generated-files: $(patsubst files/%,generated/files/%,$(wildcard files/*))

generated/files/%: files/%
	mkdir -p generated/files
	cp $< $@

# Directory resources has images and tex files used to create lessons
generated-resources: $(patsubst resources/%,generated/resources/%,$(wildcard resources/*))

generated/resources/%: resources/%
	mkdir -p generated/resources
	cp -R $< $@

# Directory notes contains tex files for outcomes and topics 
generated-notes: $(patsubst notes/%,generated/notes/%,$(wildcard notes/*))

generated/notes/%: notes/%
	mkdir -p generated/notes
	cp -R $< $@

# Directory notes/activity-snippets contains tex files for outcomes and topics 
generated-notes-activity-snippets: $(patsubst notes/activity-snippets/%,generated/notes/activity-snippets/%,$(wildcard notes/activity-snippets/*))

generated/notes/activity-snippets/%: notes/activity-snippets/%
	mkdir -p generated/notes/activity-snippets
	cp $< $@

# Directory website and website-manual-to-automate contain all static components of site
generated-website: $(patsubst website/%,generated/website/%,$(wildcard website/*))

generated/website/%: website/%
	mkdir -p generated/website
	cp -R $< $@

# Directory website/css contains styling information that may change when pages are updated, 
# for example, the contents of the sidebar depend on the number of lessons, outcomes, and applications
generated-website-css:  $(patsubst website/css/%,generated/website/css/%,$(wildcard website/css/*))

generated/website/css/%: website/css/%
	mkdir -p generated/website/css
	cp $< $@

# Building dynamic html pages based on unit template, topic (TODO: rename as outcome) template
# application template, and overview pages. These dynamic html pages are created
# directly in the generated directory
dynamic-pages: 
	python3 template.py
	python3 unitTemplate.py
	python3 topicTemplate.py
	python3 appTemplate.py

#Building html versions of all .tex files in notes/lessons directory 
tex-html : lessons-tex-html app-tex-html topic-tex-html assignments-tex-html
lessons-tex-html : $(patsubst notes/lessons/%.tex,generated/output/lessons/%.html,$(wildcard notes/lessons/*.tex))
app-tex-html : $(patsubst generated/notes/app/%.tex,generated/output/app/%.html,$(wildcard generated/notes/app/*.tex))
topic-tex-html : $(patsubst generated/notes/topic/%.tex,generated/output/topic/%.html,$(wildcard generated/notes/topic/*.tex))
assignments-tex-html : $(patsubst notes/assignments/%.tex,generated/output/assignments/%.html,$(wildcard notes/assignments/*.tex))

generated/output/lessons/%.html: notes/lessons/%.tex resources/lesson-head.tex resources/discrete-math-packages.tex
	cd notes/lessons; pandoc --standalone --mathjax -f latex -t html $(<F) -o ../../generated/output/lessons/$(@F)

generated/output/app/%.html: generated/notes/app/%.tex resources/lesson-head.tex resources/discrete-math-packages.tex
	cd generated/notes/app; pandoc --standalone --mathjax -f latex -t html $(<F) -o ../../output/app/$(@F)

generated/output/topic/%.html: generated/notes/topic/%.tex resources/lesson-head.tex resources/discrete-math-packages.tex
	cd generated/notes/topic; pandoc --standalone --mathjax -f latex -t html $(<F) -o ../../output/topic/$(@F)

generated/output/assignments/%.html: notes/assignments/%.tex resources/lesson-head.tex resources/discrete-math-packages.tex
	cd notes/assignments; pandoc --standalone --mathjax -f latex -t html $(<F) -o ../../generated/output/assignments/$(@F)

# Removing all auxiliary typesetting files from output directory and its subdirectories
clean-tex: 
	cd generated/output; rm -f *.out *.log *.aux
	cd generated/output/lessons; rm -f *.out *.log *.aux
	cd generated/output/app; rm -f *.out *.log *.aux
	cd generated/output/topic; rm -f *.out *.log *.aux
	cd generated/output/assignments; rm -f *.out *.log *.aux
