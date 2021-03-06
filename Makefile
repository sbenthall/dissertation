SHELL=bash
texer=pdflatex

all: clean thesis.pdf

 no-edit.bib: blackbox.etc.bib bibclean.sed
	rm -f no-edit.bib
	touch no-edit.bib
	echo -e "@comment{*********************************************\n THIS FILE IS AUTOGENERATED.  DO NOT EDIT BY HAND.\n*****************************************************\nIf you want to edit the .bib, edit blackbox.etc.bib\n****************************}" > no-edit.bib
	sed -f bibclean.sed < blackbox.etc.bib >> no-edit.bib

%.pdf: %.tex no-edit.bib 
	$(texer) $*
	biber $*
	$(texer) $*
	$(texer) $*

export: main.pdf
	mkdir ./export
	cat main.tex | perl -pe 's/(^|[^\\])%.*/\1%/' > export/main.tex
# cp figs into ./export as well
	zip -r export export

clean:
# rm -f $(AUTOGENERATED_TEX) # this does nothing
	rm -f thesis.aux
	rm -f thesis.bbl
	rm -f thesis.blg
	rm -f thesis.depytx
	rm -f thesis.dvi
	rm -f thesis.log
	rm -f thesis.out
	rm -f thesis.pdf
	rm -f thesis.bcf
	rm -f thesis.run.xml
	rm -f thesis.pytxcode
	rm -f *~
	rm -f *.pyc
	rm -fr export
	rm -f export.zip
	rm -f no-edit.bib
	rm -Rf doc-chapter3.*.pdf

.PHONY: all export clean

######################################
# Piotr's convenience targets
######################################

DOC      := doc-chapter3
MAIN     := chapter3
PDFLATEX := pdflatex

# OPENING PDFS
ifneq ("$(wildcard /Applications/Skim.app)","")
  OPEN := open -a /Applications/Skim.app
else ifneq ("$(wildcard /Applications/Preview.app)","")
  OPEN := open -a /Applications/Preview.app
else
  OPEN := $(shell command -v evince xpdf gv 2> /dev/null)
endif

DEP := *.tex bibs/*.bib figures/*.tex figures/*.pdf
DEP := $(foreach i,$(DEP),$(shell ls $(i) 2> /dev/null))

start:
	make draft

start-%:
	make open-$*
	make watch-$*

draft:
	make start-draft
final:
	make start-final

open-%: $(DOC).%.pdf
ifneq ("$(OPEN)","")
	$(OPEN) $(DOC).$*.pdf ; sleep 1
else
	@echo "Could not find a PDF reader. If you'd like this \
	makefile to open the generated pdfs, add your PDF reader to \
	the opening section of the Makefile."
	@exit 1
endif

$(DOC).%.pdf: $(DEP) no-edit.bib
	perl watch.pl render_latex $(MAIN) "\def\$*{}\input{$(MAIN).tex}"
	@cp $(MAIN).pdf $(DOC).$*.pdf
	@cp $(MAIN).synctex.gz $(DOC).$*.synctex.gz

watch-%:
	perl watch.pl watch $(DOC).$*.pdf $(DEP)

# DEBUGGING UTILS
debug: $(DEP)
	$(PDFLATEX) -interaction nonstopmode "\input{$(MAIN).tex}"
	$(OPEN) $(DOC).pdf

# To debug unicode issues:
# useful emacs command: find-file-literally
show_unicode: $(DEP)
	pcregrep --color='auto' -n "[\x80-\xFF]" *.tex *.bib

# List all references to the thing after find_ in the tex sources.
find_%: *.tex
	grep -I -C 1 -n --color=auto "$*" *.tex; true
