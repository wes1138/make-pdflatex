TARGETS := main.pdf

LATEX = pdflatex -halt-on-error -recorder
BIBTEX = bibtex

DEPDIR := .d
$(shell mkdir -p $(DEPDIR) &> /dev/null)

# reruns latex if needed.
RERUN = grep -Eq '(^LaTeX Warning:|\(natbib\)).* Rerun' $*.log
UNDEFINED = grep -Eq '^(LaTeX|Package natbib) Warning:.* undefined' $*.log
BACKREF = grep -Eq 'Package backref .* backref set up' $*.log
POSTBUILD = echo -n '$@: ' > $(DEPDIR)/$*.mk && \
	grep '.*.tex$$' $*.fls | \
	awk '!x[$$2]++ {print $$2}' ORS=' ' >> $(DEPDIR)/$*.mk && \
	touch -f $@ $(DEPDIR)/$*.mk

# NOTE: since we are building dependencies as we compile, we must ensure
# that the .mk file is not newer than the target, else you will always
# rebuild the target, which lists the .mk as a prereq (this is done for
# a subtle reason; it takes care of a corner case in which the dependency
# files are deleted).  Hence the touch -f command.

all : $(TARGETS)
.PHONY : all

$(TARGETS) : %.pdf : $(DEPDIR)/%.mk
	[[ ! -s $*.aux ]] || $(BIBTEX) $* || rm -f $*.aux $*.bbl
	$(LATEX) $*.tex || ! rm -f $@
	if [[ ! -f $*.bbl ]] || $(UNDEFINED) $*.log; then \
	    ($(BIBTEX) $* && $(LATEX) $*.tex) || rm -f $*.bbl; \
	fi
	! $(RERUN) || ($(LATEX) $*.tex && \
			  (! $(BACKREF) || $(LATEX) $*.tex)) || ! rm -f $@
	$(POSTBUILD)

$(DEPDIR)/%.mk: ;
.PRECIOUS: $(DEPDIR)/%.mk

-include $(patsubst %.pdf,$(DEPDIR)/%.mk,$(TARGETS))


.PHONY : clean
clean :
	rm -f *.aux *.dvi *.log *.blg *.bbl *.bak *.lof *.lot \
		*.toc *.brf *.out *.snm *.nav *.vrb *.fls

.PHONY : superclean
superclean : clean
	rm -rf *.pdf $(DEPDIR)
